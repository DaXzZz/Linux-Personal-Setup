#!/usr/bin/env bash
#
# ESSENTIAL SETUP SCRIPT
# ======================
# PURPOSE:
#   Prepare Arch Linux with core tools for Hyprland / KoolDots / JaKooLit-style configs.
#
# Notes:
#   - Installs packages/tools only.
#   - Does NOT write user config files.
#   - oh-my-posh theme is handled by install_config.sh.
#   - preload, pamac, archlinux-tweak-tool-git, and GRUB changes are excluded.
#

set -Eeuo pipefail

info() { echo -e "\n==> $*"; }
ok() { echo "✅ $*"; }
warn() { echo "⚠️  $*"; }
err() { echo "❌ $*" >&2; }

run_sudo() { sudo "$@"; }
have_cmd() { command -v "$1" &>/dev/null; }
pkg_installed() { pacman -Q "$1" &>/dev/null; }
aur_clone_url() { echo "https://aur.archlinux.org/${1}.git"; }

prompt_yes_no() {
    local question="$1"
    if [[ "${AUTO_MODE:-false}" == "true" ]]; then
        return 0
    fi

    local yn
    while true; do
        read -r -p "$question (y/n): " yn
        case "$yn" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo "Please answer y or n." ;;
        esac
    done
}

install_pacman_pkg() {
    local pkg="$1"

    if pkg_installed "$pkg"; then
        ok "$pkg is already installed. Skipping."
        return 0
    fi

    info "Installing $pkg..."
    run_sudo pacman -S --needed --noconfirm "$pkg"
}

install_pacman_pkgs() {
    local pkgs=("$@")
    local missing=()

    for pkg in "${pkgs[@]}"; do
        if pkg_installed "$pkg"; then
            ok "$pkg is already installed. Skipping."
        else
            missing+=("$pkg")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        info "Installing pacman packages: ${missing[*]}"
        run_sudo pacman -S --needed --noconfirm "${missing[@]}"
    fi
}

install_aur_direct() {
    local pkg="$1"
    local build_dir="/tmp/${pkg}"

    if pkg_installed "$pkg"; then
        ok "$pkg is already installed. Skipping."
        return 0
    fi

    info "Installing $pkg from AUR via git + makepkg..."
    rm -rf "$build_dir"

    if ! git clone "$(aur_clone_url "$pkg")" "$build_dir"; then
        err "Failed to clone AUR package: $pkg"
        return 1
    fi

    (
        cd "$build_dir"
        makepkg -si --noconfirm
    )
}

install_aur_pkg() {
    local pkg="$1"

    if pkg_installed "$pkg"; then
        ok "$pkg is already installed. Skipping."
        return 0
    fi

    if have_cmd paru; then
        info "Installing $pkg with paru..."
        if paru -S --needed --noconfirm "$pkg"; then
            return 0
        fi
        warn "paru failed for $pkg. Falling back to direct AUR git + makepkg."
    else
        warn "paru not found. Falling back to direct AUR git + makepkg for $pkg."
    fi

    install_aur_direct "$pkg"
}

install_aur_pkg_optional() {
    local pkg="$1"

    if ! install_aur_pkg "$pkg"; then
        warn "Skipping optional AUR package: $pkg"
        FAILED_AUR_PACKAGES+=("$pkg")
        return 0
    fi
}

enable_service_if_exists() {
    local service="$1"

    if systemctl list-unit-files "${service}.service" &>/dev/null; then
        info "Enabling $service..."
        run_sudo systemctl enable --now "$service" || warn "Could not enable $service."
    else
        warn "Service not found: $service. Skipping."
    fi
}

