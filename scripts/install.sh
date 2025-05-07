#!/bin/bash

# Load project paths and config definitions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
clear

# ================= Welcome Banner =================
echo -e "\n========== ARCH HYPRLAND CONFIGURATION INSTALLER =========="
echo "This utility will install your saved configurations from a backup folder."
echo "=============================================================="

# ========== Ensure prerequisites ==========
echo -e "\n⚠️  RECOMMENDED: Run 'setup_essentials.sh' before continuing."
read -p "Have you already run setup_essentials.sh on this system? (y/n): " confirm_essentials
if [[ ! "$confirm_essentials" =~ ^[Yy]$ ]]; then
    echo "🛑 Please run setup_essentials.sh first, then rerun this script."
    exit 1
fi

# ========== Ask user to choose source folder for UserSettings ==========
USERSETTINGS_FOLDER=""
mapfile -t AVAILABLE_FOLDERS < <(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d -not -name "Main" -exec basename {} \;)
if [[ -n "${AVAILABLE_FOLDERS[*]}" ]]; then
    echo -e "\n📌 Choose source folder for UserSettings.conf.txt:"
    PS3="choose > "
    select folder in "${AVAILABLE_FOLDERS[@]}"; do
        if [[ -n "$folder" ]]; then
            USERSETTINGS_FOLDER="${TARGET_DIR}/$folder"
            break
        else
            echo "Invalid selection. Try again."
        fi
    done
fi

# ========== Display source paths ==========
echo "📂 Using source folders:"
echo "- Main configs: $INSTALL_SOURCE_MAIN"
[[ -n "$USERSETTINGS_FOLDER" ]] && echo "- UserSettings.conf.txt: $USERSETTINGS_FOLDER"

# ========== Choose installation mode ==========
echo -e "\nSelect installation mode:"
echo "1) Complete - Install all available configurations"
echo "2) Selective - Choose which configurations to install"
read -p "Enter your choice (1 or 2): " INSTALL_MODE

case "$INSTALL_MODE" in
    1) INSTALL_TYPE="complete"; echo "Selected: Complete installation" ;;
    2) INSTALL_TYPE="selective"; echo "Selected: Selective installation" ;;
    *) echo "Invalid selection. Defaulting to complete installation."; INSTALL_TYPE="complete" ;;
esac

# ========== Count available config files ==========
AVAILABLE_CONFIGS=0
for FILE in "${!RESTORE_PATHS[@]}"; do
    if [[ "$FILE" == "UserSettings.conf" && -n "$USERSETTINGS_FOLDER" ]]; then
        [[ -f "$USERSETTINGS_FOLDER/$USERSETTINGS_FILENAME" ]] && AVAILABLE_CONFIGS=$((AVAILABLE_CONFIGS + 1))
    else
        [[ -f "$INSTALL_SOURCE_MAIN/${FILE}.txt" ]] && AVAILABLE_CONFIGS=$((AVAILABLE_CONFIGS + 1))
    fi
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

# ========== Ask user if they want to back up existing files ==========
read -p "📦 Do you want to back up existing files before installing? (y/n): " DO_BACKUP
if [[ "$DO_BACKUP" =~ ^[Yy]$ ]]; then
    BACKUP_NAME="Backup-$(date +'%d-%b-%y(%H\H_%MM)')"
    TIMED_BACKUP_DIR="${BACKUP_DIR}/${BACKUP_NAME}"
    mkdir -p "$TIMED_BACKUP_DIR"
    echo -e "\n📁 Backup directory: $TIMED_BACKUP_DIR"
else
    TIMED_BACKUP_DIR=""
    echo -e "\n📁 Skipping backup."
fi

# ========== Initialize tracking counters ==========
files_installed=0
files_backed_up=0
files_missing=0
files_skipped=0
skipped_files=()
missing_files=()

echo -e "\n🚀 Starting installation process..."
echo "Files to process: $AVAILABLE_CONFIGS"
echo "-----------------------------------"

