#!/bin/bash

# Package Installation Script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/helpers.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../setup.conf"

setup_error_trapping
init_logging

print_msg INFO "=== Package Installation ==="

# Validate environment
if [ -z "$DISTRO" ] || [ -z "$PACKAGE_MANAGER" ]; then
    error_exit "DISTRO and PACKAGE_MANAGER must be set" "$LINENO"
fi

# Combine package lists
declare -a PACKAGES_TO_INSTALL=()
PACKAGES_TO_INSTALL+=("${COMMON_PACKAGES[@]}")

if [ "$PACKAGE_MANAGER" = "dnf" ]; then
    PACKAGES_TO_INSTALL+=("${DNF_PACKAGES[@]}")
elif [ "$PACKAGE_MANAGER" = "apt" ]; then
    PACKAGES_TO_INSTALL+=("${APT_PACKAGES[@]}")
fi

# Remove duplicates and sort
PACKAGES_TO_INSTALL=($(printf "%s\n" "${PACKAGES_TO_INSTALL[@]}" | LC_ALL=C sort -u))

# Install system packages
print_msg INFO "Installing ${#PACKAGES_TO_INSTALL[@]} system packages..."
local count=1
for package in "${PACKAGES_TO_INSTALL[@]}"; do
    show_progress "$count" "${#PACKAGES_TO_INSTALL[@]}" "Installing $package"
    if ! install_package "$package" "$PACKAGE_MANAGER"; then
        print_msg WARN "Failed to install $package"
    fi
    count=$((count + 1))
done

# Handle fd-find symlink for Debian/Ubuntu
if [ "$PACKAGE_MANAGER" = "apt" ]; then
    if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
        print_msg INFO "Creating fd symlink from fdfind..."
        execute "Creating fd symlink" "sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd"
    fi
fi

# Install Flatpak applications
if [ "$INSTALL_FLATPAK_APPS" = true ]; then
    print_msg INFO "Installing Flatpak applications..."
    if ! command -v flatpak &>/dev/null; then
        print_msg WARN "Flatpak not installed, skipping Flatpak apps"
    else
        local flatpak_count=1
        for app in "${FLATPAK_APPS[@]}"; do
            show_progress "$flatpak_count" "${#FLATPAK_APPS[@]}" "Installing Flatpak: $app"
            if ! install_flatpak_app "$app"; then
                print_msg WARN "Failed to install Flatpak app: $app"
            fi
            flatpak_count=$((flatpak_count + 1))
        done
    fi
else
    print_msg INFO "Skipping Flatpak app installation (disabled)"
fi

print_msg SUCCESS "Package installation completed"