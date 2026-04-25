#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
clear

echo -e "\n========== ARCH HYPRLAND CONFIGURATION INSTALLER =========="
echo "This utility installs saved configurations from your project config folder."
echo "============================================================"

echo -e "\n⚠️  RECOMMENDED: Run 'setup_essentials.sh' before continuing."
read -r -p "Have you already run setup_essentials.sh on this system? (y/n): " confirm_essentials

if [[ ! "$confirm_essentials" =~ ^[Yy]$ ]]; then
    echo "🛑 Please run setup_essentials.sh first, then rerun this script."
    exit 1
fi

SYSTEMSETTINGS_FOLDER=""

mapfile -t AVAILABLE_FOLDERS < <(
    find "$TARGET_DIR" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        -not -name "Main" \
        -exec basename {} \;
)

if [[ ${#AVAILABLE_FOLDERS[@]} -gt 0 ]]; then
    echo -e "\n📌 Choose source folder for SystemSettings.conf.txt:"
    PS3="choose > "

    select folder in "${AVAILABLE_FOLDERS[@]}"; do
        if [[ -n "${folder:-}" ]]; then
            SYSTEMSETTINGS_FOLDER="${TARGET_DIR}/$folder"
            break
        else
            echo "Invalid selection. Try again."
        fi
    done
fi

echo
echo "📂 Using source folders:"
echo "- Main configs: $INSTALL_SOURCE_MAIN"
[[ -n "$SYSTEMSETTINGS_FOLDER" ]] && echo "- SystemSettings.conf.txt: $SYSTEMSETTINGS_FOLDER"

echo -e "\nSelect installation mode:"
echo "1) Complete - Install all available configurations"
echo "2) Selective - Choose which configurations to install"
read -r -p "Enter your choice (1 or 2): " INSTALL_MODE

case "$INSTALL_MODE" in
    1)
        INSTALL_TYPE="complete"
        echo "Selected: Complete installation"
        ;;
    2)
        INSTALL_TYPE="selective"
        echo "Selected: Selective installation"
        ;;
    *)
        INSTALL_TYPE="complete"
        echo "Invalid selection. Defaulting to complete installation."
        ;;
esac

get_source_path() {
    local file="$1"

    if [[ "$file" == "SystemSettings.conf" && -n "$SYSTEMSETTINGS_FOLDER" ]]; then
        echo "$SYSTEMSETTINGS_FOLDER/$SYSTEM_SETTINGS_FILENAME"
    else
        echo "$INSTALL_SOURCE_MAIN/${file}.txt"
    fi
}

AVAILABLE_CONFIGS=0

for FILE in "${!RESTORE_PATHS[@]}"; do
    SRC="$(get_source_path "$FILE")"
    [[ -f "$SRC" ]] && AVAILABLE_CONFIGS=$((AVAILABLE_CONFIGS + 1))
done

if [[ $AVAILABLE_CONFIGS -eq 0 ]]; then
    echo "❌ No configuration files found."
    exit 1
fi

read -r -p "This will install $AVAILABLE_CONFIGS configuration files. Continue? (y/n): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

read -r -p "📦 Do you want to back up existing files before installing? (y/n): " DO_BACKUP

if [[ "$DO_BACKUP" =~ ^[Yy]$ ]]; then
    BACKUP_NAME="Backup-$(date +'%d-%b-%y(%Hh_%Mm)')"
    TIMED_BACKUP_DIR="${BACKUP_DIR}/${BACKUP_NAME}"
    mkdir -p "$TIMED_BACKUP_DIR"
    echo -e "\n📁 Backup directory: $TIMED_BACKUP_DIR"
else
    TIMED_BACKUP_DIR=""
    echo -e "\n📁 Skipping backup."
fi

files_installed=0
files_backed_up=0
files_missing=0
files_skipped=0

skipped_files=()
missing_files=()

echo -e "\n🚀 Starting installation process..."
echo "Files to process: $AVAILABLE_CONFIGS"
echo "-----------------------------------"

for FILE in "${!RESTORE_PATHS[@]}"; do
    DEST="${RESTORE_PATHS[$FILE]}"
    SRC="$(get_source_path "$FILE")"

    if [[ ! -f "$SRC" ]]; then
        echo "❌ File not found: $SRC"
        files_missing=$((files_missing + 1))
        missing_files+=("$FILE → $SRC")
        continue
    fi

    echo "Processing: $(basename "$SRC") → $DEST"

    if [[ "$INSTALL_TYPE" == "selective" ]]; then
        read -r -p "Install $FILE to $DEST? (y/n): " SELECT_FILE

        if [[ ! "$SELECT_FILE" =~ ^[Yy]$ ]]; then
            echo "⏭️ Skipped: $FILE"
            files_skipped=$((files_skipped + 1))
            skipped_files+=("$FILE → $DEST")
            echo "-----------------------------------"
            continue
        fi
    fi

    mkdir -p "$(dirname "$DEST")" 2>/dev/null || {
        echo "⚠️ Failed to create directory: $(dirname "$DEST")"
        files_skipped=$((files_skipped + 1))
        skipped_files+=("$FILE → $DEST")
        echo "-----------------------------------"
        continue
    }

    if [[ -n "$TIMED_BACKUP_DIR" && -f "$DEST" ]]; then
        cp "$DEST" "$TIMED_BACKUP_DIR/$(basename "$DEST")" 2>/dev/null && {
            echo "🔄 Backup of $(basename "$DEST") saved to $TIMED_BACKUP_DIR"
            files_backed_up=$((files_backed_up + 1))
        }
    fi

    if [[ "$DEST" == /etc/* ]]; then
        echo "🔧 Installing with sudo: $(basename "$SRC") → $DEST"
        sudo cp -f "$SRC" "$DEST"
    else
        echo "📁 Installing: $(basename "$SRC") → $DEST"
        cp -f "$SRC" "$DEST"
    fi

    echo "✅ Installed: $DEST"
    files_installed=$((files_installed + 1))
    echo "-----------------------------------"
done

echo -e "\n🧾 \033[1mINSTALLATION SUMMARY\033[0m"
echo "────────────────────────────────────────────"
printf "✅ %-20s : %d\n" "Files installed" "$files_installed"
printf "📦 %-20s : %d\n" "Files backed up" "$files_backed_up"
printf "⏭️ %-20s : %d\n" "Files skipped" "$files_skipped"
printf "❌ %-20s : %d\n" "Files missing" "$files_missing"
echo "────────────────────────────────────────────"
echo "📂 Source config folder : $INSTALL_SOURCE_MAIN"
[[ -n "$SYSTEMSETTINGS_FOLDER" ]] && echo "📂 SystemSettings folder: $SYSTEMSETTINGS_FOLDER"
[[ -n "$TIMED_BACKUP_DIR" ]] && echo "🛡️ Backup saved at      : $TIMED_BACKUP_DIR"

if (( files_skipped > 0 )); then
    echo -e "\n⏭️ \033[1mSkipped Files:\033[0m"
    for f in "${skipped_files[@]}"; do
        echo "   • $f"
    done
fi

if (( files_missing > 0 )); then
    echo -e "\n❌ \033[1mMissing Files:\033[0m"
    for f in "${missing_files[@]}"; do
        echo "   • $f"
    done
fi

echo -e "\n✅ \033[1mInstallation complete!\033[0m"
exit 0