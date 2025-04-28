#!/bin/bash

set -euo pipefail

PROJECT_ROOT="${HOME}/Linux-Personal-Setup"
TARGET_DIR="${PROJECT_ROOT}/config"
SCRIPTS_DIR="${PROJECT_ROOT}/scripts"
BACKUP_DIR="${PROJECT_ROOT}/config_backups"

for dir in "$TARGET_DIR" "$SCRIPTS_DIR" "$BACKUP_DIR"; do
    mkdir -p "$dir"
done

FILES_TO_MANAGE=(
  "/etc/default/grub"
  "${HOME}/.zshrc"
  "${HOME}/.config/starship.toml"
  "${HOME}/.config/kitty/kitty.conf"
  "${HOME}/.config/fastfetch/config.jsonc"
  "${HOME}/.config/hypr/UserConfigs/WindowRules.conf"
  "${HOME}/.config/hypr/UserConfigs/Startup_Apps.conf"
  "${HOME}/.config/hypr/UserConfigs/UserSettings.conf"
  "${HOME}/.config/hypr/UserConfigs/UserDecorations.conf"
)

declare -A RESTORE_PATHS=(
  [grub]="/etc/default/grub"
  [zshrc]="${HOME}/.zshrc"
  [starship.toml]="${HOME}/.config/starship.toml"
  [kitty.conf]="${HOME}/.config/kitty/kitty.conf"
  [config.jsonc]="${HOME}/.config/fastfetch/config.jsonc"
  [WindowRules.conf]="${HOME}/.config/hypr/UserConfigs/WindowRules.conf"
  [Startup_Apps.conf]="${HOME}/.config/hypr/UserConfigs/Startup_Apps.conf"
  [UserSettings.conf]="${HOME}/.config/hypr/UserConfigs/UserSettings.conf"
  [UserDecorations.conf]="${HOME}/.config/hypr/UserConfigs/UserDecorations.conf"
)
