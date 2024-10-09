#!/bin/bash

DEBUG=0

# Parse command-line arguments
while getopts "d" opt; do
  case $opt in
    d)
      DEBUG=1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

# Function to print debug messages
debug_echo() {
  if [ $DEBUG -eq 1 ]; then
    echo "$1"
  fi
}

debug_echo "Retrieving album information..."

mkdir jsonData && cd jsonData

#--print playlist_index \
#--print artist \
#--print track \
#--print duration_string \
#--print-to-file "%(playlist_index)s - %(title)s - %(duration_string)s" "%(artist)s/%(album)s.json" \

# Downloading the json data of the first track only
yt-dlp \
    --print-to-file "%(.{playlist_index,title,duration_string})j" "%(artist)s/%(album)s.json" \
    -q \
    --no-warnings \
    --skip-download \
    --no-write-playlist-metafiles \
    --clean-info-json \
    "$1"

if [ $? -ne 0 ]; then
    echo "yt-dlp command failed"
    exit 1
fi

timestamp=$(date +"%Y%m%d%H%M%S")
json_file="album_info_$timestamp.json"

exit


# Assuming yt-dlp writes the JSON file to the current directory
mv *.info.json "$json_file"



exit 0

title=$(jq -r '.title' "$json_file")
debug_echo "Album title: $title"
debug_echo "Finding images with equal height and width..."
images=$(jq -r '.thumbnails[] | select(.height != null and .width != null and .height == .width) | "\(.url) \(.height)x\(.width)"' "$json_file")
if [ -z "$images" ]; then
    debug_echo "No images found with equal height and width."
else
    debug_echo "Images with equal height and width:"
    debug_echo "$images"
    largest_image=$(echo "$images" | grep -E "maxresdefault|1200x1200|640x640|544x544" | head -n 1 | awk '{print $1}')
    if [ -n "$largest_image" ]; then 
        debug_echo "Downloading the largest image: $largest_image"
        curl "$largest_image" -s --output "albumart.file"
        if [ $? -ne 0 ]; then
            echo "curl command failed"
            exit 1
        fi
        convert albumart.file albumart.jpg  #convert to jpg, we should be *some* valid image file if here

        if [ $? -ne 0 ]; then
            echo "convert command failed" 
            exit 1
        fi
        rm albumart.file #tidying up
    else
        debug_echo "No suitable image found."
    fi
fi

#jesus that was an ordeal.

jp2a --colors --width=80  albumart.jpg > asciiart.txt
if [ $? -ne 0 ]; then
    echo "jp2a command failed"
    exit 1
fi

debug_echo "Album art converted to ASCII art and saved as asciiart.txt"
printf "\n"
cat asciiart.txt


