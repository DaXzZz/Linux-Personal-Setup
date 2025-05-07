#!/bin/bash

# Load project paths and config definitions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
clear

echo -e "\n========== ARCH HYPRLAND CONFIGURATION BACKUP =========="
echo "This utility will back up your current config files into text format."
echo "===========================================================\n"

# ========== Choose overwrite behavior ==========
echo -e "🛡️  How do you want to handle existing .txt files?"
echo "1) Overwrite all without asking"
echo "2) Ask before each overwrite"
read -p "choose > " OVERWRITE_MODE
case "$OVERWRITE_MODE" in
    1) FORCE_OVERWRITE=true ;;
    *) FORCE_OVERWRITE=false ;;
esac

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

# ========== Backup: UserSettings Only ==========
if [[ -n "$USERSETTINGS_DEST" ]]; then
    echo -e "\n📤 Starting backup process (UserSettings)..."
    FILE="UserSettings.conf"
    SOURCE="${RESTORE_PATHS[$FILE]}"
    DEST_FOLDER="$USERSETTINGS_DEST"
    DEST_PATH="${DEST_FOLDER}/${FILE}.txt"

    if [[ ! -f "$SOURCE" ]]; then
        echo "❌ File not found: $SOURCE"
        files_missing=$((files_missing + 1))
        missing_files+=("$FILE ← $SOURCE")
    else
        mkdir -p "$DEST_FOLDER"
        if [[ -f "$DEST_PATH" && "$FORCE_OVERWRITE" == false ]]; then
            read -p "⚠️  $FILE.txt already exists. Overwrite? (y/n): " OVERWRITE
            if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
                echo "⏭️  Skipped: $FILE"
                files_skipped=$((files_skipped + 1))
                skipped_files+=("$FILE → $DEST_PATH")
            else
                cp -f "$SOURCE" "$DEST_PATH"
                echo "✅ Saved: $DEST_PATH"
                files_exported=$((files_exported + 1))
            fi
        else
            cp -f "$SOURCE" "$DEST_PATH"
            echo "✅ Saved: $DEST_PATH"
            files_exported=$((files_exported + 1))
        fi
    fi
fi

# ========== Backup: All Other Files ==========
echo -e "\n📤 Starting backup process (Main)..."
for FILE in "${!RESTORE_PATHS[@]}"; do
    [[ "$FILE" == "UserSettings.conf" ]] && continue

    SOURCE="${RESTORE_PATHS[$FILE]}"
    DEST_FOLDER="$INSTALL_SOURCE_MAIN"
    DEST_PATH="${DEST_FOLDER}/${FILE}.txt"

    if [[ ! -f "$SOURCE" ]]; then
        echo "❌ File not found: $SOURCE"
        files_missing=$((files_missing + 1))
        missing_files+=("$FILE ← $SOURCE")
        continue
    fi

    mkdir -p "$DEST_FOLDER"
    if [[ -f "$DEST_PATH" && "$FORCE_OVERWRITE" == false ]]; then
        read -p "⚠️  $FILE.txt already exists. Overwrite? (y/n): " OVERWRITE
        if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
            echo "⏭️  Skipped: $FILE"
            files_skipped=$((files_skipped + 1))
            skipped_files+=("$FILE → $DEST_PATH")
            continue
        fi
    fi

    cp -f "$SOURCE" "$DEST_PATH"
    echo "✅ Saved: $DEST_PATH"
    files_exported=$((files_exported + 1))
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
