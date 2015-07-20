#! /bin/bash

# gets the weather and speaks it to you.
# all the REGEX crap is to make it sound better when read
# by the robot voice.

# overwrite header text to file
echo "Here is the current weather outlook as of"> weather.txt

# append date to file
date +"%R %A %B %d %Y" >> weather.txt

# get weather and append to file
# ***CHANGE 'avl' TO YOUR LOCALE***
weather -q --imperial avl >> weather.txt

# clean up text to human readable and tts friendly
sed -i 's/\sN\s/ North/g' weather.txt
sed -i 's/\sS\s/ South/g' weather.txt
sed -i 's/\sE/ East/g' weather.txt
sed -i 's/\sW/ West/g' weather.txt
sed -i 's/\sNE\s/ North East/g' weather.txt
sed -i 's/\sSE\s/ South East/g' weather.txt
sed -i 's/\sNW/ North West/g' weather.txt
sed -i 's/\sSW/ South West/g' weather.txt
sed -i 's/\sNNE\s/ North North East/g' weather.txt
sed -i 's/\sENE\s/ East North East/g' weather.txt
sed -i 's/\sESE\s/ East South East/g' weather.txt
sed -i 's/\sSSE\s/ South South East/g' weather.txt
sed -i 's/\sSSW\s/ South South West/g' weather.txt
sed -i 's/\sWSW\s/ West South West/g' weather.txt
sed -i 's/\sWNW\s/ West North West/g' weather.txt
sed -i 's/\sNNW\s/ North North West/g' weather.txt
sed -i 's/-/ negative/g' weather.txt
sed -i 's/F/degrees/g' weather.txt
sed -i 's/MPH/miles per hour/g' weather.txt
#sed -i 's/://g' weather.txt #screws up the time output :(
sed -i 's/$/:/g' weather.txt
sed -i 's/([^)]*)//g' weather.txt

# add callsign for radio TX ID
echo "call sign goes here" >> weather.txt

# print on screen for verbosity
cat weather.txt

# make it talk (good luck getting festival set up with a decent voice)
festival --tts weather.txt

# NOTES: As far is festival voices are concerned, I have found that 'us_slt_arctic' is a very fluid and
# understandable female voice and prefer it over the others I have used. Good luck getting thru the 
# documentation and setup required to install and configure it!!
