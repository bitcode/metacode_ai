#!/bin/bash

# Create a temporary file to store the concatenated contents
temp_file=$(mktemp)

# Concatenate files with their names at the beginning
echo "lua/telescope/_extensions/metacode_ai.lua" >> "$temp_file"
cat lua/telescope/_extensions/metacode_ai.lua >> "$temp_file"
echo "" >> "$temp_file"

echo "lua/metacode_ai/init.lua" >> "$temp_file"
cat lua/metacode_ai/init.lua >> "$temp_file"
echo "" >> "$temp_file"

echo "plugin/metacode_ai.vim" >> "$temp_file"
cat plugin/metacode_ai.vim >> "$temp_file"
echo "" >> "$temp_file"

echo "python/metacode_ai/api_keys.py" >> "$temp_file"
cat python/metacode_ai/api_keys.py >> "$temp_file"
echo "" >> "$temp_file"

echo "python/metacode_ai/__init__.py" >> "$temp_file"
cat python/metacode_ai/__init__.py >> "$temp_file"
echo "" >> "$temp_file"

echo "python/metacode_ai/json_parser.py" >> "$temp_file"
cat python/metacode_ai/json_parser.py >> "$temp_file"
echo "" >> "$temp_file"

echo "python/metacode_ai/metacode_ai.py" >> "$temp_file"
cat python/metacode_ai/metacode_ai.py >> "$temp_file"
echo "" >> "$temp_file"

echo "python/metacode_ai/toml_parser.py" >> "$temp_file"
cat python/metacode_ai/toml_parser.py >> "$temp_file"
echo "" >> "$temp_file"

echo "python/setup.py" >> "$temp_file"
cat python/setup.py >> "$temp_file"

# Copy the contents of the temporary file to the clipboard using xclip
cat "$temp_file" | xclip -selection clipboard

# Remove the temporary file
rm "$temp_file"

echo "The contents have been copied to the clipboard."

