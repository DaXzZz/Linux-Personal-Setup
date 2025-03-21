# Arch Hyprland Config 🚀

This repository contains my personalized configurations and scripts for Arch Linux running the **Hyprland** window manager. It's optimized for productivity, aesthetics, and ease of use, perfect for daily workflows.

## 📂 What's Included

- **Hyprland Configurations:** Optimized multi-monitor setup, custom workspaces, and keybindings.
- **Kitty Terminal Configuration:** Enhanced terminal visuals, fonts, and overall experience.
- **GRUB Bootloader Configuration:** Customized boot menu with Nvidia modeset optimizations.
- **ZSH and Oh-My-Zsh:** Streamlined shell experience with powerful plugins.
- **Starship Prompt:** A minimal, cyberpunk-themed prompt integrated with Git status, command duration, and more.
- **SDDM Fix:** Solutions for multi-monitor issues during login and mouse placement.

## 🖥️ System Setup
- **Main Monitor:** `DP-1` (1920x1080@165Hz, Landscape)
- **Secondary Monitor:** `HDMI-A-1` (1920x1080@60Hz, Vertical rotated left)

## ⚙️ Configuration Highlights
- **SDDM Login:** Automatically disables secondary HDMI monitor at login for seamless focus on the main display.
- **Hyprland Multi-monitor:** Corrects mouse placement and workspace behavior.
- **Kitty Terminal:** JetBrains Mono Nerd Font, clean padding, and optimized rendering.
- **GRUB:** Graphical menu with Vimix theme, Nvidia modesetting tweaks, and optimal resolutions.
- **Starship Prompt:** Custom icons, Git integration, and time tracking to improve CLI productivity.

## 🚧 Installation Guide

1. **Clone the Repository:**
   ```sh
   git clone https://github.com/DaXzZz/Arch-Hyprland-Config.git
   cd Arch-Hyprland-Config
   ```

2. **Apply Configurations:**
   - **Hyprland:**
     ```sh
     cp -r .config/hypr ~/.config/
     ```
   - **Kitty Terminal:**
     ```sh
     cp -r .config/kitty ~/.config/
     ```
   - **GRUB:**
     ```sh
     sudo cp etc/default/grub /etc/default/grub
     sudo grub-mkconfig -o /boot/grub/grub.cfg
     ```
   - **ZSH:**
     ```sh
     cp .zshrc ~/ && source ~/.zshrc
     ```
   - **Starship:**
     ```sh
     cp -r .config/starship.toml ~/.config/
     ```

3. **Reboot** to apply all changes.

## 📸 Screenshots
(Feel free to add screenshots of your setup here)

## 🙌 Contribute

Feel free to fork, suggest improvements, or submit issues and PRs. Contributions and suggestions are always welcome!

---

Enjoy your fresh Arch Linux Hyprland setup! 🌟

