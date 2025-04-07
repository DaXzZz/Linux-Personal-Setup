#!/bin/bash
#
# INSTALL SCRIPT
# =============
# PURPOSE: Installs saved configuration files to their proper system locations
#
# WHAT IT DOES:
# - Installs configuration files from config/ to their proper system locations
# - Creates automatic backups of current files before replacing them
# - Uses appropriate permissions for system files
# - Optionally regenerates GRUB configuration
#
# WHEN TO USE: When setting up a new system or applying saved configurations
#

# Fix for path resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source config
source "${SCRIPT_DIR}/config.sh"

# Clear the screen for better readability
clear

# Welcome banner
echo -e "\n========== ARCH HYPRLAND CONFIGURATION INSTALLER =========="
echo "This utility will install your saved configurations from the config/ directory"
echo "to their proper locations on your system. Your current files will be backed up"
echo "automatically before being replaced."
echo "=============================================================="

# Recommend running setup_essentials.sh first
echo -e "\n⚠️  RECOMMENDED: Run 'setup_essentials.sh' before continuing."
echo "   This will ensure all required packages and dependencies are installed."
read -p "Have you already run setup_essentials.sh on this system? (y/n): " confirm_essentials
if [[ ! "$confirm_essentials" =~ ^[Yy]$ ]]; then
    echo "🛑 Please run setup_essentials.sh first, then rerun this script."
    exit 1
fi

# Check if source config directory exists
if [[ ! -d "$TARGET_DIR" ]]; then
  echo "❌ Error: Config directory not found at $TARGET_DIR"
  echo "Please run backup.sh first to create configuration files."
  exit 1
fi

# Select the subfolder to install from
echo -e "\nSelect the backup folder to install from:"
CONFIG_SUBFOLDERS=("PC" "Notebook" "Other (type manually)")
PS3="choose > "
select folder in "${CONFIG_SUBFOLDERS[@]}"; do
    if [[ "$folder" == "Other (type manually)" ]]; then
        read -p "Enter folder name under config/: " MANUAL_FOLDER
        INSTALL_SOURCE_FOLDER="$TARGET_DIR/$MANUAL_FOLDER"
        break
    elif [[ -n "$folder" ]]; then
        INSTALL_SOURCE_FOLDER="$TARGET_DIR/$folder"
        break
    else
        echo "Invalid choice. Try again."
    fi
done

# Validate selected folder
if [[ ! -d "$INSTALL_SOURCE_FOLDER" ]]; then
    echo "❌ Error: Folder '$INSTALL_SOURCE_FOLDER' does not exist."
    exit 1
fi
echo "📂 Using folder: $INSTALL_SOURCE_FOLDER"

# Count available configuration files
AVAILABLE_CONFIGS=0
for FILE in "${!RESTORE_PATHS[@]}"; do
  SRC="${INSTALL_SOURCE_FOLDER}/${FILE}.txt"
  if [[ -f "$SRC" ]]; then
    AVAILABLE_CONFIGS=$((AVAILABLE_CONFIGS + 1))
  fi
done

if [[ $AVAILABLE_CONFIGS -eq 0 ]]; then
  echo "❌ Error: No configuration files found in $INSTALL_SOURCE_FOLDER"
  echo "Please run backup.sh first to create configuration files."
  exit 1
fi

# Ask for confirmation
read -p "This will install $AVAILABLE_CONFIGS configuration files. Continue? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi


# Setup installation mode
echo -e "\nSelect installation mode:"
echo "1) Complete - Install all available configurations"
echo "2) Selective - Choose which configurations to install"
read -p "Enter your choice (1 or 2): " INSTALL_MODE

case "$INSTALL_MODE" in
    1) INSTALL_TYPE="complete"; echo "Selected: Complete installation" ;;
    2) INSTALL_TYPE="selective"; echo "Selected: Selective installation" ;;
    *) echo "Invalid selection. Defaulting to complete installation."; INSTALL_TYPE="complete" ;;
esac

# Create timestamped backup directory
mkdir -p "$TIMED_BACKUP_DIR"
echo -e "\n📁 Backup directory: $TIMED_BACKUP_DIR"

# Initialize counters
files_installed=0
files_backed_up=0
files_missing=0
files_skipped=0

echo -e "\nStarting installation process..."
echo "Files to process: $AVAILABLE_CONFIGS"
echo "-----------------------------------"

# Process each file
for FILE in "${!RESTORE_PATHS[@]}"; do
  SRC="${INSTALL_SOURCE_FOLDER}/${FILE}.txt"
  DEST="${RESTORE_PATHS[$FILE]}"
  
  # Skip if source doesn't exist
  if [[ ! -f "$SRC" ]]; then
    files_missing=$((files_missing + 1))
    continue
  fi
  
  echo "Processing: ${FILE}.txt -> $DEST"
  
  # In selective mode, ask if user wants to install this file
  if [[ "$INSTALL_TYPE" == "selective" ]]; then
    read -p "Install $FILE to $DEST? (y/n): " SELECT_FILE
    if [[ ! "$SELECT_FILE" =~ ^[Yy]$ ]]; then
        echo "⏭️ Skipped: $FILE"
        files_skipped=$((files_skipped + 1))
        echo "-----------------------------------"
        continue
    fi
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
    files_skipped=$((files_skipped + 1))
  fi
  
  echo "-----------------------------------"
done

# Summary
echo -e "\n========== INSTALLATION SUMMARY =========="
echo "📊 Statistics:"
echo "   - Files installed: $files_installed"
echo "   - Files backed up: $files_backed_up"
echo "   - Files skipped: $files_skipped"
echo "   - Files missing: $files_missing"
echo -e "\n💾 All configurations installed from: $INSTALL_SOURCE_FOLDER"
echo "🛡️  Backups saved to: $TIMED_BACKUP_DIR"

# Optional: regenerate GRUB config
if [[ -f "/etc/default/grub" && -f "${INSTALL_SOURCE_FOLDER}/grub.txt" ]]; then
  echo -e "\nGRUB configuration was updated."
  read -p "Do you want to regenerate GRUB config now? (y/n): " REPLY
  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    echo "🔄 Updating GRUB config..."
    if sudo grub-mkconfig -o /boot/grub/grub.cfg; then
      echo "✅ GRUB config regenerated successfully."
    else
      echo "⚠️  GRUB update failed, but other configs were installed successfully."
    fi
  else
    echo "⏭️ Skipped GRUB regeneration."
    echo "Remember to run 'sudo grub-mkconfig -o /boot/grub/grub.cfg' manually."
  fi
fi

echo -e "\n✅ Installation complete!"
exit 0