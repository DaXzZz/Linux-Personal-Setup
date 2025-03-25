#!/bin/bash

# Use more basic error handling
set -u

# Fix for path resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source config
source "${SCRIPT_DIR}/config.sh"

# Check if backup directory exists
if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "❌ Error: Backup directory does not exist: $BACKUP_DIR"
  exit 1
fi

# Get available backups
AVAILABLE_BACKUPS=($(ls -1 "$BACKUP_DIR" 2>/dev/null))

# Check if any backups exist
if [[ ${#AVAILABLE_BACKUPS[@]} -eq 0 ]]; then
  echo "❌ Error: No backup snapshots found in $BACKUP_DIR"
  exit 1
fi

# Prompt user to select a backup directory
echo "📦 Available backup snapshots:"
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

for FILE in "${!RESTORE_PATHS[@]}"; do
  if [[ -f "$SELECTED_BACKUP/$FILE" ]]; then
    AVAILABLE_FILES=$((AVAILABLE_FILES + 1))
  fi
done

# Check if backup is sparse
if [[ $AVAILABLE_FILES -eq 0 ]]; then
  echo "❌ Error: Selected backup appears to be empty or corrupted"
  exit 1
elif [[ $AVAILABLE_FILES -lt $TOTAL_FILES ]]; then
  echo "⚠️  Warning: Selected backup contains only $AVAILABLE_FILES of $TOTAL_FILES expected files"
fi

# Confirm before restoring
read -p "⚠️  This will overwrite your current config files with backup: $SNAPSHOT. Continue? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "❌ Restore cancelled."
  exit 0
fi

# Counters for summary
files_restored=0
files_missing=0
files_failed=0

echo "Starting restore process..."
echo "Files to process: $TOTAL_FILES"

# Perform restore
for FILE in "${!RESTORE_PATHS[@]}"; do
  SRC="$SELECTED_BACKUP/$FILE"
  DEST="${RESTORE_PATHS[$FILE]}"
  
  echo "Processing: $FILE -> $DEST"

  if [[ -f "$SRC" ]]; then
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
  else
    echo "⚠️  Missing in backup: $SRC"
    files_missing=$((files_missing + 1))
  fi
  
  echo "-----------------------------------"
done

# Summary
echo -e "\n🗂️  Restore Summary:"
echo "   - Files restored: $files_restored"
echo "   - Files missing from backup: $files_missing"
echo "   - Files failed to restore: $files_failed"

if [[ $files_failed -gt 0 ]]; then
  echo "⚠️  Some files could not be restored. Check the output above for details."
else
  echo "✅ Restore complete from snapshot: $SNAPSHOT"
fi

exit 0