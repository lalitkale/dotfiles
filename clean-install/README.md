# Tuxedo Machine Clean Install Setup

This directory contains everything needed to set up a fresh Tuxedo machine from scratch, including all packages, configurations, and system settings.

## What's Included

### Package Lists (`packages/`)
- `apt-packages.txt` - All manually installed APT packages
- `snap-packages.txt` - All installed Snap packages
- `flatpak-packages.txt` - All installed Flatpak packages (if any)
- `npm-global.txt` - Global npm packages
- `system-info.txt` - System and OS information

### Installation Scripts (`scripts/`)
- `install-packages.sh` - Installs all packages from the lists
- `setup-system.sh` - Configures system settings (shell, directories, etc.)
- `restore-configs.sh` - Restores dotfiles from `../tuxedo/` directory

### Bootstrap Script
- `bootstrap.sh` - Master script that runs everything in order

## Quick Start (Recommended)

For a complete clean installation on a fresh Tuxedo machine:

```bash
cd /home/lalit/dotfiles/clean-install
./bootstrap.sh
```

The bootstrap script will:
1. Update the system
2. Install all packages
3. Configure system settings
4. Restore your dotfiles and configurations
5. Provide a detailed log of everything

**Time estimate**: 30-60 minutes depending on internet speed and number of packages.

## Step-by-Step Installation (Manual)

If you prefer to run each step individually:

### Prerequisites

1. Fresh installation of Ubuntu/Linux on your Tuxedo machine
2. Internet connection
3. Sudo privileges
4. Git installed (if cloning this repository)

### Step 1: Clone or Copy This Repository

If starting from scratch, you'll need to get these dotfiles onto your new machine:

```bash
# Option 1: Clone from git (if you've committed this to a repo)
git clone <your-repo-url> ~/dotfiles

# Option 2: Copy from USB drive or other storage
cp -r /path/to/dotfiles ~/dotfiles
```

### Step 2: System Update

```bash
sudo apt update
sudo apt upgrade -y
```

### Step 3: Install Packages

```bash
cd ~/dotfiles/clean-install/scripts
./install-packages.sh
```

This will install:
- All APT packages
- Snap packages (installs snapd first if needed)
- Flatpak packages (installs flatpak first if needed)
- Global npm packages

**Note**: Failed packages will be logged and reported at the end.

### Step 4: System Configuration

```bash
./setup-system.sh
```

This will:
- Set Zsh as the default shell
- Install Oh My Zsh
- Create common directories (Projects, Documents, etc.)
- Add `~/.local/bin` to PATH
- Set up SSH directory with correct permissions
- Update font cache

### Step 5: Restore Configurations

```bash
./restore-configs.sh
```

This will:
- Restore shell configurations (.zshrc, .bashrc, aliases)
- Restore Git configuration
- Restore terminal emulator settings (Ghostty)
- Restore desktop environment settings (Budgie/GNOME)
- Back up existing configs before overwriting

### Step 6: Reboot

```bash
sudo reboot
```

## What Gets Installed

### Essential Tools
The APT packages list includes all software that was manually installed on the original system. This typically includes:
- Development tools (compilers, build tools, etc.)
- Text editors and IDEs
- Terminal emulators
- Shell utilities
- Version control systems
- Programming language runtimes
- System utilities

### Desktop Environment
- Budgie Desktop with GNOME components
- Desktop appearance settings
- Panel configuration
- Window manager settings

### Shell Environment
- Zsh (set as default shell)
- Oh My Zsh framework
- Custom aliases and shell functions
- Shell prompt configuration

## Logs and Troubleshooting

### Log Files

All scripts create detailed log files in your home directory:
- `~/bootstrap-<timestamp>.log` - Master bootstrap log
- `~/dotfiles-install-<timestamp>.log` - Package installation log
- `~/dotfiles-system-setup-<timestamp>.log` - System setup log
- `~/dotfiles-restore-<timestamp>.log` - Configuration restore log

### Common Issues

#### Package Installation Fails

Some packages may fail to install due to:
- Package name changes
- Package no longer available in repositories
- Dependency conflicts

**Solution**: Check the log file for failed packages and install them manually:
```bash
sudo apt install <package-name>
```

#### Snap/Flatpak Issues

**Issue**: Snap or Flatpak packages fail to install

**Solution**:
1. Ensure snapd/flatpak is properly installed
2. Check if the package name has changed
3. Try installing manually to see detailed error

#### Desktop Settings Not Applied

**Issue**: Desktop environment settings don't restore properly

**Solution**:
1. Ensure you're running Budgie desktop
2. Log out and log back in
3. Manually load settings:
   ```bash
   dconf load /com/solus-project/budgie-panel/ < ~/dotfiles/tuxedo/budgie-panel.dconf
   ```

#### Shell Not Changed

**Issue**: Default shell is still bash after running setup

**Solution**: The shell change requires a logout. Log out and log back in for it to take effect.

## Customization

### Selective Installation

If you don't want to install everything, you can edit the package lists before running the scripts:

```bash
# Edit package lists
nano ~/dotfiles/clean-install/packages/apt-packages.txt

# Remove or comment out (add # at start) packages you don't want
```

### Adding New Packages

To add packages to the installation:

1. Add package names to the appropriate file:
   - APT: `packages/apt-packages.txt`
   - Snap: `packages/snap-packages.txt`
   - Flatpak: `packages/flatpak-packages.txt`
   - NPM: `packages/npm-global.txt`

2. Run the installation script again:
   ```bash
   ./scripts/install-packages.sh
   ```

## Updating This Setup

As you install new software and make changes to your system, update these files:

```bash
# Update package lists
apt-mark showmanual > ~/dotfiles/clean-install/packages/apt-packages.txt
snap list | tail -n +2 | awk '{print $1}' > ~/dotfiles/clean-install/packages/snap-packages.txt

# Update configs (run from tuxedo directory)
cd ~/dotfiles/tuxedo
# Follow instructions in tuxedo/README.md to update configs
```

## Version Control

It's highly recommended to track these dotfiles with Git:

```bash
cd ~/dotfiles
git init
git add .
git commit -m "Initial Tuxedo machine dotfiles"

# Add remote repository
git remote add origin <your-repo-url>
git push -u origin main
```

This allows you to:
- Track changes over time
- Sync across multiple machines
- Revert to previous configurations
- Share with others

## System Information

These dotfiles were created from:
- **OS**: Linux 6.14.0-113033-tuxedo
- **Desktop**: Budgie with GNOME
- **Shell**: Zsh (with Bash support)
- **Terminal**: Ghostty
- **Date**: 2025-10-26

## Security Notes

1. **Review before running**: Always review scripts before running them, especially with sudo
2. **Git credentials**: The .gitconfig is included but passwords are NOT stored
3. **SSH keys**: SSH keys are NOT included - you'll need to regenerate or copy them manually
4. **Sensitive data**: This setup does NOT include any passwords, API keys, or sensitive credentials

## Manual Steps After Installation

Some things can't be automated and require manual setup:

1. **SSH Keys**
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

2. **Git Credentials**
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

3. **Browser Extensions**: Install and configure browser extensions manually

4. **Cloud Storage**: Set up Dropbox, Google Drive, or other cloud storage services

5. **VPN**: Configure VPN connections

6. **Application-Specific Settings**: Some applications store settings in non-standard locations

## Support

For issues or questions:
1. Check the log files first
2. Review the troubleshooting section above
3. Check the original package documentation
4. Consult the Tuxedo Computers support resources

## License

These are personal dotfiles. Use at your own risk. No warranty provided.
