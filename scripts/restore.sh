#!/bin/bash
#
# RESTORE SCRIPT
# =============
# PURPOSE: Restores configuration files from a previous backup
#
# WHAT IT DOES:
# - Shows available automatic backup snapshots by date
# - Lets you select which backup to restore from
# - Restores saved files to their original system locations
# - Uses appropriate permissions for system files
#
# WHEN TO USE: When you need to revert to a previous configuration state
#

# Fix for path resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source config
source "${SCRIPT_DIR}/config.sh"

# Clear the screen for better readability
clear

# Welcome banner
echo -e "\n========== ARCH HYPRLAND CONFIGURATION RESTORE =========="
echo "This utility will restore your configuration files from a previous backup."
echo "It will replace your current configurations with the selected backup versions."
echo "============================================================"

# Check if backup directory exists
if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "❌ Error: Backup directory does not exist: $BACKUP_DIR"
  exit 1
fi

# Get available backups
AVAILABLE_BACKUPS=($(ls -1 "$BACKUP_DIR" 2>/dev/null | sort -r))

# Check if any backups exist
if [[ ${#AVAILABLE_BACKUPS[@]} -eq 0 ]]; then
  echo "❌ Error: No backup snapshots found in $BACKUP_DIR"
  exit 1
fi

# Ask for confirmation
read -p "Do you want to restore configurations from a previous backup? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Restore cancelled."
    exit 0
fi

# Show available backups with more details
echo -e "\n📦 Available backup snapshots:"
echo "-----------------------------------"
for i in "${!AVAILABLE_BACKUPS[@]}"; do
  SNAPSHOT="${AVAILABLE_BACKUPS[$i]}"
  SNAPSHOT_PATH="$BACKUP_DIR/$SNAPSHOT"
  
  # Count files in this backup
  FILE_COUNT=$(find "$SNAPSHOT_PATH" -type f | wc -l)
  
  # Get creation date in readable format
  if [[ -d "$SNAPSHOT_PATH" ]]; then
    CREATE_DATE=$(stat -c "%y" "$SNAPSHOT_PATH" | cut -d. -f1)
    echo "[$((i+1))] $SNAPSHOT"
    echo "    📅 Created: $CREATE_DATE"
    echo "    📄 Files: $FILE_COUNT"
    echo "-----------------------------------"
  fi
done

# Prompt user to select a backup directory
PS3="Select a backup number (1-${#AVAILABLE_BACKUPS[@]}): "
select SNAPSHOT in "${AVAILABLE_BACKUPS[@]}"; do
  if [[ -n "$SNAPSHOT" ]] && [[ -d "$BACKUP_DIR/$SNAPSHOT" ]]; then
    SELECTED_BACKUP="$BACKUP_DIR/$SNAPSHOT"
    break
  else
    echo "❌ Invalid selection. Please try again."
  fi
done

# Validate backup integrity
TOTAL_FILES=${#RESTORE_PATHS[@]}
AVAILABLE_FILES=0

# Check which files are available in the selected backup
echo -e "\n🔍 Scanning backup: $SNAPSHOT"
echo "-----------------------------------"
AVAILABLE_FILES_LIST=()

for FILE in "${!RESTORE_PATHS[@]}"; do
  if [[ -f "$SELECTED_BACKUP/$(basename "${RESTORE_PATHS[$FILE]}")" ]]; then
    AVAILABLE_FILES=$((AVAILABLE_FILES + 1))
    AVAILABLE_FILES_LIST+=("$FILE")
    echo "✓ Found: $FILE"
  else
    echo "⚠️ Missing: $FILE"
  fi
done
echo "-----------------------------------"

# Check if backup is sparse
if [[ $AVAILABLE_FILES -eq 0 ]]; then
  echo "❌ Error: Selected backup appears to be empty or corrupted"
  exit 1
elif [[ $AVAILABLE_FILES -lt $TOTAL_FILES ]]; then
  echo "⚠️  Warning: Selected backup contains only $AVAILABLE_FILES of $TOTAL_FILES expected files"
  read -p "Continue with partial restore? (y/n): " PARTIAL
  if [[ ! "$PARTIAL" =~ ^[Yy]$ ]]; then
    echo "Restore cancelled."
    exit 0
  fi
fi

# Setup restore mode
echo -e "\nSelect restore mode:"
echo "1) Complete - Restore all available configurations from backup"
echo "2) Selective - Choose which configurations to restore"
read -p "Enter your choice (1 or 2): " RESTORE_MODE

case "$RESTORE_MODE" in
    1) RESTORE_TYPE="complete"; echo "Selected: Complete restore" ;;
    2) RESTORE_TYPE="selective"; echo "Selected: Selective restore" ;;
    *) echo "Invalid selection. Defaulting to complete restore."; RESTORE_TYPE="complete" ;;
esac

# Confirm before restoring
echo -e "\n⚠️  IMPORTANT: This will overwrite your current config files with backup: $SNAPSHOT"
read -p "Are you sure you want to continue? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "❌ Restore cancelled."
  exit 0
fi

# Counters for summary
files_restored=0
files_missing=0
files_failed=0
files_skipped=0

echo -e "\nStarting restore process..."
echo "Files to process: $AVAILABLE_FILES"
echo "-----------------------------------"

# Perform restore
for FILE in "${AVAILABLE_FILES_LIST[@]}"; do
  DEST="${RESTORE_PATHS[$FILE]}"
  SRC="$SELECTED_BACKUP/$(basename "$DEST")"
  
  echo "Processing: $FILE -> $DEST"
  
  # In selective mode, ask if user wants to restore this file
  if [[ "$RESTORE_TYPE" == "selective" ]]; then
    read -p "Restore $FILE to $DEST? (y/n): " SELECT_FILE
    if [[ ! "$SELECT_FILE" =~ ^[Yy]$ ]]; then
        echo "⏭️ Skipped: $FILE"
        files_skipped=$((files_skipped + 1))
        echo "-----------------------------------"
        continue
    fi
  fi

  # Create destination directory if it doesn't exist
  mkdir -p "$(dirname "$DEST")" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    echo "⚠️  Failed to create directory: $(dirname "$DEST")"
    files_failed=$((files_failed + 1))
    echo "-----------------------------------"
    continue
  fi

  # Copy file with appropriate permissions
  if [[ "$DEST" == /etc/* ]]; then
    echo "🔁 Restoring with sudo: $SRC -> $DEST"
    sudo cp -f "$SRC" "$DEST" 2>/dev/null
    RESULT=$?
  else
    echo "🔁 Restoring: $SRC -> $DEST"
    cp -f "$SRC" "$DEST" 2>/dev/null
    RESULT=$?
  fi
  
  if [[ $RESULT -eq 0 ]]; then
    echo "✅ Restored: $DEST"
    files_restored=$((files_restored + 1))
  else
    echo "⚠️  Failed to restore: $DEST"
    files_failed=$((files_failed + 1))
  fi
  
  echo "-----------------------------------"
done

# Summary
echo -e "\n========== RESTORE SUMMARY =========="
echo "📊 Statistics:"
echo "   - Files restored: $files_restored"
if [[ "$RESTORE_TYPE" == "selective" ]]; then
  echo "   - Files skipped: $files_skipped"
fi
echo "   - Files missing from backup: $files_missing"
echo "   - Files failed to restore: $files_failed"
echo -e "\n🕒 Restored from backup: $SNAPSHOT"

# Optional: regenerate GRUB config if it was restored
if [[ -f "/etc/default/grub" ]] && [[ $files_restored -gt 0 ]]; then
  for FILE in "${AVAILABLE_FILES_LIST[@]}"; do
    if [[ "$FILE" == "grub" ]]; then
      echo -e "\nGRUB configuration was restored."
      read -p "Do you want to regenerate GRUB config now? (y/n): " REPLY
      if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        echo "🔄 Updating GRUB config..."
        if sudo grub-mkconfig -o /boot/grub/grub.cfg; then
          echo "✅ GRUB config regenerated successfully."
        else
          echo "⚠️  GRUB update failed, but other configs were restored successfully."
        fi
      else
        echo "⏭️ Skipped GRUB regeneration."
        echo "Remember to run 'sudo grub-mkconfig -o /boot/grub/grub.cfg' manually."
      fi
      break
    fi
  done
fi

if [[ $files_failed -gt 0 ]]; then
  echo -e "\n⚠️  Some files could not be restored. Check the output above for details."
else
  echo -e "\n✅ Restore completed successfully!"
fi

exit 0