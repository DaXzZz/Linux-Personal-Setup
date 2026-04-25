#!/bin/bash
set -euo pipefail

# ==================================================
# 📁 PROJECT STRUCTURE
# ==================================================
PROJECT_ROOT="${HOME}/Linux-Personal-Setup"

TARGET_DIR="${PROJECT_ROOT}/config"
SCRIPTS_DIR="${PROJECT_ROOT}/scripts"
BACKUP_DIR="${PROJECT_ROOT}/backup"

INSTALL_SOURCE_MAIN="${TARGET_DIR}/Main"

SYSTEM_SETTINGS_FILENAME="SystemSettings.conf.txt"


# ==================================================
# 📦 RESTORE TARGET PATHS
# ==================================================
# Mapping: [source filename] -> [destination path]

declare -A RESTORE_PATHS=(
  # Shell
  [zshrc]="${HOME}/.zshrc"

  # Terminal
  [kitty.conf]="${HOME}/.config/kitty/kitty.conf"

  # Prompt
  [EDM115-newline.omp.json]="${HOME}/.config/ohmyposh/EDM115-newline.omp.json"

  # Hyprland
  [SystemSettings.conf]="${HOME}/.config/hypr/configs/SystemSettings.conf"
  [UserDecorations.conf]="${HOME}/.config/hypr/UserConfigs/UserDecorations.conf"
)


# ==================================================
# 🛠️ INITIAL SETUP
# ==================================================

for dir in "$TARGET_DIR" "$SCRIPTS_DIR" "$BACKUP_DIR"; do
    mkdir -p "$dir"
done