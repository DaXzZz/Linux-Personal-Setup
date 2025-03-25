#!/bin/bash

set -euo pipefail

# Source shared configuration
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPT_DIR/../config.sh"

# Prompt user to select a backup directory
echo "📦 Available backup snapshots:"
select SNAPSHOT in $(ls -1 $BACKUP_DIR); do
  if [ -n "$SNAPSHOT" ] && [ -d "$BACKUP_DIR/$SNAPSHOT" ]; then
    SELECTED_BACKUP="$BACKUP_DIR/$SNAPSHOT"
    break
  else
    echo "❌ Invalid selection. Please try again."
  fi
done

# Confirm before restoring
read -p "⚠️  This will overwrite your current config files with backup: $SNAPSHOT. Continue? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "❌ Restore cancelled."
  exit 0
fi

# Perform restore
for FILE in "${!RESTORE_PATHS[@]}"; do
  SRC="$SELECTED_BACKUP/$FILE"
  DEST="${RESTORE_PATHS[$FILE]}"

  if [ -f "$SRC" ]; then
    mkdir -p "$(dirname "$DEST")"

    if [[ "$DEST" == /etc/* ]]; then
      echo "🔁 Restoring with sudo: $SRC -> $DEST"
      sudo cp -f "$SRC" "$DEST"
    else
      echo "🔁 Restoring: $SRC -> $DEST"
      cp -f "$SRC" "$DEST"
    fi
  else
    echo "⚠️  Missing in backup: $SRC"
  fi
done

echo "✅ Restore complete from snapshot: $SNAPSHOT"