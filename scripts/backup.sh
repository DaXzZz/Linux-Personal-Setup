#!/bin/bash

set -euo pipefail

# Source shared configuration
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPT_DIR/../config.sh"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Ask user how to handle overwrite behavior
read -p "Do you want to overwrite all existing config files without prompting? (y/n): " OVERWRITE_ALL
OVERWRITE_ALL=${OVERWRITE_ALL,,} # lowercase

# Process each file from the config
for FILE in "${FILES_TO_MANAGE[@]}"; do
  if [ -f "$FILE" ]; then
    BASENAME=$(basename "$FILE")
    NEW_NAME=${BASENAME#.}.txt
    DEST_FILE="$TARGET_DIR/$NEW_NAME"

    # Check if file exists in target and handle overwrite policy
    if [ -f "$DEST_FILE" ]; then
      if [[ "$OVERWRITE_ALL" != "y" ]]; then
        read -p "⚠️  $NEW_NAME already exists in config/. Overwrite? (y/n): " CONFIRM
        if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
          echo "⏭ Skipped: $NEW_NAME"
          continue
        fi
      fi
    fi

    # Copy to config/ directory
    cp "$FILE" "$DEST_FILE"
    echo "✅ Saved to config/: $DEST_FILE"
  else
    echo "⚠️  Skipped (not found): $FILE"
  fi
done

echo -e "\n🗂️  All selected configs backed up to: $TARGET_DIR"