#!/bin/bash

ENV_FILE=".metacode_ai.env"
TARGET_DIR="/home/$USER"

if [ -f "$ENV_FILE" ]; then
  if [ ! -f "$TARGET_DIR/$ENV_FILE" ]; then
    mv "$ENV_FILE" "$TARGET_DIR/"
    echo "Moved $ENV_FILE to $TARGET_DIR"
  else
    echo "$TARGET_DIR/$ENV_FILE already exists. Skipping."
  fi
else
  echo "$ENV_FILE not found. Please create it and move it manually."
fi
