#!/bin/bash

# Define target directory
TARGET_DIR="/home/ryu/Arch_Hyprland_Config/config"

# Create the target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# List of files to copy
FILES=(
    "/etc/default/grub"
    "$HOME/.zshrc"
    "$HOME/.config/kitty/kitty.conf"
    "$HOME/.config/starship.toml"
    "$HOME/.config/hypr/UserConfigs/WindowRules.conf"
    "$HOME/.config/hypr/UserConfigs/Startup_Apps.conf"
    "$HOME/.config/hypr/UserConfigs/UserSettings.conf"
)

# Copy each file
for FILE in "${FILES[@]}"; do
    if [ -f "$FILE" ]; then
        cp -f "$FILE" "$TARGET_DIR"
        echo "Copied: $FILE"
    else
        echo "Skipped (not found): $FILE"
    fi
done
