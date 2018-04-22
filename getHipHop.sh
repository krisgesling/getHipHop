#!/bin/bash

echo "Welcome to the Hip Hop Show... show... show... show... show... show... show"

function setDateByDay {
  YYYY=$(date +"%Y" -d "last $1")
  MM=$(date +"%m" -d "last $1")
  DD=$(date +"%d" -d "last $1")
  echo "$YYYY"'-'"$MM"'-'"$DD"
}

# TODO add second parameter to set specific show.
# Scrape first parameter for date
if [ "$1" != "" ]
  then
    dateRegex="([0-9]{4})-([0-9]{2})-([0-9]{2})"
    [[ $1 =~ $dateRegex ]]
    YYYY="${BASH_REMATCH[1]}"
    MM="${BASH_REMATCH[2]}"
    DD="${BASH_REMATCH[3]}"
    episodeDate="$YYYY"'-'"$MM"'-'"$DD"
fi

if [ -e getHipHop.config ]
  then
    . getHipHop.config
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
      if [ ${Type[$show]} == 'direct' ]; then
        echo 'Downloading '"${OutputFileName[$show]}"
        # TODO test if right day for show.
        wget ${FullUrl[$show]} && mv ${DownloadFileName[$show]} ${OutputFileName[$show]} || echo "Download failed. Please try again later."
      fi
# Looped download for Triple J and other troublesome types
      if [ ${Type[$show]} == 'stitch' ]; then
        [ -d ${ShowDate[$show]} ] && read -p "Directory already exists - do you want to continue [y/n]? " contyn || mkdir ${ShowDate[$show]}
        if [ $contyn == "n" ]
          then
            echo 'Skipping download'
          else
            cd ${ShowDate[$show]}

            echo 'Downloading '"${OutputFileName[$show]}"
            finished=0
            segment=1

            while [ $finished == 0 ]
            do
              # Output filename for segment
              segmentDisplayNum=$(printf '%05i\n' $segment)
              segmentFile="${ShowDate[$show]}"'_Hip-Hop-Show_segment-'"$segmentDisplayNum"'.ts'

              echo 'Fetching segment '"$segment"
              curl -o $segmentFile ${UrlStart[$show]}$segment${UrlEnd[$show]}
              curlResult=$?
              # TODO why is this not !=0?
              if [ $curlResult != 0 ]
              # if [ $curlResult == "6" ] || [ $curlResult == "7" ]
              # 6 = Couldn't resolve host
              # 7 = Failed to connect to host
                then
                  echo "Error $curlResult received, trying again"
                else
                  ((segment++))
              fi
              # Check for HTML file returned indicating no more segments
              read -r firstLine<$segmentFile
              if [ $firstLine == "<HTML><HEAD><TITLE>Error</TITLE></HEAD><BODY>" ]
                then
                  if [ $segment == 2 ]
                    then
                      echo 'ERROR: Incorrect date or missing file. Skipping download.'
                      finished=2
                    else
                      echo 'All segments received, stitching together episode.'
                      rm $segmentFile
                      finished=1
                  fi
              fi
              echo " "
              echo " "
            done

            if [ $finished == 1 ]
              then
                # Concatenate all .ts files and convert to .m4a
                ffmpeg -f concat -safe 0 -i <(for f in ./*.ts; do echo "file '$PWD/$f'"; done) -c copy output.ts && ffmpeg -i output.ts -c:a aac -q:a 330 -cutoff 15000 output.m4a

                mv output.m4a ../${OutputFileName[$show]}
                rm output.ts

                echo 'Download complete: '"${OutputFileName[$show]}"
                delyn="n"
                read -p "Would you like to delete all temporary files created [y/n]? " delyn
                if [ $delyn == "y" ]; then
                  rm *.ts
                  cd ..
                  rmdir ${ShowDate[$show]}
                fi
            fi
        fi
      fi
  fi
done
