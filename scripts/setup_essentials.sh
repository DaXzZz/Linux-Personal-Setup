#!/bin/bash
#
# ESSENTIAL SETUP SCRIPT
# ======================
# PURPOSE: Prepares your Arch Linux system with core tools needed for JaKooLit's Hyprland configs
#
# WHAT IT DOES:
# - Installs Paru AUR helper for accessing packages not in official repositories
# - Installs Starship prompt for an enhanced terminal experience
# - Installs necessary fonts for proper display of UI elements and icons
# - Optionally installs basic development tools if needed
#
# WHEN TO USE: Before running install.sh to ensure all dependencies are available
#

# Prompt user for confirmation and installation mode
echo -e "\n========== ARCH HYPRLAND ESSENTIAL TOOLS SETUP =========="
echo "This script installs the core components needed for your Hyprland configuration:"
echo "  • Paru - AUR helper for installing packages not in official repos"
echo "  • Starship - Modern, minimal and customizable prompt for your shell"
echo "  • Essential fonts - For proper icon display and text rendering"
echo "  • Development tools (optional) - VSCode, Python, Node.js"
echo "==========================================================="

read -p "Do you want to continue with the installation? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

# Ask for installation mode
echo -e "\nSelect installation mode:"
echo "1) Automatic - Install all essential tools without prompting for each"
echo "2) Interactive - Ask for confirmation before each component"
read -p "Enter your choice (1 or 2): " mode
case "$mode" in
    1) AUTO_MODE=true ;;
    2) AUTO_MODE=false ;;
    *) echo "Invalid selection. Defaulting to interactive mode."; AUTO_MODE=false ;;
esac

# Error handling
set -e

# Fix for path resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Log file
LOG_FILE="$SCRIPT_DIR/setup_log.txt"
echo "Starting installation at $(date)" > "$LOG_FILE"

# Function to log messages
log_message() {
    echo "$1"
    echo "$(date +"%H:%M:%S"): $1" >> "$LOG_FILE"
}

# Function to install a package with pacman if not already installed
install_pacman_pkg() {
    local pkg_name="$1"
    local pkg_desc="${2:-$1}"
    
    if ! pacman -Q "$pkg_name" &>/dev/null; then
        if [[ "$AUTO_MODE" == "true" ]] || prompt_yes_no "Install $pkg_desc?"; then
            log_message "📦 Installing $pkg_desc..."
            sudo pacman -S --noconfirm "$pkg_name" &>> "$LOG_FILE"
            log_message "✅ Installed $pkg_desc"
        else
            log_message "⏭️ Skipped installation of $pkg_desc"
        fi
    else
        log_message "✓ $pkg_desc is already installed"
    fi
}

# Function to install a package with paru if not already installed
install_paru_pkg() {
    local pkg_name="$1"
    local pkg_desc="${2:-$1}"
    
    if ! paru -Q "$pkg_name" &>/dev/null; then
        if [[ "$AUTO_MODE" == "true" ]] || prompt_yes_no "Install $pkg_desc?"; then
            log_message "📦 Installing $pkg_desc from AUR..."
            paru -S --noconfirm "$pkg_name" &>> "$LOG_FILE"
            log_message "✅ Installed $pkg_desc"
        else
            log_message "⏭️ Skipped installation of $pkg_desc"
        fi
    else
        log_message "✓ $pkg_desc is already installed"
    fi
}

# Function to prompt for yes/no confirmation
prompt_yes_no() {
    local prompt="$1"
    while true; do
        read -p "$prompt (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

echo "========================================="
log_message "🚀 Starting essential setup..."
echo "========================================="

# Install git if not already installed (needed for paru)
install_pacman_pkg "git" "Git (required for Paru)"
install_pacman_pkg "base-devel" "Base development tools (required for Paru)"

# Install paru if not already installed
if ! command -v paru &>/dev/null; then
    if [[ "$AUTO_MODE" == "true" ]] || prompt_yes_no "Install Paru (AUR helper)?"; then
        log_message "📦 Installing Paru (AUR helper)..."
        
        # Create a temporary directory
        TEMP_DIR=$(mktemp -d)
        cd "$TEMP_DIR"
        
        # Clone and build paru
        git clone https://aur.archlinux.org/paru.git &>> "$LOG_FILE"
        cd paru
        makepkg -si --noconfirm &>> "$LOG_FILE"
        
        # Clean up
        cd "$SCRIPT_DIR"
        rm -rf "$TEMP_DIR"
        
        log_message "✅ Installed Paru"
    else
        log_message "⏭️ Skipped installation of Paru"
    fi
else
    log_message "✓ Paru is already installed"
fi

# Install Starship prompt
if [[ "$AUTO_MODE" == "true" ]] || prompt_yes_no "Install Starship prompt?"; then
    log_message "📦 Installing Starship prompt..."
    install_pacman_pkg "starship" "Starship prompt"
else
    log_message "⏭️ Skipped installation of Starship prompt"
fi

# Install fonts
if [[ "$AUTO_MODE" == "true" ]] || prompt_yes_no "Install essential fonts?"; then
    log_message "📦 Installing fonts..."
    install_pacman_pkg "ttf-jetbrains-mono-nerd" "JetBrains Mono Nerd Font"
    install_pacman_pkg "noto-fonts" "Noto Fonts"
    install_pacman_pkg "noto-fonts-emoji" "Noto Emoji Fonts"
else
    log_message "⏭️ Skipped installation of fonts"
fi

# Optional: Development tools
if prompt_yes_no "Do you want to install development tools (VSCode, Python, Node.js)?"; then
    log_message "📦 Installing development tools..."
    if [[ "$AUTO_MODE" == "true" ]]; then
        # Install all dev tools without prompting
        install_paru_pkg "visual-studio-code-bin" "Visual Studio Code"
        install_pacman_pkg "python" "Python"
        install_pacman_pkg "python-pip" "Python pip package manager"
        install_pacman_pkg "nodejs" "Node.js"
        install_pacman_pkg "npm" "npm package manager"
    else
        # Ask for each dev tool
        install_paru_pkg "visual-studio-code-bin" "Visual Studio Code"
        install_pacman_pkg "python" "Python"
        install_pacman_pkg "python-pip" "Python pip package manager"
        install_pacman_pkg "nodejs" "Node.js"
        install_pacman_pkg "npm" "npm package manager"
    fi
else
    log_message "⏭️ Skipped installation of development tools"
fi

# Skip services - removed as requested

# Summary
echo "========================================="
log_message "✅ Essential setup complete!"
echo "========================================="
echo "The following components were processed:"
echo " - Paru (AUR helper)"
echo " - Starship prompt"
echo " - Essential fonts"
echo "Log file saved to: $LOG_FILE"

exit 0