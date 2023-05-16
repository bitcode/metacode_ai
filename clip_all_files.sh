#!/bin/bash

# Initialize a variable to hold the file content
content=""

# Add content of each file to the variable
for file in lua/metacode_ai/init.lua lua/telescope/_extensions/metacode_ai.lua plugin/metacode_ai.vim python/metacode_ai/metacode_ai.py
do
    if [ -f "$file" ]; then
        content+="===== $file ====="
        content+=$'\n'
        content+=$(cat "$file")
        content+=$'\n\n' # Adds a newline between files
    else
        echo "File $file does not exist"
    fi
done

# Copy the concatenated content to the clipboard
echo "$content" | xclip -selection clipboard

echo "The contents have been copied to the clipboard."

