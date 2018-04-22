# getHipHop.sh
A shell script for lovers of Unix and Hip Hop.  

Requires ffmpeg for conversion of file streams.

`sudo apt install ffmpeg`

## Basic usage
`./getHipHop.sh`

By default it fetches the most recent Hip Sista Hop from 3CR, and Triple J's Hip Hop Show.

To fetch a specific show provide a date and show name in format:

`./getHipHop.sh HipHopShow 2018-04-12`

Note: ShowName must match an existing show in `getHipHop.config`

## Config options
`getHipHop.config` allows you to:
- Change download directory
- Change output file naming
- Add new shows

## Song Requests
Additional shows (even non-hip-hop...) can be added to `getHipHop.config`. If there's a great show I should add to this repo please open a pull request.
