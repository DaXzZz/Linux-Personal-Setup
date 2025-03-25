# Arch Hyprland Config 🚀

Personal Arch Linux + Hyprland configuration optimized for dual monitors and productivity.

## 📦 What's Included
- **Hyprland**: Multi-monitor setup with workspace defaults
- **Terminal**: Kitty + ZSH + Starship prompt
- **System**: GRUB with NVIDIA support + SDDM fixes

## 💻 Monitor Setup
- Main: DP-1 (1080p@165Hz, landscape)
- Secondary: HDMI-A-1 (1080p@60Hz, vertical)

## 🛠️ Quick Setup

```bash
# Clone repo
git clone https://github.com/DaXzZz/Arch-Hyprland-Config.git
cd Arch-Hyprland-Config

# Install configs using script
./scripts/install.sh

# Or backup your current configs
./scripts/backup.sh
```

## 📝 Other Commands
- `./scripts/restore.sh` - Restore previous config backups
- `hyprctl reload` - Apply changes to Hyprland

---

✨ Make your Hyprland feel like home!