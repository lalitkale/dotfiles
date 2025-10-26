# Tuxedo Machine Dotfiles

This directory contains configuration backups for your Tuxedo machine running Linux 6.14.0-113033-tuxedo.

## What's Backed Up

### Shell Configurations
- `.zshrc` - Zsh shell configuration
- `.bashrc` - Bash shell configuration
- `.aliases` - Custom shell aliases
- `.bash_aliases` - Bash-specific aliases

### Version Control
- `.gitconfig` - Git configuration (username, email, aliases, etc.)

### Terminal Emulator
- `ghostty/` - Ghostty terminal emulator configuration

### Desktop Environment
- `budgie-panel.dconf` - Budgie desktop panel settings
- `budgie-wm.dconf` - Budgie window manager settings
- `gnome-settings.dconf` - GNOME desktop settings

## System Information
- **OS**: Linux 6.14.0-113033-tuxedo
- **Desktop Environment**: Budgie with GNOME
- **Shell**: Zsh (with Bash configs also available)
- **Terminal**: Ghostty
- **Backup Date**: 2025-10-26

## How to Restore

### Quick Restore (All Configs)
```bash
cd /home/lalit/dotfiles/tuxedo
./restore.sh
```

The restore script will:
1. Create a backup of your current configurations
2. Restore all dotfiles to their proper locations
3. Restore desktop environment settings via dconf

### Manual Restore (Individual Files)

#### Shell Configurations
```bash
cp .zshrc ~/.zshrc
cp .bashrc ~/.bashrc
cp .aliases ~/.aliases
cp .bash_aliases ~/.bash_aliases
source ~/.zshrc  # or source ~/.bashrc
```

#### Git Configuration
```bash
cp .gitconfig ~/.gitconfig
```

#### Terminal Configuration
```bash
cp -r ghostty ~/.config/ghostty
```

#### Desktop Environment Settings
```bash
dconf load /com/solus-project/budgie-panel/ < budgie-panel.dconf
dconf load /com/solus-project/budgie-wm/ < budgie-wm.dconf
dconf load /org/gnome/ < gnome-settings.dconf
```

## Important Notes

1. **Desktop Settings**: After restoring desktop environment settings, you may need to log out and log back in for changes to take effect.

2. **Shell Changes**: After restoring shell configurations, either restart your terminal or run `source ~/.zshrc` to apply changes immediately.

3. **Backups**: The restore script automatically creates backups of your existing configurations before overwriting them.

4. **Version Control**: If you're using this across multiple machines, consider initializing a git repository:
   ```bash
   cd /home/lalit/dotfiles
   git init
   git add .
   git commit -m "Initial Tuxedo machine dotfiles backup"
   ```

## Updating This Backup

To update the configurations in this directory with your current system settings:

```bash
# Shell configs
cp ~/.zshrc /home/lalit/dotfiles/tuxedo/.zshrc
cp ~/.bashrc /home/lalit/dotfiles/tuxedo/.bashrc
cp ~/.aliases /home/lalit/dotfiles/tuxedo/.aliases
cp ~/.bash_aliases /home/lalit/dotfiles/tuxedo/.bash_aliases

# Git config
cp ~/.gitconfig /home/lalit/dotfiles/tuxedo/.gitconfig

# Terminal config
cp -r ~/.config/ghostty /home/lalit/dotfiles/tuxedo/ghostty

# Desktop environment
dconf dump /com/solus-project/budgie-panel/ > /home/lalit/dotfiles/tuxedo/budgie-panel.dconf
dconf dump /com/solus-project/budgie-wm/ > /home/lalit/dotfiles/tuxedo/budgie-wm.dconf
dconf dump /org/gnome/ > /home/lalit/dotfiles/tuxedo/gnome-settings.dconf
```
