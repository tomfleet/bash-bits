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

# Remove all files and directories in the current directory
debug_echo "Removing all files and directories in the current directory..."
rm -rfd ./*
if [ $? -ne 0 ]; then
    echo "Failed to remove files and directories"
    exit 1
fi


# the joys of scope? I dunno - flat-playlist doesn't get the scope of artist or album?
# so we call the first track alone of the album / playlist, to get "album" artist, and album name

# Downloading the json data of the first track only - to get the album title etc
yt-dlp \
    --print-to-file "%(.{artist,album})j" "%(artist)s - %(album)s.json" \
    -q \
    --no-warnings \
    --playlist-start 1 \
    --playlist-end 1 \
    --skip-download \
    --no-write-playlist-metafiles \
    --clean-info-json \
    "$1"

if [ $? -ne 0 ]; then
    echo "yt-dlp [album info] failed"
    exit 1
fi

# then we pull these *back out of* the json file...
json_file=$(find . -name "*.json" | head -n 1)
artist=$(jq -r '.artist' "$json_file")
album=$(jq -r '.album' "$json_file")

debug_echo "Artist: $artist"
debug_echo "Album: $album"

echo "{\n"artist": " | cat - "$json_file" > temp && mv temp "$json_file"}
echo "File: $json_file"

# to use them in the output template for the-"fkat-playlist" call to yt-dlp

# *fast* (flat_playlist) to get the tracklisting.
yt-dlp \
    --print-to-file "%(.{playlist_index,title,duration_string})j," "${artist} - ${album}.json" \
    -q \
    --no-warnings \
    --skip-download \
    --no-write-playlist-metafiles \
    --clean-info-json \
    --flat-playlist \
    "$1"

if [ $? -ne 0 ]; then
    echo "yt-dlp [tracklist] failed"
    exit 1
fi

echo "}}" >> "$file"

timestamp=$(date +"%Y%m%d%H%M%S")
json_file="album_info_$timestamp.json"

exit
#we are so done here
