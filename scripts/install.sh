#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
clear

echo -e "\n========== ARCH HYPRLAND CONFIGURATION INSTALLER =========="
echo "This utility will install your saved configurations from a backup folder."
echo "=============================================================="

echo -e "\n⚠️  RECOMMENDED: Run 'setup_essentials.sh' before continuing."
read -p "Have you already run setup_essentials.sh on this system? (y/n): " confirm_essentials
if [[ ! "$confirm_essentials" =~ ^[Yy]$ ]]; then
    echo "🛑 Please run setup_essentials.sh first, then rerun this script."
    exit 1
fi

# Default path: config/PC/ALL
INSTALL_SOURCE_FOLDER="$SCRIPT_DIR/config/PC/ALL"
mkdir -p "$INSTALL_SOURCE_FOLDER"

# For UserSettings file only, ask the user
CONFIG_SUBFOLDERS=("PC" "Notebook" "Create new folder")
USERSETTINGS_FOLDER=""
USERSETTINGS_FILE="UserSettings.conf.txt"

if [[ -f "$SCRIPT_DIR/config/PC/ALL/$USERSETTINGS_FILE" ]]; then
    echo -e "\n📌 Found $USERSETTINGS_FILE — where should this be installed from?"
    PS3="choose > "
    select folder in "${CONFIG_SUBFOLDERS[@]}"; do
        if [[ "$folder" == "Create new folder" ]]; then
            read -p "Enter folder name: " NEWFOLDER
            USERSETTINGS_FOLDER="$SCRIPT_DIR/config/$NEWFOLDER"
            break
        elif [[ -n "$folder" ]]; then
            USERSETTINGS_FOLDER="$SCRIPT_DIR/config/$folder"
            break
        else
            echo "Invalid selection. Try again."
        fi
    done
fi

echo "📂 Using source folders:"
echo "- Main configs: $INSTALL_SOURCE_FOLDER"
[[ -n "$USERSETTINGS_FOLDER" ]] && echo "- UserSettings.conf.txt: $USERSETTINGS_FOLDER"

echo -e "\nSelect installation mode:"
echo "1) Complete - Install all available configurations"
echo "2) Selective - Choose which configurations to install"
read -p "Enter your choice (1 or 2): " INSTALL_MODE

case "$INSTALL_MODE" in
    1) INSTALL_TYPE="complete"; echo "Selected: Complete installation" ;;
    2) INSTALL_TYPE="selective"; echo "Selected: Selective installation" ;;
    *) echo "Invalid selection. Defaulting to complete installation."; INSTALL_TYPE="complete" ;;
esac

# Count available configs
AVAILABLE_CONFIGS=0
for FILE in "${!RESTORE_PATHS[@]}"; do
    SRC_MAIN="${INSTALL_SOURCE_FOLDER}/${FILE}.txt"
    SRC_USER="${USERSETTINGS_FOLDER}/${FILE}.txt"
    [[ -f "$SRC_MAIN" || -f "$SRC_USER" ]] && AVAILABLE_CONFIGS=$((AVAILABLE_CONFIGS + 1))
done

if [[ $AVAILABLE_CONFIGS -eq 0 ]]; then
    echo "❌ No configuration files found."
    exit 1
fi

read -p "This will install $AVAILABLE_CONFIGS configuration files. Continue? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Setup backup directory
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TIMED_BACKUP_DIR="${BACKUP_DIR}/backup_${TIMESTAMP}"
mkdir -p "$TIMED_BACKUP_DIR"
echo -e "\n📁 Backup directory: $TIMED_BACKUP_DIR"

files_installed=0
files_backed_up=0
files_missing=0
files_skipped=0

echo -e "\nStarting installation process..."
echo "Files to process: $AVAILABLE_CONFIGS"
echo "-----------------------------------"

for FILE in "${!RESTORE_PATHS[@]}"; do
    DEST="${RESTORE_PATHS[$FILE]}"
    SRC=""

    # Determine source
    if [[ "$FILE" == "UserSettings.conf" && -n "$USERSETTINGS_FOLDER" ]]; then
        SRC="$USERSETTINGS_FOLDER/${FILE}.txt"
    else
        SRC="$INSTALL_SOURCE_FOLDER/${FILE}.txt"
    fi

    if [[ ! -f "$SRC" ]]; then
        files_missing=$((files_missing + 1))
        continue
    fi

    echo "Processing: ${FILE}.txt -> $DEST"

    if [[ "$INSTALL_TYPE" == "selective" ]]; then
        read -p "Install $FILE to $DEST? (y/n): " SELECT_FILE
        if [[ ! "$SELECT_FILE" =~ ^[Yy]$ ]]; then
            echo "⏭️ Skipped: $FILE"
            files_skipped=$((files_skipped + 1))
            echo "-----------------------------------"
            continue
        fi
    fi

    mkdir -p "$(dirname "$DEST")" 2>/dev/null || {
        echo "⚠️ Failed to create directory: $(dirname "$DEST")"
        echo "-----------------------------------"
        continue
    }

    if [[ -f "$DEST" ]]; then
        cp "$DEST" "$TIMED_BACKUP_DIR/$(basename "$DEST")" 2>/dev/null && {
            echo "🔄 Backup of $(basename "$DEST") saved to $TIMED_BACKUP_DIR"
            files_backed_up=$((files_backed_up + 1))
        }
    fi

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
        echo "⚠️ Failed to install: $DEST"
        files_skipped=$((files_skipped + 1))
    fi

    echo "-----------------------------------"
done

echo -e "\n========== INSTALLATION SUMMARY =========="
echo "📊 Statistics:"
echo "   - Files installed: $files_installed"
echo "   - Files backed up: $files_backed_up"
echo "   - Files skipped: $files_skipped"
echo "   - Files missing: $files_missing"
echo -e "\n📂 Installed from: $INSTALL_SOURCE_FOLDER"
echo "🛡️  Backups saved to: $TIMED_BACKUP_DIR"

# GRUB
echo -e "\nChecking GRUB config..."
if [[ -f "/etc/default/grub" && -f "${INSTALL_SOURCE_FOLDER}/grub.txt" ]]; then
  echo -e "\nGRUB configuration was updated."
  read -p "Do you want to regenerate GRUB config now? (y/n): " REPLY
  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    echo "🔄 Updating GRUB config..."
    if sudo grub-mkconfig -o /boot/grub/grub.cfg; then
      echo "✅ GRUB config regenerated successfully."
    else
      echo "⚠️ GRUB update failed, but other configs were installed successfully."
    fi
  else
    echo "⏭️ Skipped GRUB regeneration."
    echo "Remember to run 'sudo grub-mkconfig -o /boot/grub/grub.cfg' manually."
  fi
fi

echo -e "\n✅ Installation complete!"
exit 0
