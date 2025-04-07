#!/bin/bash
#
# CONFIGURATION FILE
# =================
# PURPOSE: Core settings file for the Arch-Hyprland configuration system
#
# WHAT IT CONTAINS:
# - Project directories and paths used by all scripts
# - List of configuration files to manage (FILES_TO_MANAGE array)
# - Mapping between backed-up files and system locations
# - Configuration validation functions
#
# HOW IT'S USED:
# - Sourced by other scripts (backup.sh, install.sh, restore.sh)
# - Can be run with --validate to check configuration integrity
#

# Display message if run directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    clear
    echo -e "\n========== ARCH HYPRLAND CONFIGURATION SYSTEM =========="
    echo "This is a configuration file that defines paths and settings"
    echo "for the backup, install, and restore scripts."
    echo ""
    echo "Available options:"
    echo "  --validate     Check configuration for consistency"
    echo "  --list         List all managed configuration files"
    echo "  --edit         Open this file in your default editor"
    echo "  --help         Show this help message"
    echo "==========================================================="
    
    # Process command line options
    case "${1:-}" in
        "--validate")
            echo -e "\nValidating configuration..."
            VALIDATE_MODE=true
            ;;
        "--list")
            echo -e "\nListing managed configuration files:"
            if [[ -z "${HOME:-}" ]]; then
                echo "❌ Error: HOME environment variable is not set"
                exit 1
            fi
            PROJECT_ROOT="${HOME}/Arch-Hyprland-Config"
            source <(grep -A50 "FILES_TO_MANAGE=" "$0")
            for file in "${FILES_TO_MANAGE[@]}"; do
                if [[ -f "$file" ]]; then
                    echo "✓ $file (exists)"
                else
                    echo "⚠️ $file (missing)"
                fi
            done
            exit 0
            ;;
        "--edit")
            ${EDITOR:-nano} "$0"
            exit 0
            ;;
        "--help"|*)
            # Already showed help above
            exit 0
            ;;
    esac
fi

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
    echo "⚠️  Creating project directory now..."
    mkdir -p "$PROJECT_ROOT"
    if [[ $? -ne 0 ]]; then
        echo "❌ Error: Failed to create project directory"
        exit 1
    else
        echo "✅ Project directory created"
    fi
fi

# Paths used across scripts
TARGET_DIR="${PROJECT_ROOT}/config"         # 📁 Directory for storing config files (used in install.sh)
SCRIPTS_DIR="${PROJECT_ROOT}/scripts"       # ⚙️  Directory for script files like backup.sh, install.sh, restore.sh
BACKUP_DIR="${PROJECT_ROOT}/config_backups" # 🛡️  Directory for backup files (before being overwritten)

# Create directories if they don't exist
for dir in "${TARGET_DIR}" "${BACKUP_DIR}" "${SCRIPTS_DIR}"; do
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        echo "📁 Created directory: $dir"
    fi
done

# Timestamped backup directory
HOSTNAME=$(hostname | cut -d'.' -f1)
TIMESTAMP=$(date +"%d-%b-%Y_%I.%M%p")  # e.g., 07-Apr-2025_09.30AM
TIMED_BACKUP_DIR="${BACKUP_DIR}/${HOSTNAME}_${TIMESTAMP}"

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
    local missing_files=0
    
    echo "🔍 Checking configuration integrity..."
    
    # Check that all RESTORE_PATHS entries are in FILES_TO_MANAGE
    for file_path in "${RESTORE_PATHS[@]}"; do
        if ! printf '%s\n' "${FILES_TO_MANAGE[@]}" | grep -q "^${file_path}$"; then
            echo "⚠️  Warning: Path '${file_path}' in RESTORE_PATHS is not in FILES_TO_MANAGE"
            issues_found=1
        fi
    done
    
    # Check which files exist on the system
    for file in "${FILES_TO_MANAGE[@]}"; do
        if [[ ! -f "$file" ]]; then
            echo "⚠️  Warning: Managed file '$file' does not exist on this system"
            missing_files=$((missing_files + 1))
        fi
    done
    
    if [[ $missing_files -gt 0 ]]; then
        echo "⚠️  $missing_files managed files are missing from your system"
    fi
    
    if [[ $issues_found -eq 1 ]]; then
        echo "⚠️  Config validation found issues that may cause problems"
    else
        echo "✅ Config validation passed"
    fi
}

# Run validation in verbose mode if requested
if [[ "${VALIDATE_MODE:-false}" == "true" || "${1:-}" == "--validate" ]]; then
    validate_config
fi