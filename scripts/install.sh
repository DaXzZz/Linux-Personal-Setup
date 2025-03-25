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

# Check if source config directory exists
if [[ ! -d "$TARGET_DIR" ]]; then
  error_exit "Config directory not found at $TARGET_DIR"
fi

# Create timestamped backup directory
mkdir -p "$TIMED_BACKUP_DIR" || error_exit "Failed to create backup directory: $TIMED_BACKUP_DIR"
echo "📁 Backup directory: $TIMED_BACKUP_DIR"

# Initialize counters
files_installed=0
files_backed_up=0
files_missing=0

# Loop and copy each file
for FILE in "${!RESTORE_PATHS[@]}"; do
  SRC="${TARGET_DIR}/${FILE}.txt"
  DEST="${RESTORE_PATHS[$FILE]}"

  if [[ ! -f "$SRC" ]]; then
    echo "⚠️  Warning: Source file missing: $SRC"
    ((files_missing++))
    continue
  fi

  # Ensure destination directory exists
  mkdir -p "$(dirname "$DEST")" || error_exit "Failed to create directory: $(dirname "$DEST")"

  # Backup existing destination file if it exists
  if [[ -f "$DEST" ]]; then
    if cp "$DEST" "$TIMED_BACKUP_DIR/$(basename "$DEST")"; then
      echo "🔄 Backup of $(basename "$DEST") saved to $TIMED_BACKUP_DIR"
      ((files_backed_up++))
    else
      error_exit "Failed to backup file: $DEST"
    fi
  fi

  # Copy with appropriate permissions
  if [[ "$DEST" == /etc/* ]]; then
    echo "🔧 Installing (sudo): ${FILE}.txt -> $DEST"
    if ! sudo cp -f "$SRC" "$DEST"; then
      error_exit "Failed to install file (sudo): $DEST"
    fi
  else
    echo "📁 Installing: ${FILE}.txt -> $DEST"
    if ! cp -f "$SRC" "$DEST"; then
      error_exit "Failed to install file: $DEST"
    fi
  fi
  
  ((files_installed++))
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
    success "GRUB config updated."
  else
    echo "⚠️  GRUB update failed, but other configs were installed successfully."
  fi
else
  echo "⏭ Skipped GRUB update."
fi

exit 0