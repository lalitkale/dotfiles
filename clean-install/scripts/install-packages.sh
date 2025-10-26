#!/bin/bash

# Package Installation Script for Tuxedo Machine
# This script installs all packages from the exported package lists

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="$SCRIPT_DIR/../packages"
LOG_FILE="$HOME/dotfiles-install-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log_success() {
    log "${GREEN}✓ $1${NC}"
}

log_error() {
    log "${RED}✗ $1${NC}"
}

log_info() {
    log "${YELLOW}→ $1${NC}"
}

echo "======================================"
echo "Package Installation Script"
echo "======================================"
echo ""
log_info "Log file: $LOG_FILE"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_error "Please do not run this script as root. It will use sudo when needed."
    exit 1
fi

# Update package lists
log_info "Updating package lists..."
sudo apt update 2>&1 | tee -a "$LOG_FILE"
log_success "Package lists updated"

# Install APT packages
if [ -f "$PACKAGES_DIR/apt-packages.txt" ]; then
    log_info "Installing APT packages..."
    log_info "This may take a while depending on the number of packages..."

    # Read packages and install
    FAILED_PACKAGES=()
    while IFS= read -r package; do
        # Skip empty lines and comments
        [[ -z "$package" || "$package" =~ ^# ]] && continue

        # Check if already installed
        if dpkg -l | grep -q "^ii  $package "; then
            log_info "Already installed: $package"
        else
            log_info "Installing: $package"
            if sudo apt install -y "$package" >> "$LOG_FILE" 2>&1; then
                log_success "Installed: $package"
            else
                log_error "Failed to install: $package"
                FAILED_PACKAGES+=("$package")
            fi
        fi
    done < "$PACKAGES_DIR/apt-packages.txt"

    if [ ${#FAILED_PACKAGES[@]} -eq 0 ]; then
        log_success "All APT packages installed successfully"
    else
        log_error "Failed to install ${#FAILED_PACKAGES[@]} packages:"
        printf '%s\n' "${FAILED_PACKAGES[@]}" | tee -a "$LOG_FILE"
    fi
else
    log_error "apt-packages.txt not found"
fi

# Install Snap packages
if [ -f "$PACKAGES_DIR/snap-packages.txt" ]; then
    log_info "Installing Snap packages..."

    if ! command -v snap &> /dev/null; then
        log_info "Snap not installed. Installing snapd..."
        sudo apt install -y snapd 2>&1 | tee -a "$LOG_FILE"
    fi

    FAILED_SNAPS=()
    while IFS= read -r package; do
        # Skip empty lines, comments, and core snaps
        [[ -z "$package" || "$package" =~ ^# || "$package" == "snapd" || "$package" == "core"* || "$package" == "bare" ]] && continue

        log_info "Installing snap: $package"
        if sudo snap install "$package" >> "$LOG_FILE" 2>&1; then
            log_success "Installed snap: $package"
        else
            log_error "Failed to install snap: $package"
            FAILED_SNAPS+=("$package")
        fi
    done < "$PACKAGES_DIR/snap-packages.txt"

    if [ ${#FAILED_SNAPS[@]} -eq 0 ]; then
        log_success "All Snap packages installed successfully"
    else
        log_error "Failed to install ${#FAILED_SNAPS[@]} snaps:"
        printf '%s\n' "${FAILED_SNAPS[@]}" | tee -a "$LOG_FILE"
    fi
else
    log_error "snap-packages.txt not found"
fi

# Install Flatpak packages
if [ -f "$PACKAGES_DIR/flatpak-packages.txt" ]; then
    if grep -q "flatpak not installed" "$PACKAGES_DIR/flatpak-packages.txt"; then
        log_info "No flatpak packages to install"
    else
        log_info "Installing Flatpak packages..."

        if ! command -v flatpak &> /dev/null; then
            log_info "Flatpak not installed. Installing flatpak..."
            sudo apt install -y flatpak 2>&1 | tee -a "$LOG_FILE"
            log_info "Adding Flathub repository..."
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>&1 | tee -a "$LOG_FILE"
        fi

        FAILED_FLATPAKS=()
        while IFS= read -r package; do
            [[ -z "$package" || "$package" =~ ^# ]] && continue

            log_info "Installing flatpak: $package"
            if flatpak install -y flathub "$package" >> "$LOG_FILE" 2>&1; then
                log_success "Installed flatpak: $package"
            else
                log_error "Failed to install flatpak: $package"
                FAILED_FLATPAKS+=("$package")
            fi
        done < "$PACKAGES_DIR/flatpak-packages.txt"

        if [ ${#FAILED_FLATPAKS[@]} -eq 0 ]; then
            log_success "All Flatpak packages installed successfully"
        else
            log_error "Failed to install ${#FAILED_FLATPAKS[@]} flatpaks:"
            printf '%s\n' "${FAILED_FLATPAKS[@]}" | tee -a "$LOG_FILE"
        fi
    fi
fi

# Install NPM global packages
if [ -f "$PACKAGES_DIR/npm-global.txt" ]; then
    if grep -q "npm not installed" "$PACKAGES_DIR/npm-global.txt"; then
        log_info "No npm global packages to install"
    else
        log_info "Installing NPM global packages..."

        if ! command -v npm &> /dev/null; then
            log_error "npm not found. Please install Node.js/npm first."
        else
            FAILED_NPM=()
            while IFS= read -r package; do
                [[ -z "$package" || "$package" =~ ^# ]] && continue

                log_info "Installing npm package: $package"
                if npm install -g "$package" >> "$LOG_FILE" 2>&1; then
                    log_success "Installed npm package: $package"
                else
                    log_error "Failed to install npm package: $package"
                    FAILED_NPM+=("$package")
                fi
            done < "$PACKAGES_DIR/npm-global.txt"

            if [ ${#FAILED_NPM[@]} -eq 0 ]; then
                log_success "All NPM packages installed successfully"
            else
                log_error "Failed to install ${#FAILED_NPM[@]} npm packages:"
                printf '%s\n' "${FAILED_NPM[@]}" | tee -a "$LOG_FILE"
            fi
        fi
    fi
fi

echo ""
echo "======================================"
echo "Package Installation Complete!"
echo "======================================"
echo ""
log_info "Full log available at: $LOG_FILE"
echo ""
