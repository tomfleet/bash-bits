#!/bin/bash

#check if demo dir exists and if so rm it
if [ -d "demo" ]; then
    rm -rfd demo
fi

#make a new demo dir and cd into it
mkdir -p demo && cd demo

#check if the user has provided a URL
if [ -z "$1" ]; then
    echo "No URL provided"
    exit 1
fi

url=$1

echo "Captured URL: $url"

#sudo dos2unix ../aaart/aaart.sh 

# Call the script and print the output

pwd=$(pwd)
echo "Current directory for art: $pwd"

call_aaart() {
    ../../aaart/aaart.sh "$1"
    if [ $? -ne 0 ]; then
        echo "yt-dlp [tracklist] failed"
        exit 1
    fi
}

call_aaart "$url"

if [ $? -ne 0 ]; then
    echo "yt-dlp [tracklist] failed"
    exit 1
fi




pwd=$(pwd)
echo "Current directory after art: $pwd"


call_aainfo() {
    ../../aainfo/aainfo.sh "$1"
    if [ $? -ne 0 ]; then
        echo "aainfo.sh failed"
        exit 1
    fi
}

call_aainfo "$url"
if [ $? -ne 0 ]; then
    echo "aainfo.sh failed"
    exit 1
fi


pwd=$(pwd)
echo "Current directory after info: $pwd"
dir=$pwd
#look inside the most recently modified directory for a json file
json_file=$(find "$dir" -name "*.json" | head -n 1)

#echo the conteents of json file
cat "$json_file"