install_zsh_plugins() {
    info "Installing Zsh, Oh-My-Zsh, and plugins..."

    install_pacman_pkgs zsh curl git

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        info "Installing Oh-My-Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        ok "Oh-My-Zsh already installed. Skipping."
    fi

    mkdir -p "$HOME/.oh-my-zsh/custom/plugins"
    local plugin_dir="$HOME/.oh-my-zsh/custom/plugins"

    [[ -d "$plugin_dir/zsh-autosuggestions" ]] \
        && ok "zsh-autosuggestions already installed." \
        || git clone https://github.com/zsh-users/zsh-autosuggestions.git "$plugin_dir/zsh-autosuggestions"

    [[ -d "$plugin_dir/zsh-syntax-highlighting" ]] \
        && ok "zsh-syntax-highlighting already installed." \
        || git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugin_dir/zsh-syntax-highlighting"

    [[ -d "$plugin_dir/zsh-completions" ]] \
        && ok "zsh-completions already installed." \
        || git clone https://github.com/zsh-users/zsh-completions.git "$plugin_dir/zsh-completions"

    [[ -d "$plugin_dir/you-should-use" ]] \
        && ok "you-should-use already installed." \
        || git clone https://github.com/MichaelAquilina/zsh-you-should-use.git "$plugin_dir/you-should-use"

    echo
    ok "Zsh plugins installed."
    echo 'Use this in ~/.zshrc:'
    echo 'plugins=(git archlinux zsh-autosuggestions zsh-syntax-highlighting zsh-completions you-should-use sudo command-not-found extract)'
}

install_paru_if_needed() {
    if have_cmd paru; then
        ok "paru already installed. Skipping."
        return 0
    fi

    if ! prompt_yes_no "Install paru (AUR helper)?"; then
        warn "paru skipped. AUR packages will use direct git + makepkg fallback."
        return 0
    fi

    install_pacman_pkgs git base-devel

    info "Installing paru from AUR..."
    rm -rf /tmp/paru

    if git clone https://aur.archlinux.org/paru.git /tmp/paru; then
        (
            cd /tmp/paru
            makepkg -si --noconfirm
        )
    else
        warn "Could not clone paru. Continuing without paru."
    fi
}

configure_git_if_needed() {
    local git_username
    local git_email

    git_username=$(git config --global --get user.name || true)
    git_email=$(git config --global --get user.email || true)

    if [[ -n "$git_username" && -n "$git_email" ]]; then
        echo
        ok "Git is already configured:"
        echo "user.name: $git_username"
        echo "user.email: $git_email"
        return 0
    fi

    echo
    warn "No global Git user.name or user.email found."

    if prompt_yes_no "Configure Git username, email, and default branch?"; then
        read -r -p "Enter your Git username: " git_username
        read -r -p "Enter your Git email: " git_email

        git config --global user.name "$git_username"
        git config --global user.email "$git_email"
        git config --global color.ui auto
        git config --global init.defaultBranch main
        git config --global core.editor nano

        ok "Git configuration updated."
    fi
}

update_mirrorlist_if_requested() {
    if ! prompt_yes_no "Update mirrorlist with reflector now?"; then
        return 0
    fi

    install_pacman_pkg reflector

    while true; do
        run_sudo reflector \
            --verbose \
            --latest 10 \
            --protocol https \
            --sort rate \
            --download-timeout 20 \
            --save /etc/pacman.d/mirrorlist

        echo
        info "Current mirrorlist preview:"
        head -n 20 /etc/pacman.d/mirrorlist || true

        prompt_yes_no "Are you satisfied with this mirrorlist?" && break
        echo
        info "Re-running reflector..."
    done

    run_sudo pacman -Syyu --noconfirm
}

