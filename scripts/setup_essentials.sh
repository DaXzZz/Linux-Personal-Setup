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
echo "  • Oh-My-Posh theme"
echo "==========================================================="

read -p "Do you want to continue with the installation? (y/n): " confirm
if DIMENSION
[[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

# Select mode
echo -e "\nInstall mode:"
echo "1) Automatic - Install everything without asking"
echo "2) Interactive (default) - Confirm before each major step"
echo "3) Install Oh-My-Posh Theme Only"
echo "4) Install Zsh Plugins Only"
read -p "Choose [1/2/3/4] (default 2): " mode

if [[ "$mode" == "3" ]]; then
    echo -e "\nInstalling Oh-My-Posh Theme..."
    mkdir -p ~/.config/ohmyposh
    cat << 'EOF' > ~/.config/ohmyposh/EDM115-newline.omp.json
{
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "blocks": [
    {
      "type": "prompt",
      "alignment": "left",
      "segments": [
        {
          "properties": {
            "cache_duration": "none"
          },
          "template": "\n\u256d\u2500",
          "foreground": "#f8f8f2",
          "type": "text",
          "style": "plain"
        },
        {
          "properties": {
            "cache_duration": "none"
          },
          "leading_diamond": "\ue0b6",
          "template": "{{ .UserName }}",
          "foreground": "#f8f8f2",
          "background": "#282a36",
          "type": "session",
          "style": "diamond"
        },
        {
          "properties": {
            "cache_duration": "none"
          },
          "template": "\udb85\udc0b",
          "foreground": "#ff5555",
          "powerline_symbol": "\ue0b0",
          "background": "#282a36",
          "type": "root",
          "style": "powerline"
        },
        {
          "properties": {
            "cache_duration": "none"
          },
          "template": "{{ .Icon }}  ",
          "foreground": "#f8f8f2",
          "powerline_symbol": "\ue0b0",
          "background": "#282a36",
          "type": "os",
          "style": "powerline"
        },
        {
          "properties": {
            "cache_duration": "none",
            "style": "full"
          },
          "trailing_diamond": "\ue0b4",
          "template": " \udb80\ude56 {{ path .Path .Location }}",
          "foreground": "#282a36",
          "background": "#cccccc",
          "type": "path",
          "style": "diamond"
        },
        {
          "properties": {
            "branch_icon": "",
            "cache_duration": "none",
            "display_changing_color": true,
            "fetch_status": true,
            "fetch_upstream_icon": true,
            "full_branch_path": true
          },
          "leading_diamond": "\ue0b6",
          "trailing_diamond": "\ue0b4",
          "template": "\ue725 ({{ url .UpstreamIcon .UpstreamURL }} {{ url .HEAD .UpstreamURL }}){{ if gt .Ahead 0 }}<#50fa7b> +{{ .Ahead }}</>{{ end }}{{ if gt .Behind 0 }}<#ff5555> -{{ .Behind }}</>{{ end }}{{ if .Working.Changed }}<#f8f8f2> \uf044 {{ .Working.String }}</>{{ end }}{{ if .Staging.Changed }}<#f8f8f2> \uf046 {{ .Staging.String }}</>{{ end }}",
          "foreground": "#282a36",
          "background": "#ffb86c",
          "type": "git",
          "style": "diamond"
        }
      ]
    },
    {
      "type": "prompt",
      "alignment": "left",
      "segments": [
        {
          "properties": {
            "always_enabled": true,
            "cache_duration": "none"
          },
          "template": "\u2570\u2500 ❯❯",
          "foreground": "#f8f8f2",
          "type": "text",
          "style": "diamond"
        }
      ],
      "newline": true
    }
  ],
  "version": 3,
  "patch_pwsh_bleed": true,
  "final_space": true
}
EOF
    echo "✅ Oh-My-Posh theme (EDM115-newline) installed at ~/.config/ohmyposh/EDM115-newline.omp.json"
    exit 0
fi

if [[ "$mode" == "4" ]]; then
    echo -e "\nInstalling Zsh, Oh-My-Zsh, and additional plugins..."
    # Install Zsh
    if command -v zsh &>/dev/null; then
        echo "✅ Zsh already installed. Skipping."
    else
        echo "⬇️ Installing zsh..."
        sudo pacman -S --noconfirm zsh
    fi
    # Install Oh-My-Zsh
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
    else
        echo "✅ Oh-My-Zsh already installed. Skipping."
    fi
    # Install additional plugins
    mkdir -p ~/.oh-my-zsh/custom/plugins
    cd ~/.oh-my-zsh/custom/plugins
    [[ -d zsh-autosuggestions ]] && echo "✅ zsh-autosuggestions already installed. Skipping." || git clone https://github.com/zsh-users/zsh-autosuggestions.git
    [[ -d zsh-syntax-highlighting ]] && echo "✅ zsh-syntax-highlighting already installed. Skipping." || git clone https://github.com/zsh-users/zsh-syntax-highlighting.git
    [[ -d zsh-completions ]] && echo "✅ zsh-completions already installed. Skipping." || git clone https://github.com/zsh-users/zsh-completions.git
    [[ -d you-should-use ]] && echo "✅ you-should-use already installed. Skipping." || git clone https://github.com/MichaelAquilina/zsh-you-should-use.git
    echo -e "\n✅ Zsh plugins installed. Please add the following to your ~/.zshrc:"
    echo "plugins=(git archlinux zsh-autosuggestions zsh-syntax-highlighting zsh-completions you-should-use sudo command-not-found extract)"
    exit 0
fi

if [[ -z "$mode" || "$mode" == "2" ]]; then
    AUTO_MODE=false
else
    AUTO_MODE=true
fi

set -e

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

install_pacman_pkg() {
    pkg="$1"
    if pacman -Q "$pkg" &>/dev/null; then
        echo "✅ $pkg is already installed. Skipping."
    else
        echo "⬇️ Installing $pkg..."
        sudo pacman -S --noconfirm "$pkg"
    fi
}

install_paru_pkg() {
    pkg="$1"
    if paru -Q "$pkg" &>/dev/null; then
        echo "✅ $pkg is already installed (AUR). Skipping."
    else
        echo "⬇️ Installing $pkg (from AUR)..."
        paru -S --noconfirm "$pkg"
    fi
}

install_pacman_pkg git
install_pacman_pkg base-devel

if ! command -v paru &>/dev/null; then
    prompt_yes_no "Install paru (AUR helper)?" && {
        cd /tmp
        git clone https://aur.archlinux.org/paru.git
        cd paru
        makepkg -si --noconfirm
    }
else
    echo "✅ paru already installed. Skipping."
fi

# Check starship
if command -v starship &>/dev/null; then
    echo "✅ Starship already installed. Skipping."
else
    prompt_yes_no "Install Starship prompt?" && install_pacman_pkg starship
fi

# Check oh-my-posh
if command -v oh-my-posh &>/dev/null; then
    echo "✅ oh-my-posh already installed. Skipping."
else
    prompt_yes_no "Install oh-my-posh?" && install_paru_pkg oh-my-posh
fi

prompt_yes_no "Install fonts?" && {
    install_pacman_pkg ttf-jetbrains-mono-nerd
    install_pacman_pkg noto-fonts
    install_pacman_pkg noto-fonts-emoji
}

prompt_yes_no "Install core desktop apps & tools?" && {
    for pkg in \
        p7zip unrar tar rsync git neofetch htop nano exfatprogs ntfs-3g flac jasper aria2 curl wget \
        cmake clang imagemagick go timeshift btop zoxide firefox vlc gimp qt6-multimedia-ffmpeg krita thunderbird \
        trash-cli iputils inetutils intel-ucode obs-studio python python-pip nodejs npm bat ufw gufw reflector; do
        install_pacman_pkg "$pkg"
    done

    for pkg in \
        preload libreoffice-fresh pamac-gtk discord telegram-desktop postman-bin docker visual-studio-code-bin \
        github-cli docker-compose archlinux-tweak-tool-git; do
        install_paru_pkg "$pkg"
    done
}

# Check current Git config
git_username=$(git config --global --get user.name)
git_email=$(git config --global --get user.email)

if [[ -n "$git_username" && -n "$git_email" ]]; then
    echo -e "\n✅ Git is already configured as:"
    echo "user.name: $git_username"
    echo "user.email: $git_email"
    echo "🔹 Skipping Git configuration."
else
    echo -e "\n⚠️ No Git user.name or email set."
    prompt_yes_no "Do you want to configure Git (username, email, default branch)?" && {
        read -p "Enter your Git username: " git_username
        read -p "Enter your Git email: " git_email
        git config --global user.name "$git_username"
        git config --global user.email "$git_email"
        git config --global color.ui auto
        git config --global init.defaultBranch main
        git config --global core.editor nano
        echo "✅ Git configuration has been updated."
    }
fi

# Update mirrorlist with reflector (confirm loop)
prompt_yes_no "Do you want to update the mirrorlist now?" && {
    while true; do
        sudo reflector --verbose --latest 10 --protocol https --sort rate --download-timeout 20 --save /etc/pacman.d/mirrorlist
        echo -e "\n🔍 Current top 5 mirrors:"
        head -n 20 /etc/pacman.d/mirrorlist

        prompt_yes_no "Are you satisfied with this mirrorlist?" && break
        echo -e "\n🔁 Re-running reflector to fetch new mirrors...\n"
    done

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
if groups $USER | grep -qw docker; then
    docker_group_status="✅ User '$USER' is already in docker group. Skipping."
    echo -e "\n$docker_group_status"
else
    docker_group_status="⚠️ User '$USER' is NOT in docker group."
    prompt_yes_no "Enable Docker and add user to docker group?" && {
        sudo systemctl enable --now docker
        sudo usermod -aG docker $USER
        echo "⚠️ Please reboot your system to apply Docker group permissions."
    }
fi

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

# Check UFW default policies
echo "▶️ Checking UFW default policies..."
sudo ufw status verbose | grep "Default" || echo "⚠️ Could not retrieve UFW default policies."

# Check if Reflector updated the mirrorlist
echo "▶️ Checking if mirrorlist was updated by Reflector..."
if grep -q "https" /etc/pacman.d/mirrorlist; then
    echo "✅ Mirrorlist seems updated (contains HTTPS mirrors)."
else
    echo "⚠️ Mirrorlist might not be updated. Please run reflector manually."
fi

# Show Docker group status
echo -e "\n▶️ Docker group status:"
echo "$docker_group_status"

# Check if GRUB config exists
echo "▶️ Checking GRUB config..."
if [[ -f /boot/grub/grub.cfg ]]; then
    echo "✅ GRUB config file exists."
else
    echo "⚠️ GRUB config file not found. Please run grub-mkconfig."
fi

# Final message
echo -e "\n✅ Setup complete!"
echo "⚡ Please complete these manual steps (not fully automated):"
echo "- Edit /etc/pacman.conf to enable ParallelDownloads and add ILoveCandy"
echo "- Setup shell integration for Zoxide (add 'eval \"\$(zoxide init bash)\"' to ~/.bashrc)"
echo "- Create SSH Key if needed: ssh-keygen -t ed25519"
echo "- Create Timeshift snapshot before major updates: timeshift --create"
echo "- Review and fine-tune UFW firewall rules: ufw allow/deny <ports>"
echo "- (Optional) Switch Desktop Manager: disable GDM, enable SDDM"
echo "- Regularly update system: sudo pacman -Syu && paru -Syu"
echo "- Clean up old package caches: sudo pacman -Sc"
echo "- Check system services: systemctl status"
echo "- Monitor disk usage: df -h"
echo "- Identify and remove orphan packages: sudo pacman -Rns \$(pacman -Qtdq)"
echo "- Customize system settings to fit your needs"
echo -e "\n📚 Refer to the full Arch Linux First Setup Guide for detailed instructions."

exit 0