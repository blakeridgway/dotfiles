#!/bin/bash

# System Preparation Script
# Updates system packages and sets up Flathub

set -euo pipefail

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/helpers.sh"

setup_error_trapping
init_logging

print_msg INFO "=== System Preparation ==="
print_msg INFO "Distribution: $DISTRO | Package Manager: $PACKAGE_MANAGER"

# Validate environment
if [ -z "$DISTRO" ] || [ -z "$PACKAGE_MANAGER" ]; then
    error_exit "DISTRO and PACKAGE_MANAGER must be set" "$LINENO"
fi

# Pre-flight checks
print_msg INFO "Running pre-flight checks..."
require_sudo || error_exit "Sudo access required" "$LINENO"
check_network || print_msg WARN "No internet connectivity"
check_disk_space 2000 / || print_msg WARN "Limited disk space"

# Update system packages
print_msg INFO "Updating system packages..."
if [ "$PACKAGE_MANAGER" = "dnf" ]; then
    print_msg DEBUG "Using DNF package manager"
    execute "DNF system update" "sudo dnf update -y"
    execute "DNF system upgrade" "sudo dnf upgrade -y"
    execute "DNF cleanup" "sudo dnf clean all"
    
elif [ "$PACKAGE_MANAGER" = "apt" ]; then
    print_msg DEBUG "Using APT package manager"
    execute "APT update package list" "sudo apt update"
    execute "APT upgrade packages" "sudo apt upgrade -y"
    execute "APT cleanup" "sudo apt autoclean && sudo apt autoremove -y"
else
    error_exit "Unknown package manager: $PACKAGE_MANAGER" "$LINENO"
fi

# Setup Flatpak
print_msg INFO "Setting up Flatpak and Flathub..."
if command -v flatpak &>/dev/null; then
    print_msg DEBUG "Flatpak found"
    execute "Adding Flathub repository" \
        "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
    print_msg SUCCESS "Flathub repository configured"
else
    print_msg WARN "Flatpak not found - will be installed in next step"
fi

print_msg SUCCESS "System preparation completed"