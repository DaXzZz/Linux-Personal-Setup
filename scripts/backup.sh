#!/bin/bash

# Load project paths and config definitions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
clear

echo -e "\n========== ARCH HYPRLAND CONFIGURATION BACKUP =========="
echo "This utility will back up your current config files into text format."
echo "==========================================================="

# ========== Choose target folder for UserSettings ==========
USERSETTINGS_DEST=""
mapfile -t AVAILABLE_FOLDERS < <(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d -not -name "Main" -exec basename {} \;)
if [[ -n "${AVAILABLE_FOLDERS[*]}" ]]; then
    echo -e "\n📌 Choose destination folder for UserSettings.conf.txt:"
    PS3="choose > "
    select folder in "${AVAILABLE_FOLDERS[@]}"; do
        if [[ -n "$folder" ]]; then
            USERSETTINGS_DEST="${TARGET_DIR}/$folder"
            break
        else
            echo "Invalid selection. Try again."
        fi
    done
fi

# ========== Initialize counters and lists ==========
files_exported=0
files_skipped=0
files_missing=0
skipped_files=()
missing_files=()

echo -e "\n🗂️  Starting backup process..."
echo "-----------------------------------"

# ========== Main backup loop ==========
for FILE in "${!RESTORE_PATHS[@]}"; do
    SOURCE="${RESTORE_PATHS[$FILE]}"
    DEST_FOLDER="$INSTALL_SOURCE_MAIN"
    DEST_FILENAME="${FILE}.txt"

    # Special case for UserSettings: use user-selected folder
    if [[ "$FILE" == "UserSettings.conf" && -n "$USERSETTINGS_DEST" ]]; then
        DEST_FOLDER="$USERSETTINGS_DEST"
    fi

    DEST_PATH="${DEST_FOLDER}/${DEST_FILENAME}"

    if [[ ! -f "$SOURCE" ]]; then
        echo "❌ File not found: $SOURCE"
        files_missing=$((files_missing + 1))
        missing_files+=("$FILE ← $SOURCE")
        continue
    fi

    echo "📤 Exporting: $SOURCE → $DEST_PATH"

    if [[ -f "$DEST_PATH" ]]; then
        read -p "⚠️  $DEST_FILENAME already exists. Overwrite? (y/n): " OVERWRITE
        if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
            echo "⏭️  Skipped: $DEST_FILENAME"
            files_skipped=$((files_skipped + 1))
            skipped_files+=("$FILE → $DEST_PATH")
            echo "-----------------------------------"
            continue
        fi
    fi

    mkdir -p "$DEST_FOLDER"
    cp -f "$SOURCE" "$DEST_PATH" && {
        echo "✅ Saved: $DEST_PATH"
        files_exported=$((files_exported + 1))
    }

    echo "-----------------------------------"
done

# ========== Summary ==========
echo -e "\n🧾 \033[1mBACKUP SUMMARY\033[0m"
echo "────────────────────────────────────────────"
printf "✅ %-20s : %d\n" "Files exported" "$files_exported"
printf "⏭️  %-20s : %d\n" "Files skipped" "$files_skipped"
printf "❌ %-20s : %d\n" "Files missing" "$files_missing"
echo "────────────────────────────────────────────"
echo "📂 Main backup folder      : $INSTALL_SOURCE_MAIN"
[[ -n "$USERSETTINGS_DEST" ]] && echo "📂 UserSettings saved into : $USERSETTINGS_DEST"

if (( files_skipped > 0 )); then
    echo -e "\n⏭️ \033[1mSkipped Files:\033[0m"
    for f in "${skipped_files[@]}"; do
        echo "   • $f"
    done
fi

if (( files_missing > 0 )); then
    echo -e "\n❌ \033[1mMissing Files (not found in system):\033[0m"
    for f in "${missing_files[@]}"; do
        echo "   • $f"
    done
fi

echo -e "\n✅ \033[1mBackup complete!\033[0m"
exit 0
