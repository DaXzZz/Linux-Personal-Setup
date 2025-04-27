# install.sh
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
clear

echo -e "\n========== ARCH HYPRLAND CONFIGURATION INSTALLER =========="
echo "This utility will install your saved configurations from a backup folder."
echo "=============================================================="

# Recommend running setup_essentials.sh first
echo -e "\n\u26a0\ufe0f  RECOMMENDED: Run 'setup_essentials.sh' before continuing."
read -p "Have you already run setup_essentials.sh on this system? (y/n): " confirm_essentials
if [[ ! "$confirm_essentials" =~ ^[Yy]$ ]]; then
    echo "\ud83d\uded1 Please run setup_essentials.sh first, then rerun this script."
    exit 1
fi

# Select source folder
echo -e "\nSelect the backup folder to install from:"
CONFIG_SUBFOLDERS=("PC" "Notebook" "Timestamped backup (from config_backups/)")
PS3="choose > "
select folder in "${CONFIG_SUBFOLDERS[@]}"; do
    case "$REPLY" in
        1|2)
            INSTALL_SOURCE_FOLDER="$TARGET_DIR/$folder"
            break
            ;;
        3)
            echo -e "\nAvailable timestamped backups:"
            BACKUP_FOLDERS=($(ls -1 "$BACKUP_DIR" 2>/dev/null | sort -r))
            if [[ ${#BACKUP_FOLDERS[@]} -eq 0 ]]; then
                echo "\u274c No timestamped backups found in $BACKUP_DIR"
                exit 1
            fi
            select backup in "${BACKUP_FOLDERS[@]}"; do
                if [[ -n "$backup" ]]; then
                    RAW_BACKUP_PATH="$BACKUP_DIR/$backup"
                    TEMP_INSTALL_FOLDER="${PROJECT_ROOT}/_temp_install"
                    mkdir -p "$TEMP_INSTALL_FOLDER"
                    rm -f "$TEMP_INSTALL_FOLDER"/*

                    echo "\u23f3 Converting raw backup files to .txt format..."
                    for FILE in "${!RESTORE_PATHS[@]}"; do
                        SRC="$RAW_BACKUP_PATH/$(basename "${RESTORE_PATHS[$FILE]}")"
                        DEST="$TEMP_INSTALL_FOLDER/${FILE}.txt"
                        [[ -f "$SRC" ]] && cp "$SRC" "$DEST"
                    done

                    INSTALL_SOURCE_FOLDER="$TEMP_INSTALL_FOLDER"
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

echo "\ud83d\udcc2 Using folder: $INSTALL_SOURCE_FOLDER"

# Ask for installation mode
echo -e "\nSelect installation mode:"
echo "1) Complete - Install all available configurations"
echo "2) Selective - Choose which configurations to install"
read -p "Enter your choice (1 or 2): " INSTALL_MODE

case "$INSTALL_MODE" in
    1) INSTALL_TYPE="complete"; echo "Selected: Complete installation" ;;
    2) INSTALL_TYPE="selective"; echo "Selected: Selective installation" ;;
    *) echo "Invalid selection. Defaulting to complete installation."; INSTALL_TYPE="complete" ;;
esac

AVAILABLE_CONFIGS=0
for FILE in "${!RESTORE_PATHS[@]}"; do
  SRC="${INSTALL_SOURCE_FOLDER}/${FILE}.txt"
  [[ -f "$SRC" ]] && AVAILABLE_CONFIGS=$((AVAILABLE_CONFIGS + 1))
done

if [[ $AVAILABLE_CONFIGS -eq 0 ]]; then
  echo "\u274c Error: No configuration files found in $INSTALL_SOURCE_FOLDER"
  exit 1
fi

read -p "This will install $AVAILABLE_CONFIGS configuration files. Continue? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Generate timestamp and backup directory
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TIMED_BACKUP_DIR="${BACKUP_DIR}/backup_${TIMESTAMP}"
mkdir -p "$TIMED_BACKUP_DIR"
echo -e "\n\ud83d\udcc1 Backup directory: $TIMED_BACKUP_DIR"

files_installed=0
files_backed_up=0
files_missing=0
files_skipped=0

echo -e "\nStarting installation process..."
echo "Files to process: $AVAILABLE_CONFIGS"
echo "-----------------------------------"

for FILE in "${!RESTORE_PATHS[@]}"; do
  SRC="${INSTALL_SOURCE_FOLDER}/${FILE}.txt"
  DEST="${RESTORE_PATHS[$FILE]}"

  if [[ ! -f "$SRC" ]]; then
    files_missing=$((files_missing + 1))
    continue
  fi

  echo "Processing: ${FILE}.txt -> $DEST"

  if [[ "$INSTALL_TYPE" == "selective" ]]; then
    read -p "Install $FILE to $DEST? (y/n): " SELECT_FILE
    if [[ ! "$SELECT_FILE" =~ ^[Yy]$ ]]; then
        echo "\u23ed\ufe0f Skipped: $FILE"
        files_skipped=$((files_skipped + 1))
        echo "-----------------------------------"
        continue
    fi
  fi

  mkdir -p "$(dirname "$DEST")" 2>/dev/null || {
    echo "\u26a0\ufe0f Failed to create directory: $(dirname "$DEST")"
    echo "-----------------------------------"
    continue
  }

  if [[ -f "$DEST" ]]; then
    cp "$DEST" "$TIMED_BACKUP_DIR/$(basename "$DEST")" 2>/dev/null && {
      echo "\ud83d\udd04 Backup of $(basename "$DEST") saved to $TIMED_BACKUP_DIR"
      files_backed_up=$((files_backed_up + 1))
    }
  fi

  if [[ "$DEST" == /etc/* ]]; then
    echo "\ud83d\udd27 Installing (sudo): ${FILE}.txt -> $DEST"
    sudo cp -f "$SRC" "$DEST" 2>/dev/null
    RESULT=$?
  else
    echo "\ud83d\udcc1 Installing: ${FILE}.txt -> $DEST"
    cp -f "$SRC" "$DEST" 2>/dev/null
    RESULT=$?
  fi

  if [[ $RESULT -eq 0 ]]; then
    echo "\u2705 Installed: $DEST"
    files_installed=$((files_installed + 1))
  else
    echo "\u26a0\ufe0f Failed to install: $DEST"
    files_skipped=$((files_skipped + 1))
  fi
  echo "-----------------------------------"
done

# Summary
echo -e "\n========== INSTALLATION SUMMARY =========="
echo "\ud83d\udcca Statistics:"
echo "   - Files installed: $files_installed"
echo "   - Files backed up: $files_backed_up"
echo "   - Files skipped: $files_skipped"
echo "   - Files missing: $files_missing"
echo -e "\n\ud83d\udcc0 Installed from: $INSTALL_SOURCE_FOLDER"
echo "\ud83d\udee1\ufe0f  Backups saved to: $TIMED_BACKUP_DIR"

# GRUB
echo -e "\nChecking GRUB config..."
if [[ -f "/etc/default/grub" && -f "${INSTALL_SOURCE_FOLDER}/grub.txt" ]]; then
  echo -e "\nGRUB configuration was updated."
  read -p "Do you want to regenerate GRUB config now? (y/n): " REPLY
  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    echo "\ud83d\udd04 Updating GRUB config..."
    if sudo grub-mkconfig -o /boot/grub/grub.cfg; then
      echo "\u2705 GRUB config regenerated successfully."
    else
      echo "\u26a0\ufe0f GRUB update failed, but other configs were installed successfully."
    fi
  else
    echo "\u23ed\ufe0f Skipped GRUB regeneration."
    echo "Remember to run 'sudo grub-mkconfig -o /boot/grub/grub.cfg' manually."
  fi
fi

echo -e "\n\u2705 Installation complete!"
exit 0
