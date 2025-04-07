#!/bin/bash
#
# RESTORE SCRIPT
# =============
# PURPOSE: Restores configuration files from a previous backup
#
# WHAT IT DOES:
# - Lets you choose a backup from config/ (profile) or config_backups/ (timestamped)
# - Restores files to their original system locations
# - Uses appropriate permissions
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

# Choose restore source type
echo -e "\nWhere do you want to restore from?"
RESTORE_SOURCES=("Saved config folder (e.g. PC, Notebook)" "Timestamped backup (from install.sh)")
PS3="choose > "
select SOURCE_CHOICE in "${RESTORE_SOURCES[@]}"; do
  case "$REPLY" in
    1)
      echo -e "\nSelect folder from: $TARGET_DIR"
      CONFIG_SUBFOLDERS=($(ls -1 "$TARGET_DIR"))
      PS3="choose > "
      select SUBFOLDER in "${CONFIG_SUBFOLDERS[@]}"; do
        if [[ -n "$SUBFOLDER" ]]; then
          SELECTED_BACKUP="$TARGET_DIR/$SUBFOLDER"
          BACKUP_TYPE="profile"
          break 2
        else
          echo "Invalid selection. Try again."
        fi
      done
      ;;
    2)
      if [[ ! -d "$BACKUP_DIR" ]]; then
        echo "❌ Error: Backup directory does not exist: $BACKUP_DIR"
        exit 1
      fi
      AVAILABLE_BACKUPS=($(ls -1 "$BACKUP_DIR" 2>/dev/null | sort -r))
      if [[ ${#AVAILABLE_BACKUPS[@]} -eq 0 ]]; then
        echo "❌ Error: No timestamped backups found in $BACKUP_DIR"
        exit 1
      fi
      echo -e "\nSelect snapshot from: $BACKUP_DIR"
      PS3="choose > "
      select SNAPSHOT in "${AVAILABLE_BACKUPS[@]}"; do
        if [[ -n "$SNAPSHOT" && -d "$BACKUP_DIR/$SNAPSHOT" ]]; then
          SELECTED_BACKUP="$BACKUP_DIR/$SNAPSHOT"
          BACKUP_TYPE="timestamped"
          break 2
        else
          echo "Invalid selection. Try again."
        fi
      done
      ;;
    *)
      echo "Invalid selection. Try again."
      ;;
  esac
done

echo -e "\n📂 Using backup source: $SELECTED_BACKUP"

# Ask for confirmation
read -p "Do you want to restore configurations from this backup? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Restore cancelled."
    exit 0
fi

# Validate backup integrity
TOTAL_FILES=${#RESTORE_PATHS[@]}
AVAILABLE_FILES=0
AVAILABLE_FILES_LIST=()

echo -e "\n🔍 Scanning backup folder..."
echo "-----------------------------------"
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
echo -e "\n⚠️  IMPORTANT: This will overwrite your current config files with backup: $(basename "$SELECTED_BACKUP")"
read -p "Are you sure you want to continue? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "❌ Restore cancelled."
  exit 0
fi

# Counters
files_restored=0
files_missing=0
files_failed=0
files_skipped=0

echo -e "\nStarting restore process..."
echo "Files to process: $AVAILABLE_FILES"
echo "-----------------------------------"

for FILE in "${AVAILABLE_FILES_LIST[@]}"; do
  DEST="${RESTORE_PATHS[$FILE]}"
  SRC="$SELECTED_BACKUP/$(basename "$DEST")"

  echo "Processing: $FILE -> $DEST"

  if [[ "$RESTORE_TYPE" == "selective" ]]; then
    read -p "Restore $FILE to $DEST? (y/n): " SELECT_FILE
    if [[ ! "$SELECT_FILE" =~ ^[Yy]$ ]]; then
      echo "⏭️ Skipped: $FILE"
      files_skipped=$((files_skipped + 1))
      echo "-----------------------------------"
      continue
    fi
  fi

  mkdir -p "$(dirname "$DEST")" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    echo "⚠️  Failed to create directory: $(dirname "$DEST")"
    files_failed=$((files_failed + 1))
    echo "-----------------------------------"
    continue
  fi

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
[[ "$RESTORE_TYPE" == "selective" ]] && echo "   - Files skipped: $files_skipped"
echo "   - Files failed to restore: $files_failed"
echo -e "\n🕒 Restored from backup: $(basename "$SELECTED_BACKUP")"

# GRUB regeneration
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

[[ $files_failed -gt 0 ]] && echo -e "\n⚠️  Some files could not be restored. Check the output above for details." || echo -e "\n✅ Restore completed successfully!"
exit 0
