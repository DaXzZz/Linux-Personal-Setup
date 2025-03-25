#!/bin/bash

# Add stricter error handling
set -euo pipefail

# Validate environment
if [[ -z "${HOME:-}" ]]; then
    echo "❌ Error: HOME environment variable is not set"
    exit 1
fi

# Base project directory - use absolute path with proper quoting
PROJECT_ROOT="${HOME}/Arch-Hyprland-Config"

# Validate project directory exists
if [[ ! -d "$PROJECT_ROOT" ]]; then
    echo "⚠️  Warning: Project directory does not exist at: ${PROJECT_ROOT}"
    echo "⚠️  Some operations may fail. Please check your installation."
fi

# Paths used across scripts
TARGET_DIR="${PROJECT_ROOT}/config"         # 📁  Storage of config files for installation (used in install.sh)
SCRIPTS_DIR="${PROJECT_ROOT}/scripts"       # ⚙️  Script file storage such as backup_config.sh, install.sh, restore.sh
BACKUP_DIR="${PROJECT_ROOT}/config_backups" # 🛡️  Used to store backup files (before they are overwritten).

# Create directories if they don't exist
mkdir -p "${TARGET_DIR}" "${BACKUP_DIR}" "${SCRIPTS_DIR}"

# Timestamped backup directory
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TIMED_BACKUP_DIR="${BACKUP_DIR}/original_${TIMESTAMP}"

# List of system files to manage (full paths)
FILES_TO_MANAGE=(
  "/etc/default/grub"
  "${HOME}/.zshrc"
  "${HOME}/.config/kitty/kitty.conf"
  "${HOME}/.config/starship.toml"
  "${HOME}/.config/hypr/UserConfigs/WindowRules.conf"
  "${HOME}/.config/hypr/UserConfigs/Startup_Apps.conf"
  "${HOME}/.config/hypr/UserConfigs/UserSettings.conf"
)

# Map plain names for matching in config/ and restore
# Use associative arrays in scripts like:
#   declare -A FILE_MAP
#   source path_config.sh && for file in "${!RESTORE_PATHS[@]}"; do ...
declare -A RESTORE_PATHS=(
  ["grub"]="/etc/default/grub"
  ["zshrc"]="${HOME}/.zshrc"
  ["kitty.conf"]="${HOME}/.config/kitty/kitty.conf"
  ["starship.toml"]="${HOME}/.config/starship.toml"
  ["WindowRules.conf"]="${HOME}/.config/hypr/UserConfigs/WindowRules.conf"
  ["Startup_Apps.conf"]="${HOME}/.config/hypr/UserConfigs/Startup_Apps.conf"
  ["UserSettings.conf"]="${HOME}/.config/hypr/UserConfigs/UserSettings.conf"
)

# Validate that all files in RESTORE_PATHS are in FILES_TO_MANAGE
validate_config() {
    local issues_found=0
    
    for file_path in "${RESTORE_PATHS[@]}"; do
        if ! printf '%s\n' "${FILES_TO_MANAGE[@]}" | grep -q "^${file_path}$"; then
            echo "⚠️  Warning: Path '${file_path}' in RESTORE_PATHS is not in FILES_TO_MANAGE"
            issues_found=1
        fi
    done
    
    if [[ $issues_found -eq 1 ]]; then
        echo "⚠️  Config validation found issues that may cause problems"
    else
        echo "✅ Config validation passed"
    fi
}

# Run validation in verbose mode if requested
if [[ "${1:-}" == "--validate" ]]; then
    validate_config
fi