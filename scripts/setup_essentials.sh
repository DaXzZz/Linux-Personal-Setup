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
echo "1) Automatic - Install everything without asking"
echo "2) Interactive (default) - Confirm before each major step"
read -p "Choose [1/2] (default 2): " mode

# Default to 2 (Interactive) if no input
if [[ -z "$mode" || "$mode" == "2" ]]; then
    AUTO_MODE=false
else
    AUTO_MODE=true
fi

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

# Install via pacman (with skipping message)
install_pacman_pkg() {
    pkg="$1"
    if pacman -Q "$pkg" &>/dev/null; then
        echo "✅ $pkg is already installed. Skipping."
    else
        echo "⬇️ Installing $pkg..."
        sudo pacman -S --noconfirm "$pkg"
    fi
}

# Install via paru (with skipping message)
install_paru_pkg() {
    pkg="$1"
    if paru -Q "$pkg" &>/dev/null; then
        echo "✅ $pkg is already installed (AUR). Skipping."
    else
        echo "⬇️ Installing $pkg (from AUR)..."
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

# Install Starship prompt
prompt_yes_no "Install Starship prompt?" && install_pacman_pkg starship

# Install Fonts
prompt_yes_no "Install fonts?" && {
    install_pacman_pkg ttf-jetbrains-mono-nerd
    install_pacman_pkg noto-fonts
    install_pacman_pkg noto-fonts-emoji
}

# Install Full app suite
prompt_yes_no "Install core desktop apps & tools?" && {
    # Packages via pacman
    for pkg in \
        p7zip unrar tar rsync git neofetch htop nano exfatprogs fuse-exfat ntfs-3g flac jasper aria2 curl wget \
        cmake clang imagemagick go timeshift btop zoxide firefox vlc gimp qt6-multimedia-ffmpeg krita thunderbird \
        trash-cli iputils inetutils intel-ucode obs-studio python python-pip nodejs npm bat ufw gufw reflector; do
        install_pacman_pkg "$pkg"
    done

    # Packages via paru
    for pkg in \
        preload libreoffice-fresh pamac-gtk discord telegram-desktop postman-bin docker visual-studio-code-bin \
        github-cli docker-compose archlinux-tweak-tool-git; do
        install_paru_pkg "$pkg"
    done
}

# Configure Git
prompt_yes_no "Configure Git (username, email, default branch)?" && {
    read -p "Enter your Git username: " git_username
    read -p "Enter your Git email: " git_email
    git config --global user.name "$git_username"
    git config --global user.email "$git_email"
    git config --global color.ui auto
    git config --global init.defaultBranch main
    git config --global core.editor nano
    echo "✅ Git configuration has been set."
}

# Update mirrorlist with reflector
prompt_yes_no "Update mirrorlist with reflector?" && {
    sudo reflector --verbose --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
    sudo pacman -Syyu
}

# Update GRUB config
prompt_yes_no "Update GRUB config (important if intel-ucode installed)?" && {
    sudo grub-mkconfig -o /boot/grub/grub.cfg
}

# Enable preload service
sudo systemctl enable --now preload

# Enable UFW firewall
sudo systemctl enable --now ufw
sudo ufw enable
prompt_yes_no "Set UFW to deny incoming and allow outgoing connections?" && {
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
}

# Enable Docker and add user to docker group
prompt_yes_no "Enable Docker and add user to docker group?" && {
    sudo systemctl enable --now docker
    sudo usermod -aG docker $USER
    echo "⚠️ Please reboot your system to apply Docker group permissions."
}

# Final checklist
echo -e "\n🔍 Final checklist for your system:\n"

# Check if preload service is active
echo "▶️ Checking Preload service..."
systemctl is-enabled preload &>/dev/null && echo "✅ Preload is enabled." || echo "⚠️ Preload is NOT enabled."

# Check if intel-ucode package is installed
echo "▶️ Checking Intel Microcode (intel-ucode)..."
pacman -Q intel-ucode &>/dev/null && echo "✅ intel-ucode is installed." || echo "⚠️ intel-ucode is NOT installed."

# Check if Docker service is running
echo "▶️ Checking Docker service..."
systemctl is-active docker &>/dev/null && echo "✅ Docker service is active." || echo "⚠️ Docker service is NOT running."

# Check if UFW firewall is active
echo "▶️ Checking UFW firewall..."
systemctl is-active ufw &>/dev/null && echo "✅ UFW is active." || echo "⚠️ UFW is NOT active."

# Check if Reflector updated the mirrorlist
echo "▶️ Checking if mirrorlist was updated by Reflector..."
if grep -q "https" /etc/pacman.d/mirrorlist; then
    echo "✅ Mirrorlist seems updated (contains HTTPS mirrors)."
else
    echo "⚠️ Mirrorlist might not be updated. Please run reflector manually."
fi

# Check if GRUB config exists
echo "▶️ Checking GRUB config..."
if [[ -f /boot/grub/grub.cfg ]]; then
    echo "✅ GRUB config file exists."
else
    echo "⚠️ GRUB config file not found. Please run grub-mkconfig."
fi

# Final message
echo -e "\n✅ Setup complete!"
echo "⚡ Please check these manual steps (not fully automated by script):"
echo "- Setup Zoxide in your shell config (~/.bashrc or ~/.zshrc)"
echo "- Setup SSH Key if needed (ssh-keygen)"
echo "- Create Timeshift snapshot before big updates (timeshift --create)"
echo "- Fine-tune firewall rules (ufw allow/deny ports) if needed"
echo "- Review and customize your system settings"
echo -e "\n📚 Refer to the full Arch Linux First Setup Guide for detailed instructions."
exit 0