final_checklist() {
    echo
    info "Final checklist"

    echo "▶️ Oh-My-Posh:"
    have_cmd oh-my-posh && ok "oh-my-posh is installed." || warn "oh-my-posh is not installed."

    echo "▶️ Intel Microcode:"
    pkg_installed intel-ucode && ok "intel-ucode is installed." || warn "intel-ucode is not installed."

    echo "▶️ Docker service:"
    systemctl is-active docker &>/dev/null && ok "Docker is active." || warn "Docker is not running."

    echo "▶️ UFW firewall:"
    systemctl is-active ufw &>/dev/null && ok "UFW is active." || warn "UFW is not active."

    echo "▶️ UFW default policies:"
    if have_cmd ufw; then
        run_sudo ufw status verbose | grep "Default" || warn "Could not retrieve UFW default policies."
    else
        warn "ufw command not found."
    fi

    echo "▶️ Mirrorlist:"
    grep -q "https" /etc/pacman.d/mirrorlist && ok "Mirrorlist contains HTTPS mirrors." || warn "Mirrorlist may not be updated."

    echo "▶️ Docker group:"
    if groups "$USER" | grep -qw docker; then
        ok "User '$USER' is in docker group."
    else
        warn "User '$USER' is not in docker group."
    fi

    if (( ${#FAILED_AUR_PACKAGES[@]} > 0 )); then
        echo
        warn "Some optional AUR packages failed or were skipped:"
        printf ' - %s\n' "${FAILED_AUR_PACKAGES[@]}"
    fi
}

FAILED_AUR_PACKAGES=()

echo -e "\n========== ARCH HYPRLAND ESSENTIAL TOOLS SETUP =========="
echo "This script installs core components for your Hyprland configuration:"
echo "  • paru - AUR helper"
echo "  • fonts - icons and UI display"
echo "  • zsh + oh-my-zsh plugins"
echo "  • oh-my-posh-bin"
echo "  • desktop/dev tools"
echo "==========================================================="

read -r -p "Do you want to continue with the installation? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

echo -e "\nInstall mode:"
echo "1) Automatic - install everything without asking"
echo "2) Interactive (default) - confirm each major step"
echo "3) Install Zsh plugins only"
read -r -p "Choose [1/2/3] (default 2): " mode

case "${mode:-2}" in
    1) AUTO_MODE=true ;;
    2) AUTO_MODE=false ;;
    3)
        AUTO_MODE=false
        install_zsh_plugins
        exit 0
        ;;
    *)
        warn "Invalid mode. Using interactive mode."
        AUTO_MODE=false
        ;;
esac

git config --global http.version HTTP/1.1 || true

install_pacman_pkgs git base-devel ca-certificates curl openssl

if have_cmd update-ca-trust; then
    run_sudo update-ca-trust || true
fi

install_paru_if_needed

if prompt_yes_no "Install Oh-My-Posh?"; then
    install_aur_pkg oh-my-posh-bin || warn "Oh-My-Posh install failed. Retry later with: paru -S oh-my-posh-bin"
fi

if prompt_yes_no "Install fonts?"; then
    install_pacman_pkgs \
        ttf-jetbrains-mono-nerd \
        noto-fonts \
        noto-fonts-emoji \
        otf-font-awesome
fi

if prompt_yes_no "Install Zsh plugins?"; then
    install_zsh_plugins
fi

if prompt_yes_no "Install core desktop apps and tools?"; then
    install_pacman_pkgs \
        p7zip unrar tar rsync git fastfetch htop nano exfatprogs ntfs-3g flac jasper aria2 curl wget \
        cmake clang imagemagick go timeshift btop zoxide firefox vlc gimp qt6-multimedia-ffmpeg krita thunderbird \
        trash-cli iputils inetutils intel-ucode obs-studio python python-pip nodejs npm bat ufw gufw reflector \
        docker docker-compose github-cli discord telegram-desktop

    for pkg in \
        postman-bin \
        visual-studio-code-bin; do
        install_aur_pkg_optional "$pkg"
    done
fi

configure_git_if_needed
update_mirrorlist_if_requested

if prompt_yes_no "Enable UFW firewall?"; then
    install_pacman_pkg ufw
    enable_service_if_exists ufw

    if prompt_yes_no "Set UFW default deny incoming and allow outgoing?"; then
        run_sudo ufw default deny incoming
        run_sudo ufw default allow outgoing
        run_sudo ufw --force enable
    fi
fi

if prompt_yes_no "Enable Docker and add current user to docker group?"; then
    install_pacman_pkgs docker docker-compose
    enable_service_if_exists docker

    if ! groups "$USER" | grep -qw docker; then
        run_sudo usermod -aG docker "$USER"
        warn "Reboot or log out/in to apply Docker group permissions."
    else
        ok "User '$USER' is already in docker group."
    fi
fi

final_checklist

echo
ok "Setup complete."
echo "Manual notes:"
echo "- Config files are handled by install_config.sh."
echo "- For zoxide in zsh:"
echo '  eval "$(zoxide init zsh)"'
echo "- For oh-my-posh in zsh:"
echo '  eval "$(oh-my-posh init zsh --config ~/.config/ohmyposh/EDM115-newline.omp.json)"'
echo "- Create SSH key if needed:"
echo "  ssh-keygen -t ed25519"
echo "- Update regularly:"
echo "  sudo pacman -Syu && paru -Syu"
echo "- Remove orphan packages carefully:"
echo '  sudo pacman -Rns $(pacman -Qtdq)'

exit 0