#!/bin/bash

set -euo pipefail

# Source shared configuration
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPT_DIR/../config.sh"

# Check if source config directory exists
if [ ! -d "$TARGET_DIR" ]; then
  echo "❌ Error: Config directory not found at $TARGET_DIR"
  exit 1
fi

# Create timestamped backup directory
mkdir -p "$TIMED_BACKUP_DIR"
echo "📁 Backup directory: $TIMED_BACKUP_DIR"

# Loop and copy each file
for FILE in "${!RESTORE_PATHS[@]}"; do
  SRC="$TARGET_DIR/${FILE}.txt"
  DEST="${RESTORE_PATHS[$FILE]}"

  if [ ! -f "$SRC" ]; then
    echo "⚠️  Warning: Source file missing: $SRC"
    continue
  fi

  # Ensure destination directory exists
  mkdir -p "$(dirname "$DEST")"

  # Backup existing destination file if it exists
  if [ -f "$DEST" ]; then
    cp "$DEST" "$TIMED_BACKUP_DIR/$(basename "$DEST")"
    echo "🔄 Backup of $(basename "$DEST") saved to $TIMED_BACKUP_DIR"
  fi

  # Copy with appropriate permissions
  if [[ "$DEST" == /etc/* ]]; then
    echo "🔧 Installing (sudo): ${FILE}.txt -> $DEST"
    sudo cp -f "$SRC" "$DEST"
  else
    echo "📁 Installing: ${FILE}.txt -> $DEST"
    cp -f "$SRC" "$DEST"
  fi

done

echo -e "\n✅ All config files restored."

# Optional: regenerate GRUB config
read -p "Re-generate GRUB config now? (y/n): " REPLY
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
  echo "🔄 Updating GRUB config..."
  sudo grub-mkconfig -o /boot/grub/grub.cfg
  echo "✅ GRUB config updated."
else
  echo "⏭ Skipped GRUB update."
fi