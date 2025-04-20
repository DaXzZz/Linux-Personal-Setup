#!/bin/bash
#
# CONFIGURATION FILE
# ==================
# PURPOSE: Defines config paths to back up and manages them interactively

# Strict mode
set -euo pipefail

# Validate environment
if [[ -z "${HOME:-}" ]]; then
    echo "❌ Error: HOME environment variable is not set"
    exit 1
fi

# Base project directory
PROJECT_ROOT="${HOME}/Arch-Hyprland-Config"

# Directory paths
TARGET_DIR="${PROJECT_ROOT}/config"
SCRIPTS_DIR="${PROJECT_ROOT}/scripts"
BACKUP_DIR="${PROJECT_ROOT}/config_backups"

# Ensure directories exist
for dir in "$TARGET_DIR" "$SCRIPTS_DIR" "$BACKUP_DIR"; do
    mkdir -p "$dir"
done

# Files to manage
FILES_TO_MANAGE=(
  "/etc/default/grub"
  "${HOME}/.zshrc"
  "${HOME}/.config/kitty/kitty.conf"
  "${HOME}/.config/starship.toml"
  "${HOME}/.config/hypr/UserConfigs/WindowRules.conf"
  "${HOME}/.config/hypr/UserConfigs/Startup_Apps.conf"
  "${HOME}/.config/hypr/UserConfigs/UserSettings.conf"
)

# Interactive menu for managing FILES_TO_MANAGE
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    CONFIG_FILE="$0"
    clear
    echo -e "\n========== ARCH-HYPRLAND CONFIG MANAGER =========="

    while true; do
        echo -e "\nSelect an option:"
        echo "1) 📄 List current FILES_TO_MANAGE"
        echo "2) ➕ Add a new file path"
        echo "3) ❌ Delete a file path"
        echo "4) 🚪 Exit"
        read -p "Enter your choice [1-4]: " choice

        case "$choice" in
            1)
                echo -e "\n🗂️  Current FILES_TO_MANAGE:"
                index=1
                for path in "${FILES_TO_MANAGE[@]}"; do
                    status="[❌ missing]"
                    [[ -f "$path" ]] && status="[✅ exists]"
                    echo " $index) $path $status"
                    ((index++))
                done
                ;;
            2)
                read -p "Enter full file path to add: " new_path
                if [[ -z "$new_path" ]]; then
                    echo "⚠️  No path entered."
                elif printf '%s\n' "${FILES_TO_MANAGE[@]}" | grep -Fxq "$new_path"; then
                    echo "⚠️  Path already exists in the list."
                else
                    sed -i "/^FILES_TO_MANAGE=(/a\  \"$new_path\"" "$CONFIG_FILE"
                    echo "✅ Added: $new_path"
                    source "$CONFIG_FILE"
                fi
                ;;
            3)
                echo -e "\nSelect a path to delete:"
                select del_path in "${FILES_TO_MANAGE[@]}" "Cancel"; do
                    if [[ "$REPLY" -ge 1 && "$REPLY" -le "${#FILES_TO_MANAGE[@]}" ]]; then
                        sed -i "\|[[:space:]]\"${FILES_TO_MANAGE[$((REPLY-1))]}\"|d" "$CONFIG_FILE"
                        echo "🗑️  Deleted: ${FILES_TO_MANAGE[$((REPLY-1))]}"
                        source "$CONFIG_FILE"
                        break
                    elif [[ "$REPLY" == "$(( ${#FILES_TO_MANAGE[@]} + 1 ))" ]]; then
                        echo "❎ Cancelled"
                        break
                    else
                        echo "❌ Invalid selection"
                    fi
                done
                ;;
            4)
                echo "👋 Exiting."
                exit 0
                ;;
            *)
                echo "❌ Invalid choice"
                ;;
        esac
    done
fi
