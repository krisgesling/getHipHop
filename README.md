# getHipHop.sh
A shell script for lovers of Unix and Hip Hop.  

Requires ffmpeg for conversion of file streams.

`sudo apt install ffmpeg`

## Basic usage
`./getHipHop.sh`

By default it fetches the most recent Hip Sista Hop from 3CR, and Triple J's Hip Hop Show.

To fetch an older show provide a date as the first paramater in format YYYY-MM-DD:

`./getHipHop.sh 2018-04-12`

## Config options
`getHipHop.config` allows you to:
- Change download directory
- Change output file naming
- Add new shows

## Song Requests
Additional shows (even non-hip-hop...) can be added to `getHipHop.config`. If there's a great show I should add to this repo please open a pull request.
