#!/bin/bash
#
# ESSENTIAL UNINSTALL SCRIPT
# ===========================
# PURPOSE: Uninstalls all packages installed by essential-setup-final.sh
#

echo -e "\n========== ARCH HYPRLAND ESSENTIAL TOOLS UNINSTALL =========="
read -p "Are you sure you want to uninstall all installed packages? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

set -e

# Helper to uninstall via pacman
uninstall_pacman_pkg() {
    pkg="$1"
    if pacman -Q "$pkg" &>/dev/null; then
        echo "🗑️ Removing $pkg..."
        sudo pacman -Rns --noconfirm "$pkg"
    else
        echo "✅ $pkg is not installed. Skipping."
    fi
}

# Helper to uninstall via paru (AUR)
uninstall_paru_pkg() {
    pkg="$1"
    if paru -Q "$pkg" &>/dev/null; then
        echo "🗑️ Removing $pkg (AUR)..."
        paru -Rns --noconfirm "$pkg"
    else
        echo "✅ $pkg (AUR) is not installed. Skipping."
    fi
}

# Disable services first
echo -e "\n🔧 Disabling related services..."

sudo systemctl disable --now preload || true
sudo systemctl disable --now docker || true
sudo systemctl disable --now ufw || true

echo -e "\n🗑️ Uninstalling packages installed by the setup script..."

# Uninstall pacman packages
for pkg in \
    p7zip unrar tar rsync git neofetch htop nano exfatprogs fuse-exfat ntfs-3g flac jasper aria2 curl wget \
    cmake clang imagemagick go timeshift btop zoxide firefox vlc gimp qt6-multimedia-ffmpeg krita thunderbird \
    trash-cli iputils inetutils intel-ucode obs-studio python python-pip nodejs npm bat ufw gufw reflector \
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji starship; do
    uninstall_pacman_pkg "$pkg"
done

# Uninstall paru packages
for pkg in \
    preload libreoffice-fresh pamac-gtk discord telegram-desktop postman-bin docker visual-studio-code-bin \
    github-cli docker-compose archlinux-tweak-tool-git; do
    uninstall_paru_pkg "$pkg"
done

echo -e "\n✅ Uninstallation complete!"
echo "⚡ You may want to manually remove leftover configs in your home directory if necessary."
exit 0
