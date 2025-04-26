#!/bin/bash
#
# ESSENTIAL SETUP SCRIPT
# ======================
# PURPOSE: Prepares your Arch Linux system with core tools needed for JaKooLit's Hyprland configs
#

echo -e "\n========== ARCH HYPRLAND ESSENTIAL TOOLS SETUP =========="
echo "This script installs the core components needed for your Hyprland configuration:"
echo "  • Paru - AUR helper"
echo "  • Starship - Modern shell prompt"
echo "  • Fonts - For icons and UI display"
echo "  • Full app suite (VSCode, Python, Node.js, etc.)"
echo "==========================================================="

read -p "Do you want to continue with the installation? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

# Select mode
echo -e "\nInstall mode:"
echo "1) Automatic - No confirmations"
echo "2) Interactive - Confirm each group"
read -p "Choose [1/2]: " mode
[[ "$mode" == "1" ]] && AUTO_MODE=true || AUTO_MODE=false

set -e

# Helper: prompt yes/no
prompt_yes_no() {
    [[ "$AUTO_MODE" == "true" ]] && return 0
    while true; do
        read -p "$1 (y/n): " yn
        case "$yn" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

# Install via pacman
install_pacman_pkg() {
    pkg="$1"
    if ! pacman -Q "$pkg" &>/dev/null; then
        sudo pacman -S --noconfirm "$pkg"
    fi
}

# Install via paru
install_paru_pkg() {
    pkg="$1"
    if ! paru -Q "$pkg" &>/dev/null; then
        paru -S --noconfirm "$pkg"
    fi
}

# git + base-devel (for paru build)
install_pacman_pkg git
install_pacman_pkg base-devel

# Install paru (if not already installed)
if ! command -v paru &>/dev/null; then
    prompt_yes_no "Install paru (AUR helper)?" && {
        cd /tmp
        git clone https://aur.archlinux.org/paru.git
        cd paru
        makepkg -si --noconfirm
    }
fi

# Starship prompt
prompt_yes_no "Install Starship prompt?" && install_pacman_pkg starship

# Fonts
prompt_yes_no "Install fonts?" && {
    install_pacman_pkg ttf-jetbrains-mono-nerd
    install_pacman_pkg noto-fonts
    install_pacman_pkg noto-fonts-emoji
}

# Full app suite
prompt_yes_no "Install core desktop apps & tools?" && {

    # Packages via pacman
    sudo pacman -S \
        p7zip unrar tar rsync git neofetch htop exfatprogs fuse-exfat ntfs-3g flac jasper aria2 curl wget \
        timeshift btop zoxide firefox vlc gimp qt6-multimedia-ffmpeg krita thunderbird trash-cli iputils \
        inetutils intel-ucode obs-studio python python-pip nodejs npm bat preload ufw gufw

    # Packages via paru
    paru -S \
        libreoffice-fresh pamac-gtk discord telegram-desktop postman-bin docker visual-studio-code-bin \
        github-cli docker-compose archlinux-tweak-tool-git
}

echo -e "\n✅ Setup complete! You may now run ./install.sh to restore your configs."
exit 0
