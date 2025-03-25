#!/bin/bash

set -euo pipefail

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

# Source shared configuration
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source "${SCRIPT_DIR}/../config.sh" || error_exit "Failed to source config.sh"

# Check if backup directory exists
if [[ ! -d "$BACKUP_DIR" ]]; then
  error_exit "Backup directory does not exist: $BACKUP_DIR"
fi

# Get available backups
AVAILABLE_BACKUPS=($(ls -1 "$BACKUP_DIR" 2>/dev/null))

# Check if any backups exist
if [[ ${#AVAILABLE_BACKUPS[@]} -eq 0 ]]; then
  error_exit "No backup snapshots found in $BACKUP_DIR"
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
    ((AVAILABLE_FILES++))
  fi
done

# Check if backup is sparse
if [[ $AVAILABLE_FILES -eq 0 ]]; then
  error_exit "Selected backup appears to be empty or corrupted"
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

# Perform restore
for FILE in "${!RESTORE_PATHS[@]}"; do
  SRC="$SELECTED_BACKUP/$FILE"
  DEST="${RESTORE_PATHS[$FILE]}"

  if [[ -f "$SRC" ]]; then
    # Create destination directory if it doesn't exist
    mkdir -p "$(dirname "$DEST")" || error_exit "Failed to create directory: $(dirname "$DEST")"

    # Copy file with appropriate permissions
    if [[ "$DEST" == /etc/* ]]; then
      echo "🔁 Restoring with sudo: $SRC -> $DEST"
      if sudo cp -f "$SRC" "$DEST"; then
        ((files_restored++))
      else
        echo "⚠️  Failed to restore: $DEST (sudo issue)"
        ((files_failed++))
      fi
    else
      echo "🔁 Restoring: $SRC -> $DEST"
      if cp -f "$SRC" "$DEST"; then
        ((files_restored++))
      else
        echo "⚠️  Failed to restore: $DEST"
        ((files_failed++))
      fi
    fi
  else
    echo "⚠️  Missing in backup: $SRC"
    ((files_missing++))
  fi
done

# Summary
echo -e "\n🗂️  Restore Summary:"
echo "   - Files restored: $files_restored"
echo "   - Files missing from backup: $files_missing"
echo "   - Files failed to restore: $files_failed"

if [[ $files_failed -gt 0 ]]; then
  echo "⚠️  Some files could not be restored. Check the output above for details."
else
  success "Restore complete from snapshot: $SNAPSHOT"
fi

exit 0