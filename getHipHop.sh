#!/bin/bash

echo "Welcome to the Hip Hop Show... show... show... show... show... show... show"

# Associative array declaration
declare -A ShowName Type ShowDate DownloadFileName FullUrl UrlStart UrlEnd FinishError OutputFileName

function setDateByDay {
  YYYY=$(date +"%Y" -d "last $1")
  MM=$(date +"%m" -d "last $1")
  DD=$(date +"%d" -d "last $1")
  echo "$YYYY"'-'"$MM"'-'"$DD"
}

function getDateFromParam {
# Scrape first parameter for date
  if [ "$1" != "" ]
    then
      dateRegex="([0-9]{4})-([0-9]{2})-([0-9]{2})"
      [[ $1 =~ $dateRegex ]]
      YYYY="${BASH_REMATCH[1]}"
      MM="${BASH_REMATCH[2]}"
      DD="${BASH_REMATCH[3]}"
      echo "$YYYY"'-'"$MM"'-'"$DD"
  fi
}

function downloadIfDirect {
  local show=$1
  # Simple download for direct files
  if [ ${Type[$show]} == 'direct' ]; then
    echo 'Downloading '"${OutputFileName[$show]}"
    # TODO test if right day for show.
    wget ${FullUrl[$show]} && mv ${DownloadFileName[$show]} ${OutputFileName[$show]} || echo "Download failed. Please try again later."
  fi
}

function setSegmentFileName {
  # Output filename for segment
  local segmentNum=$1
  local segmentDisplayNum=$(printf '%05i\n' $segmentNum)
  local segmentFileName="${ShowDate[$show]}"'_Hip-Hop-Show_segment-'"$segmentDisplayNum"'.ts'
  echo "$segmentFileName"
}

function fetchSegment {
  local segmentNum=$1
  local segmentFileName=$2
  curl -o $segmentFileName ${UrlStart[$show]}$segmentNum${UrlEnd[$show]}
  echo "$?"
}

function testSegmentForEndFile {
  # Check for HTML file returned indicating no more segments
  # Returns finished status
  local segmentFileName=$1
  local segmentNum=$2
  local isFinished=0
  read -r firstLine<$segmentFileName
  if [ $firstLine == "<HTML><HEAD><TITLE>Error</TITLE></HEAD><BODY>" ]
    then
      if [ $segmentNum == 2 ]
        then
          isFinished=2
        else
          isFinished=1
      fi
    else isFinished=0
  fi
  echo "$isFinished"
}

function finishedCode {
  case "$1" in
    1) echo 'All segments received, stitching together episode.'
       rm $segmentFileName
       ;;
    2) echo 'ERROR: Incorrect date or missing file. Skipping download.'
       ;;
  esac
}

function concatenateFiles {
  local show=$1
  # Concatenate all .ts files and convert to .m4a
  ffmpeg -f concat -safe 0 -i <(for f in ./*.ts; do echo "file '$PWD/$f'"; done) -c copy output.ts && ffmpeg -i output.ts -c:a aac -q:a 330 -cutoff 15000 output.m4a

  mv output.m4a ../${OutputFileName[$show]}
  rm output.ts
}

function promptForDeletion {
  local show=$1
  delyn="n"
  read -p "Would you like to delete all temporary files created [y/n]? " delyn
  if [ $delyn == "y" ]; then
    rm *.ts
    cd ..
    rmdir ${ShowDate[$show]}
  fi
}

if [ -e getHipHop.config ]
  then
    . getHipHop.config
    # Override shows if 2nd parameter present
    [[ $1 ]] && unset ShowsToDownload && ShowsToDownload=($1)
  else
    echo "ERROR: No configuration file found, exiting now."
    exit
fi

[ -d $downloadDir ] && cd $downloadDir

for show in "${ShowsToDownload[@]}"
do
# Test for existing file
  contyn="y"
  [ -e ${OutputFileName[$show]} ] && read -p "${OutputFileName[$show]}"' already exists - do you want to continue [y/n]? ' contyn
  if [ $contyn == "n" ]
    then
      echo 'Skipping download'
    else
# Simple download for direct files
      downloadIfDirect $show
# Looped download for Triple J and other troublesome types
      if [ ${Type[$show]} == 'stitch' ]; then
        [ -d ${ShowDate[$show]} ] && read -p "Directory already exists - do you want to continue [y/n]? " contyn || mkdir ${ShowDate[$show]}
        if [ $contyn == "n" ]
          then
            echo 'Skipping download'
          else
            cd ${ShowDate[$show]}
            echo 'Downloading '"${OutputFileName[$show]}"
            segmentNum=1
            isFinished=0

            while [ $isFinished == 0 ]
            do
              echo " "
              segmentFileName=$(setSegmentFileName $segmentNum)
              fetchResult=$(fetchSegment $segmentNum $segmentFileName)
              if [ $fetchResult == 0 ]
                then
                  ((segmentNum++))
                else
                  echo "CURL ERROR $fetchResult, trying again"
              fi
              isFinished=$(testSegmentForEndFile $segmentFileName $segmentNum)
              finishedCode $isFinished
              echo " "
            done

            if [ $isFinished == 1 ]
              then
                concatenateFiles $show
                echo 'Download complete: '"${OutputFileName[$show]}"
                promptForDeletion $show
            fi
        fi
      fi
  fi
done
