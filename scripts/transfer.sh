#!/bin/zsh

# Check if the destination directory is provided as an argument
if [ -z "$1" ]; then
  echo "Error: Destination directory not provided."
  exit 1
fi

# Store the destination directory in a variable
destination_dir="$1"

# Copy the files to the specified destination directory
scp -r ../0* "eland:$destination_dir"
scp -r ../1* "eland:$destination_dir"