# ========== Main installation loop ==========
for FILE in "${!RESTORE_PATHS[@]}"; do
    DEST="${RESTORE_PATHS[$FILE]}"
    SRC=""

    # Determine where to load the config from
    if [[ "$FILE" == "UserSettings.conf" && -n "$USERSETTINGS_FOLDER" ]]; then
        SRC="$USERSETTINGS_FOLDER/$USERSETTINGS_FILENAME"
    else
        SRC="$INSTALL_SOURCE_MAIN/${FILE}.txt"
    fi

    if [[ ! -f "$SRC" ]]; then
        echo "❌ File not found: $SRC"
        files_missing=$((files_missing + 1))
        missing_files+=("$FILE → $SRC")
        continue
    fi

    echo "Processing: $(basename "$SRC") → $DEST"

    # ========== Ask for confirmation (if in selective mode) ==========
    if [[ "$INSTALL_TYPE" == "selective" ]]; then
        read -p "Install $FILE to $DEST? (y/n): " SELECT_FILE
        if [[ ! "$SELECT_FILE" =~ ^[Yy]$ ]]; then
            echo "⏭️ Skipped: $FILE"
            files_skipped=$((files_skipped + 1))
            skipped_files+=("$FILE → $DEST")
            echo "-----------------------------------"
            continue
        fi
    fi

    # ========== Ensure destination directory exists ==========
    mkdir -p "$(dirname "$DEST")" 2>/dev/null || {
        echo "⚠️ Failed to create directory: $(dirname "$DEST")"
        echo "-----------------------------------"
        continue
    }

    # ========== Backup if enabled ==========
    if [[ -n "$TIMED_BACKUP_DIR" && -f "$DEST" ]]; then
        cp "$DEST" "$TIMED_BACKUP_DIR/$(basename "$DEST")" 2>/dev/null && {
            echo "🔄 Backup of $(basename "$DEST") saved to $TIMED_BACKUP_DIR"
            files_backed_up=$((files_backed_up + 1))
        }
    fi

    # ========== Install the file ==========
    if [[ "$DEST" == /etc/* ]]; then
        echo "🔧 Installing (sudo): $(basename "$SRC") → $DEST"
        sudo cp -f "$SRC" "$DEST" 2>/dev/null
        RESULT=$?
    else
        echo "📁 Installing: $(basename "$SRC") → $DEST"
        cp -f "$SRC" "$DEST" 2>/dev/null
        RESULT=$?
    fi

    # ========== Track result ==========
    if [[ $RESULT -eq 0 ]]; then
        echo "✅ Installed: $DEST"
        files_installed=$((files_installed + 1))
    else
        echo "⚠️ Failed to install: $DEST"
        files_skipped=$((files_skipped + 1))
        skipped_files+=("$FILE → $DEST")
    fi

    echo "-----------------------------------"
done

# ========== Installation Summary ==========
echo -e "\n🧾 \033[1mINSTALLATION SUMMARY\033[0m"
echo "────────────────────────────────────────────"
printf "✅ %-20s : %d\n" "Files installed" "$files_installed"
printf "📦 %-20s : %d\n" "Files backed up" "$files_backed_up"
printf "⏭️ %-20s : %d\n" "Files skipped" "$files_skipped"
printf "❌ %-20s : %d\n" "Files missing" "$files_missing"
echo "────────────────────────────────────────────"
echo "📂 Source config folder : $INSTALL_SOURCE_MAIN"
[[ -n "$TIMED_BACKUP_DIR" ]] && echo "🛡️ Backup saved at      : $TIMED_BACKUP_DIR"

if (( files_skipped > 0 )); then
    echo -e "\n⏭️ \033[1mSkipped Files:\033[0m"
    for f in "${skipped_files[@]}"; do
        echo "   • $f"
    done
fi

if (( files_missing > 0 )); then
    echo -e "\n❌ \033[1mMissing Files (not found in source):\033[0m"
    for f in "${missing_files[@]}"; do
        echo "   • $f"
    done
fi

echo -e "\n✅ \033[1mInstallation complete!\033[0m"
exit 0
