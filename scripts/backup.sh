#!/bin/bash
#
# BACKUP SCRIPT
# =============
# PURPOSE: Creates backups of your configuration files for easy restoration or sharing

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

read -p "Do you want to continue with the backup process? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Backup cancelled."
    exit 0
fi

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

# Set ALL folder
ALL_BACKUP_FOLDER="$SCRIPT_DIR/config/PC/ALL"
mkdir -p "$ALL_BACKUP_FOLDER"

# Prepare folder options for UserSettings
CONFIG_SUBFOLDERS=("PC" "Notebook" "Create new folder")

# Overwrite behavior
if [[ "$BACKUP_TYPE" != "selective" ]]; then
    read -p "Do you want to overwrite existing backed-up files without prompting? (y/n): " OVERWRITE_ALL
    OVERWRITE_ALL=${OVERWRITE_ALL,,}
    if [[ ! "$OVERWRITE_ALL" =~ ^[yn]$ ]]; then
        echo "❌ Error: Invalid input. Please enter 'y' or 'n'."
        exit 1
    fi
fi

# Stats
files_backed_up=0
files_skipped=0
files_not_found=0
files_overwritten=0
files_unchanged=0

echo -e "\nStarting backup process..."
echo "Files to process: ${#FILES_TO_MANAGE[@]}"
echo "-----------------------------------"

for ((i=0; i<${#FILES_TO_MANAGE[@]}; i++)); do
    FILE="${FILES_TO_MANAGE[$i]}"
    BASENAME=$(basename "$FILE")
    NEW_NAME="${BASENAME#.}.txt"

    # Special handling for UserSettings
    if [[ "$BASENAME" == "UserSettings.conf" || "$NEW_NAME" == "UserSettings.conf.txt" ]]; then
        echo -e "\n📌 Detected UserSettings file: $FILE"
        echo "Please choose where to store this file:"
        PS3="choose > "
        select folder in "${CONFIG_SUBFOLDERS[@]}"; do
            if [[ "$folder" == "Create new folder" ]]; then
                read -p "Enter new folder name: " NEW_FOLDER
                SPECIAL_FOLDER="$SCRIPT_DIR/config/$NEW_FOLDER"
                break
            elif [[ -n "$folder" ]]; then
                SPECIAL_FOLDER="$SCRIPT_DIR/config/$folder"
                break
            else
                echo "Invalid choice. Try again."
            fi
        done
        mkdir -p "$SPECIAL_FOLDER"
        DEST_FILE="$SPECIAL_FOLDER/$NEW_NAME"
    else
        DEST_FILE="$ALL_BACKUP_FOLDER/$NEW_NAME"
    fi

    # Selective mode ask per-file
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

    if [[ ! -f "$FILE" ]]; then
        echo "⚠️  Skipped (not found): $FILE"
        files_not_found=$((files_not_found + 1))
        echo "-----------------------------------"
        continue
    fi

    # Check for unchanged in update mode
    if [[ "$BACKUP_TYPE" == "update" && -f "$DEST_FILE" ]]; then
        if cmp -s "$FILE" "$DEST_FILE"; then
            echo "✓ Unchanged: $FILE"
            files_unchanged=$((files_unchanged + 1))
            echo "-----------------------------------"
            continue
        fi
    fi

    # Check for overwrite
    WILL_OVERWRITE=false
    if [[ -f "$DEST_FILE" ]]; then
        if [[ "$BACKUP_TYPE" == "selective" ]]; then
            read -p "⚠️  $NEW_NAME already exists. Overwrite? (y/n): " CONFIRM
            [[ "$CONFIRM" =~ ^[Yy]$ ]] && WILL_OVERWRITE=true || {
                echo "⏭️ Skipped: $NEW_NAME"
                files_skipped=$((files_skipped + 1))
                echo "-----------------------------------"
                continue
            }
        elif [[ "$OVERWRITE_ALL" == "y" ]]; then
            WILL_OVERWRITE=true
        else
            read -p "⚠️  $NEW_NAME already exists. Overwrite? (y/n): " CONFIRM
            [[ "$CONFIRM" =~ ^[Yy]$ ]] && WILL_OVERWRITE=true || {
                echo "⏭️ Skipped: $NEW_NAME"
                files_skipped=$((files_skipped + 1))
                echo "-----------------------------------"
                continue
            }
        fi
    fi

    # Copy file
    if [[ "$FILE" == /etc/* ]]; then
        sudo cp -f "$FILE" "$DEST_FILE" 2>/dev/null
        RESULT=$?
    else
        cp -f "$FILE" "$DEST_FILE" 2>/dev/null
        RESULT=$?
    fi

    if [[ $RESULT -eq 0 ]]; then
        echo "✅ Saved: $DEST_FILE"
        files_backed_up=$((files_backed_up + 1))
        [[ "$WILL_OVERWRITE" == true ]] && files_overwritten=$((files_overwritten + 1))
    else
        echo "⚠️  Failed to copy: $FILE"
        files_skipped=$((files_skipped + 1))
    fi

    echo "-----------------------------------"
done

files_new=$((files_backed_up - files_overwritten))

echo -e "\n========== BACKUP SUMMARY =========="
echo "📊 Statistics:"
echo "   - Files backed up: $files_backed_up"
echo "   - New files: $files_new"
echo "   - Files overwritten: $files_overwritten"
[[ "$BACKUP_TYPE" == "update" ]] && echo "   - Files unchanged: $files_unchanged"
echo "   - Files skipped: $files_skipped"
echo "   - Files not found: $files_not_found"
echo -e "\n📁 ALL configs saved to: $ALL_BACKUP_FOLDER (except UserSettings)"

read -p "Do you want to see a list of all backed up files? (y/n): " SHOW_LIST
if [[ "$SHOW_LIST" =~ ^[Yy]$ ]]; then
    echo -e "\nBacked up files:"
    find "$SCRIPT_DIR/config" -type f -exec ls -lh {} \;
fi

echo -e "\n✅ Backup complete!"
exit 0
