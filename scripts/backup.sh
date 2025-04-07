#!/bin/bash
#
# BACKUP SCRIPT
# =============
# PURPOSE: Creates backups of your configuration files for easy restoration or sharing
#
# WHAT IT DOES:
# - Copies your configuration files to the config/ directory
# - Handles system files (like GRUB) with proper permissions
# - Provides options for selective or complete backups
# - Creates a detailed backup report at the end
#
# WHEN TO USE: Before making system changes or when you want to save your configurations
#

# Fix for path resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source config
source "${SCRIPT_DIR}/config.sh"

# Clear the screen for better readability
clear

# Welcome banner
echo -e "\n========== ARCH HYPRLAND CONFIGURATION BACKUP =========="
echo "This utility will save your current configuration files to the config/ directory."
echo "Files backed up include: GRUB, Hyprland settings, terminal configs, and more."
echo "==========================================================="

# Ask for confirmation
read -p "Do you want to continue with the backup process? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Backup cancelled."
    exit 0
fi

# Setup backup mode
echo -e "\nSelect backup mode:"
echo "1) Complete - Back up all configuration files"
echo "2) Selective - Choose which configurations to back up"
echo "3) Update existing - Only update configurations that have changed"
read -p "Enter your choice (1, 2, or 3): " BACKUP_MODE

case "$BACKUP_MODE" in
    1) BACKUP_TYPE="complete"; echo "Selected: Complete backup" ;;
    2) BACKUP_TYPE="selective"; echo "Selected: Selective backup" ;;
    3) BACKUP_TYPE="update"; echo "Selected: Update existing backups" ;;
    *) echo "Invalid selection. Defaulting to complete backup."; BACKUP_TYPE="complete" ;;
esac

# Choose target subfolder inside config/
echo -e "\nSelect a folder to save this backup:"
CONFIG_SUBFOLDERS=("PC" "Notebook" "Create new folder")
PS3="choose > "
select folder in "${CONFIG_SUBFOLDERS[@]}"; do
    if [[ "$folder" == "Create new folder" ]]; then
        read -p "Enter a name for the new folder: " NEW_FOLDER_NAME
        BACKUP_FOLDER="$TARGET_DIR/$NEW_FOLDER_NAME"
        break
    elif [[ -n "$folder" ]]; then
        BACKUP_FOLDER="$TARGET_DIR/$folder"
        break
    else
        echo "Invalid choice. Try again."
    fi
done

# Create the folder if it doesn't exist
mkdir -p "$BACKUP_FOLDER"
echo "✅ Using backup folder: $BACKUP_FOLDER"


# Create target directory
mkdir -p "$TARGET_DIR"

# Overwrite behavior
if [[ "$BACKUP_TYPE" != "selective" ]]; then
    read -p "Do you want to overwrite existing backed-up files without prompting? (y/n): " OVERWRITE_ALL
    OVERWRITE_ALL=${OVERWRITE_ALL,,} # lowercase
    
    # Validate input
    if [[ ! "$OVERWRITE_ALL" =~ ^[yn]$ ]]; then
        echo "❌ Error: Invalid input. Please enter 'y' or 'n'."
        exit 1
    fi
fi

# Track statistics
files_backed_up=0
files_skipped=0
files_not_found=0
files_overwritten=0
files_unchanged=0

echo -e "\nStarting backup process..."
echo "Files to process: ${#FILES_TO_MANAGE[@]}"
echo "-----------------------------------"

# Process each file from the config
for ((i=0; i<${#FILES_TO_MANAGE[@]}; i++)); do
    FILE="${FILES_TO_MANAGE[$i]}"
    BASENAME=$(basename "$FILE")
    NEW_NAME=${BASENAME#.}.txt
    DEST_FILE="$BACKUP_FOLDER/$NEW_NAME"
    
    # In selective mode, ask if user wants to back up this file
    if [[ "$BACKUP_TYPE" == "selective" ]]; then
        read -p "Back up $FILE? (y/n): " SELECT_FILE
        if [[ ! "$SELECT_FILE" =~ ^[Yy]$ ]]; then
            echo "⏭️ Skipped: $FILE"
            files_skipped=$((files_skipped + 1))
            echo "-----------------------------------"
            continue
        fi
    fi
    
    echo "Processing file $((i+1)) of ${#FILES_TO_MANAGE[@]}: $FILE"
    
    # Check if file exists
    if [[ ! -f "$FILE" ]]; then
        echo "⚠️  Skipped (not found): $FILE"
        files_not_found=$((files_not_found + 1))
        echo "-----------------------------------"
        continue
    fi
    
    # In update mode, check if the file has changed
    if [[ "$BACKUP_TYPE" == "update" && -f "$DEST_FILE" ]]; then
        if cmp -s "$FILE" "$DEST_FILE"; then
            echo "✓ Unchanged: $FILE"
            files_unchanged=$((files_unchanged + 1))
            echo "-----------------------------------"
            continue
        fi
    fi

    # Check if file exists in target and handle overwrite policy
    WILL_OVERWRITE=false
    if [[ -f "$DEST_FILE" ]]; then
        if [[ "$BACKUP_TYPE" == "selective" ]]; then
            read -p "⚠️  $NEW_NAME already exists in config/. Overwrite? (y/n): " CONFIRM
            if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
                WILL_OVERWRITE=true
            else
                echo "⏭️ Skipped: $NEW_NAME"
                files_skipped=$((files_skipped + 1))
                echo "-----------------------------------"
                continue
            fi
        elif [[ "$OVERWRITE_ALL" == "y" ]]; then
            WILL_OVERWRITE=true
        else
            read -p "⚠️  $NEW_NAME already exists in config/. Overwrite? (y/n): " CONFIRM
            if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
                WILL_OVERWRITE=true
            else
                echo "⏭️ Skipped: $NEW_NAME"
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
echo -e "\n========== BACKUP SUMMARY =========="
echo "📊 Statistics:"
echo "   - Files backed up: $files_backed_up"
echo "   - New files: $files_new"
echo "   - Files overwritten: $files_overwritten"
if [[ "$BACKUP_TYPE" == "update" ]]; then
    echo "   - Files unchanged: $files_unchanged"
fi
echo "   - Files skipped: $files_skipped"
echo "   - Files not found: $files_not_found"
echo -e "\n📁 All configs backed up to: $BACKUP_FOLDER"

# Offer to list backed up files
read -p "Do you want to see a list of all backed up files? (y/n): " SHOW_LIST
if [[ "$SHOW_LIST" =~ ^[Yy]$ ]]; then
    echo -e "\nBacked up files (size in KB):"
    ls -la "$BACKUP_FOLDER"
    echo -e "\nNote: The 'total XX' at the top shows disk usage in kilobytes (KB)"
fi

echo -e "\n✅ Backup complete!"
exit 0