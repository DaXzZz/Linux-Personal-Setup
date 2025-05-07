#!/bin/bash

set -euo pipefail

# ========== Project Structure ==========
PROJECT_ROOT="${HOME}/Linux-Personal-Setup"

# Main directories used in the project
TARGET_DIR="${PROJECT_ROOT}/config"            # Stores config files categorized by device (e.g. PC, Notebook, Main)
SCRIPTS_DIR="${PROJECT_ROOT}/scripts"          # Stores utility scripts
BACKUP_DIR="${PROJECT_ROOT}/backup"            # Stores manual/user-confirmed backup copies

# Where main config .txt files (to install) are loaded from
INSTALL_SOURCE_MAIN="${TARGET_DIR}/Main"

# Filename used only for UserSettings config
USERSETTINGS_FILENAME="UserSettings.conf.txt"

# ========== File Paths to Manage ==========
# These are the actual target locations on the system where configs should be restored to
declare -A RESTORE_PATHS=(
  [zshrc]="${HOME}/.zshrc"
  [starship.toml]="${HOME}/.config/starship.toml"
  [kitty.conf]="${HOME}/.config/kitty/kitty.conf"
  [config-daxz.jsonc]="${HOME}/.config/fastfetch/config-daxz.jsonc"
  [WindowRules.conf]="${HOME}/.config/hypr/UserConfigs/WindowRules.conf"
  [Startup_Apps.conf]="${HOME}/.config/hypr/UserConfigs/Startup_Apps.conf"
  [UserSettings.conf]="${HOME}/.config/hypr/UserConfigs/UserSettings.conf"
  [UserDecorations.conf]="${HOME}/.config/hypr/UserConfigs/UserDecorations.conf"
)

# Create required directories if they don't exist
for dir in "$TARGET_DIR" "$SCRIPTS_DIR" "$BACKUP_DIR"; do
    mkdir -p "$dir"
done
