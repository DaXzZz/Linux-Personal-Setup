#!/bin/bash

# Use more basic error handling
set -u

# Fix for path resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source config
source "${SCRIPT_DIR}/config.sh"

# Check if source config directory exists
if [[ ! -d "$TARGET_DIR" ]]; then
  echo "❌ Error: Config directory not found at $TARGET_DIR"
  exit 1
fi

# Create timestamped backup directory
mkdir -p "$TIMED_BACKUP_DIR"
echo "📁 Backup directory: $TIMED_BACKUP_DIR"

# Initialize counters
files_installed=0
files_backed_up=0
files_missing=0

echo "Starting installation process..."
echo "Files to process: ${#RESTORE_PATHS[@]}"

# Process each file using counter-based loop
for FILE in "${!RESTORE_PATHS[@]}"; do
  SRC="${TARGET_DIR}/${FILE}.txt"
  DEST="${RESTORE_PATHS[$FILE]}"
  
  echo "Processing: ${FILE} -> ${DEST}"

  # Check source file
  if [[ ! -f "$SRC" ]]; then
    echo "⚠️  Warning: Source file missing: $SRC"
    files_missing=$((files_missing + 1))
    echo "-----------------------------------"
    continue
  fi

  # Ensure destination directory exists
  mkdir -p "$(dirname "$DEST")" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    echo "⚠️  Failed to create directory: $(dirname "$DEST")"
    echo "-----------------------------------"
    continue
  fi

  # Backup existing destination file if it exists
  if [[ -f "$DEST" ]]; then
    cp "$DEST" "$TIMED_BACKUP_DIR/$(basename "$DEST")" 2>/dev/null
    if [[ $? -eq 0 ]]; then
      echo "🔄 Backup of $(basename "$DEST") saved to $TIMED_BACKUP_DIR"
      files_backed_up=$((files_backed_up + 1))
    else
      echo "⚠️  Failed to backup: $DEST (continuing anyway)"
    fi
  fi

  # Copy with appropriate permissions
  if [[ "$DEST" == /etc/* ]]; then
    echo "🔧 Installing (sudo): ${FILE}.txt -> $DEST"
    sudo cp -f "$SRC" "$DEST" 2>/dev/null
    RESULT=$?
  else
    echo "📁 Installing: ${FILE}.txt -> $DEST"
    cp -f "$SRC" "$DEST" 2>/dev/null
    RESULT=$?
  fi
  
  if [[ $RESULT -eq 0 ]]; then
    echo "✅ Installed: $DEST"
    files_installed=$((files_installed + 1))
  else
    echo "⚠️  Failed to install: $DEST"
  fi
  
  echo "-----------------------------------"
done

# Summary
echo -e "\n🗂️  Installation Summary:"
echo "   - Files installed: $files_installed"
echo "   - Files backed up: $files_backed_up"
echo "   - Files missing: $files_missing"
echo -e "\n✅ All config files installed."

# Optional: regenerate GRUB config
read -p "Re-generate GRUB config now? (y/n): " REPLY
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
  echo "🔄 Updating GRUB config..."
  if sudo grub-mkconfig -o /boot/grub/grub.cfg; then
    echo "✅ GRUB config updated."
  else
    echo "⚠️  GRUB update failed, but other configs were installed successfully."
  fi
else
  echo "⏭ Skipped GRUB update."
fi

exit 0