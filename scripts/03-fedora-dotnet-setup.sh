#!/bin/bash

# Fedora .NET Development Environment Setup

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/helpers.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../setup.conf"

setup_error_trapping
init_logging

if [ "$DISTRO" != "fedora" ]; then
    print_msg WARN "This script is designed for Fedora. Skipping."
    exit 0
fi

print_msg INFO "=== Fedora .NET Development Environment Setup ==="

FEDORA_VERSION=$(rpm -E %fedora)
print_msg INFO "Fedora Version: $FEDORA_VERSION"

# Helper function to check Fedora version support
check_fedora_dotnet_support() {
    local version="$1"
    # Microsoft typically supports current and previous 2 Fedora versions
    local min_supported=$((FEDORA_VERSION - 2))
    
    if [ "$version" -lt "$min_supported" ]; then
        print_msg WARN "Fedora $version may not be supported by Microsoft .NET packages"
        return 1
    fi
    return 0
}

check_fedora_dotnet_support "$FEDORA_VERSION"

# Install Fedora-specific packages
if [ "$INSTALL_POSTGRESQL" = true ] || [ "$INSTALL_DOCKER" = true ] || [ "$INSTALL_DOTNET" = true ]; then
    print_msg INFO "Installing Fedora-specific development packages..."
    
    declare -a fedora_packages=()
    
    if [ "$INSTALL_POSTGRESQL" = true ]; then
        fedora_packages+=("postgresql-server" "postgresql-contrib")
    fi
    
    if [ "$INSTALL_DOCKER" = true ]; then
        fedora_packages+=("moby-engine" "docker-compose")
    fi
    
    for package in "${fedora_packages[@]}"; do
        if ! install_package "$package" "dnf"; then
            print_msg WARN "Failed to install $package"
        fi
    done
fi

# .NET Setup
if [ "$INSTALL_DOTNET" = true ]; then
    print_msg INFO "Setting up .NET Development Environment..."
    
    # Use Fedora native .NET packages (recommended over Microsoft repo)
    if rpm -q "dotnet-sdk-9.0" &>/dev/null; then
        print_msg SUCCESS ".NET SDK already installed"
    else
        print_msg INFO "Installing .NET SDK from Fedora repositories..."
        
        # Try .NET 9 first, then 8
        for sdk_version in "9.0" "8.0"; do
            if execute "Installing dotnet-sdk-${sdk_version}" "sudo dnf install -y dotnet-sdk-${sdk_version}"; then
                print_msg SUCCESS ".NET SDK $sdk_version installed"
                break
            fi
        done
    fi
    
    # Verify installation
    if command -v dotnet &>/dev/null; then
        print_msg SUCCESS "Dotnet verification:"
        print_msg DEBUG "$(dotnet --version)"
    fi
fi

# PostgreSQL Setup
if [ "$INSTALL_POSTGRESQL" = true ]; then
    print_msg INFO "Setting up PostgreSQL..."
    
    # Initialize database if needed
    if ! sudo systemctl is-active --quiet postgresql; then
        print_msg INFO "Initializing PostgreSQL database..."
        if command -v postgresql-setup &>/dev/null; then
            execute "Initializing PostgreSQL" "sudo postgresql-setup --initdb" || true
        fi
    fi
    
    # Enable and start service
    execute "Enabling PostgreSQL service" "sudo systemctl enable postgresql"
    execute "Starting PostgreSQL service" "sudo systemctl start postgresql"
    
    if sudo systemctl is-active --quiet postgresql; then
        print_msg SUCCESS "PostgreSQL is running"
    fi
fi

# Docker Setup
if [ "$INSTALL_DOCKER" = true ]; then
    print_msg INFO "Setting up Docker..."
    
    execute "Enabling Docker service" "sudo systemctl enable docker"
    execute "Starting Docker service" "sudo systemctl start docker"
    
    # Add user to docker group
    if ! groups "$USER" | grep -q docker; then
        execute "Adding user to docker group" "sudo usermod -aG docker $USER"
        print_msg WARN "User added to docker group - you must log out and log back in"
    else
        print_msg SUCCESS "User already in docker group"
    fi
fi

print_msg SUCCESS "Fedora .NET setup completed"