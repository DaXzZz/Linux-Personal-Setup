#!/bin/bash

set -euo pipefail

# Source shared configuration
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source "${SCRIPT_DIR}/../config.sh"

# Error handling function
error_exit() {
    local message="$1"
    echo "❌ Error: $message" >&2
    exit 1
}

# Success function
success() {
    local message="$1"
    echo "✅ $message"
}

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR" || error_exit "Failed to create target directory: $TARGET_DIR"

# Ask user how to handle overwrite behavior
read -p "Do you want to overwrite all existing config files without prompting? (y/n): " OVERWRITE_ALL
OVERWRITE_ALL=${OVERWRITE_ALL,,} # lowercase

# Validate input
if [[ ! "$OVERWRITE_ALL" =~ ^[yn]$ ]]; then
    error_exit "Invalid input. Please enter 'y' or 'n'."
fi

# Track statistics
files_backed_up=0
files_skipped=0
files_not_found=0

# Process each file from the config
for FILE in "${FILES_TO_MANAGE[@]}"; do
    if [[ -f "$FILE" ]]; then
        BASENAME=$(basename "$FILE")
        NEW_NAME=${BASENAME#.}.txt
        DEST_FILE="$TARGET_DIR/$NEW_NAME"

        # Check if file exists in target and handle overwrite policy
        if [[ -f "$DEST_FILE" ]]; then
            if [[ "$OVERWRITE_ALL" != "y" ]]; then
                read -p "⚠️  $NEW_NAME already exists in config/. Overwrite? (y/n): " CONFIRM
                if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
                    echo "⏭ Skipped: $NEW_NAME"
                    ((files_skipped++))
                    continue
                fi
            fi
        fi

        # Copy to config/ directory
        if cp "$FILE" "$DEST_FILE"; then
            success "Saved to config/: $DEST_FILE"
            ((files_backed_up++))
        else
            echo "⚠️  Failed to copy: $FILE"
            ((files_skipped++))
        fi
    else
        echo "⚠️  Skipped (not found): $FILE"
        ((files_not_found++))
    fi
done

# Summary
echo -e "\n🗂️  Backup Summary:"
echo "   - Files backed up: $files_backed_up"
echo "   - Files skipped: $files_skipped"
echo "   - Files not found: $files_not_found"
echo -e "\n🗂️  All selected configs backed up to: $TARGET_DIR"

# Success exit
exit 0