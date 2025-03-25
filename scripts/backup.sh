#!/bin/bash

# Use more basic error handling
set -u

# Fix for path resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source config
source "${SCRIPT_DIR}/config.sh"

# Create target directory
mkdir -p "$TARGET_DIR"

# Ask user how to handle overwrite behavior
read -p "Do you want to overwrite all existing config files without prompting? (y/n): " OVERWRITE_ALL
OVERWRITE_ALL=${OVERWRITE_ALL,,} # lowercase

# Validate input
if [[ ! "$OVERWRITE_ALL" =~ ^[yn]$ ]]; then
    echo "❌ Error: Invalid input. Please enter 'y' or 'n'."
    exit 1
fi

# Track statistics
files_backed_up=0
files_skipped=0
files_not_found=0
files_overwritten=0  # Added counter for overwritten files

echo "Starting backup process..."
echo "Files to process: ${#FILES_TO_MANAGE[@]}"

# Process each file from the config
for ((i=0; i<${#FILES_TO_MANAGE[@]}; i++)); do
    FILE="${FILES_TO_MANAGE[$i]}"
    echo "Processing file $((i+1)) of ${#FILES_TO_MANAGE[@]}: $FILE"
    
    # Check if file exists
    if [[ ! -f "$FILE" ]]; then
        echo "⚠️  Skipped (not found): $FILE"
        files_not_found=$((files_not_found + 1))
        continue
    fi

    BASENAME=$(basename "$FILE")
    NEW_NAME=${BASENAME#.}.txt
    DEST_FILE="$TARGET_DIR/$NEW_NAME"

    # Check if file exists in target and handle overwrite policy
    WILL_OVERWRITE=false
    if [[ -f "$DEST_FILE" ]]; then
        if [[ "$OVERWRITE_ALL" == "y" ]]; then
            WILL_OVERWRITE=true
        else
            read -p "⚠️  $NEW_NAME already exists in config/. Overwrite? (y/n): " CONFIRM
            if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
                WILL_OVERWRITE=true
            else
                echo "⏭ Skipped: $NEW_NAME"
                files_skipped=$((files_skipped + 1))
                echo "-----------------------------------"
                continue
            fi
        fi
    fi

    # Copy to config/ directory
    if [[ "$FILE" == /etc/* ]]; then
        # For system files, use sudo
        sudo cp -f "$FILE" "$DEST_FILE" 2>/dev/null
        RESULT=$?
    else
        # For user files
        cp -f "$FILE" "$DEST_FILE" 2>/dev/null
        RESULT=$?
    fi
    
    # Check result
    if [[ $RESULT -eq 0 ]]; then
        echo "✅ Saved to config/: $DEST_FILE"
        files_backed_up=$((files_backed_up + 1))
        
        # Count overwritten files
        if [[ "$WILL_OVERWRITE" == "true" ]]; then
            files_overwritten=$((files_overwritten + 1))
        fi
    else
        echo "⚠️  Failed to copy: $FILE"
        files_skipped=$((files_skipped + 1))
    fi
    
    echo "-----------------------------------"
done

# Calculate net new files (backed up minus overwritten)
files_new=$((files_backed_up - files_overwritten))

# Summary
echo -e "\n🗂️  Backup Summary:"
echo "   - Files backed up: $files_backed_up"
echo "   - New files: $files_new"
echo "   - Files overwritten: $files_overwritten"
echo "   - Files skipped: $files_skipped"
echo "   - Files not found: $files_not_found"
echo -e "\n🗂️  All selected configs backed up to: $TARGET_DIR"

exit 0