#!/bin/bash

# Check if the input file path is provided as an argument
if [ $# -eq 0 ]; then
    echo "Please provide the input file path as a command line argument."
    exit 1
fi

# Store the input file path from the command line argument
input_file="$1"

# Create a temporary file for storing the filtered data
filtered_file="filtered_data.txt"

# Read the input file line by line
while IFS= read -r line; do
    # Check if T_med value is greater than 999
    t_med=$(echo "$line" | awk '{print $2}')
    if (( $(awk -v t_med="$t_med" 'BEGIN { print (t_med > 999) }') )); then
        # T_med is greater than 999, skip this line
        continue
    fi

    # Append the line to the filtered file
    echo "$line" >> "$filtered_file"
done < "$input_file"

# Replace the original file with the filtered file
mv "$filtered_file" "$input_file"

#echo "Rows with T_med greater than 999 have been removed."