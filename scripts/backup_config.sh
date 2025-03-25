#!/bin/bash

# Define target directory
TARGET_DIR="/home/ryu/Arch-Hyprland-Config/config"

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

# Copy each file as plain .txt
for FILE in "${FILES[@]}"; do
    if [ -f "$FILE" ]; then
        BASENAME=$(basename "$FILE")
        # Check if the file starts with a dot
        if [[ "$BASENAME" == .* ]]; then
            NEW_NAME=${BASENAME#.}.txt  # Remove the leading dot and add .txt
        else
            NEW_NAME=$BASENAME.txt
        fi
        cp -f "$FILE" "$TARGET_DIR/$NEW_NAME"
        echo "Copied: $FILE as $NEW_NAME"
    else
        echo "Skipped (not found): $FILE"
    fi
done
