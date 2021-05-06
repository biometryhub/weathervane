#!/bin/bash

# Downloads all of the SILO weather data for each of the sites listed
# in NVT_SA_data.csv.
# Code author: Russell A. Edson
# Date last modified: 06/05/2021

input="./NVT_SA_data.csv"

# Ignore header row
sed 1d "$input" | while IFS= read -r line
do
  i=1
  sed 's/,/\n/g' <<<$line | ( while read value
  do 
    # Extract Site, Year, Trial and Latitude/Longitude info
    case $i in
      2)
        year=$value
        ;;
      3)
        trialcode=$(echo "$value" | sed 's/ //g')
        ;;
      5)
        site=$(echo "$value" | sed 's/ //g')
        ;;
      7)
        latitude=$(echo "$value" | cut -c1-8)
        ;;
      8)
        longitude=$(echo "$value" | cut -c1-8)
        ;;
    esac
    i=$((i+1))
  done
  rubycommand="./wvane.rb --lat $latitude --lng $longitude"
  rubycommand+=" --start $year-01-01 --finish $year-12-31"
  rubycommand+=" --out ${year}_${site}_${trialcode}.csv"
  #rubycommand+=" > /dev/null 2>&1"
  $rubycommand )
done
