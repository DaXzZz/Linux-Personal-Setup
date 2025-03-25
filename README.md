# Arch Hyprland Config 🚀

Personal setup for Arch Linux with Hyprland, optimized for multi-monitor, visual theming, and terminal productivity.

## 📦 Included Configs
- **Hyprland:** Dual monitor layout, workspace defaults, cursor fix
- **Kitty:** JetBrainsMono font, clean UI
- **GRUB:** Theme + NVIDIA boot args
- **ZSH:** Oh-My-Zsh with plugins & fastfetch
- **Starship:** Cyberpunk-style prompt with Git + clock
- **SDDM Fix:** Disables secondary screen at login, cursor fix

## 🖥️ Setup
- **Main:** DP-1 (landscape 1080p@165Hz)
- **Secondary:** HDMI-A-1 (vertical 1080p@60Hz)

## 🛠 Quick Install
```bash
git clone https://github.com/DaXzZz/Arch-Hyprland-Config.git
cd Arch-Hyprland-Config
```
Copy configs:
```bash
cp -r .config/hypr ~/.config/
cp -r .config/kitty ~/.config/
cp .zshrc ~/
cp .config/starship.toml ~/.config/
sudo cp etc/default/grub /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

## 💡 Tips
- `hyprctl reload` to refresh Hyprland
- Mount issues? See `ntfs_mount_fix_guide.txt`

---

Make your Hyprland feel like home! ✨
