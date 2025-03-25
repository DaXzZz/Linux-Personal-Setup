#!/bin/bash

# Shared paths for backup/restore/install scripts

# Base project directory
PROJECT_ROOT="$HOME/Arch-Hyprland-Config"

# Paths used across scripts
TARGET_DIR="$PROJECT_ROOT/config"         # 📁 ที่เก็บไฟล์ config สำหรับติดตั้ง (ใช้ใน install.sh)
SCRIPTS_DIR="$PROJECT_ROOT/scripts"       # ⚙️  ที่เก็บไฟล์สคริปต์ เช่น backup_config.sh, install.sh, restore.sh
BACKUP_DIR="$PROJECT_ROOT/config_backups" # 🛡️  ที่ใช้เก็บไฟล์สำรอง (ก่อนถูกเขียนทับ)

# Timestamped backup directory
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TIMED_BACKUP_DIR="$BACKUP_DIR/original_$TIMESTAMP"

# List of system files to manage (full paths)
FILES_TO_MANAGE=(
  "/etc/default/grub"
  "$HOME/.zshrc"
  "$HOME/.config/kitty/kitty.conf"
  "$HOME/.config/starship.toml"
  "$HOME/.config/hypr/UserConfigs/WindowRules.conf"
  "$HOME/.config/hypr/UserConfigs/Startup_Apps.conf"
  "$HOME/.config/hypr/UserConfigs/UserSettings.conf"
)

# Map plain names for matching in config/ and restore
# Use associative arrays in scripts like:
#   declare -A FILE_MAP
#   source path_config.sh && for file in "${!RESTORE_PATHS[@]}"; do ...
declare -A RESTORE_PATHS=(
  ["grub"]="/etc/default/grub"
  ["zshrc"]="$HOME/.zshrc"
  ["kitty.conf"]="$HOME/.config/kitty/kitty.conf"
  ["starship.toml"]="$HOME/.config/starship.toml"
  ["WindowRules.conf"]="$HOME/.config/hypr/UserConfigs/WindowRules.conf"
  ["Startup_Apps.conf"]="$HOME/.config/hypr/UserConfigs/Startup_Apps.conf"
  ["UserSettings.conf"]="$HOME/.config/hypr/UserConfigs/UserSettings.conf"
)
