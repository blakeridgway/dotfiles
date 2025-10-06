#!/bin/bash

# 01-package-install.sh
# Installs system packages and Flatpak applications.
# Relies on DISTRO and PACKAGE_MANAGER being set by the caller.

echo "--- Starting Package Installation ---"

if [ -z "$DISTRO" ] || [ -z "$PACKAGE_MANAGER" ]; then
    echo "ERROR: DISTRO and PACKAGE_MANAGER must be set in the environment."
    exit 1
fi

# Define base package list
BASE_PACKAGE_LIST=(
    btop
    curl
    git
    gh
    fd-find
    flatpak
    jq
    python3
    python3-pip
    ripgrep
    virt-manager
    zsh
    wget
    unzip
)

# Distro-specific packages to add to the main list
DISTRO_SPECIFIC_PACKAGES=()
if [ "$PACKAGE_MANAGER" == "dnf" ]; then
    DISTRO_SPECIFIC_PACKAGES+=(
        "fontconfig-devel"  # for fc-cache
        "openssl-devel"     # for various compilations
        "util-linux-user"   # for chsh, if needed by OhMyZsh script
    )
elif [ "$PACKAGE_MANAGER" == "apt" ]; then
    DISTRO_SPECIFIC_PACKAGES+=(
        "libfontconfig-dev"
        "libssl-dev"
        "fd-find" # On Debian/Ubuntu, binary is fdfind, symlink to fd often needed
                  # Or user might prefer 'fd' package if available from other sources
    )
fi

# Combine package lists
PACKAGE_LIST=("${BASE_PACKAGE_LIST[@]}" "${DISTRO_SPECIFIC_PACKAGES[@]}")
PACKAGE_LIST=($(printf "%s\n" "${PACKAGE_LIST[@]}" | LC_ALL=C sort -u))


FLATPAK_LIST=(
    com.bitwarden.desktop
    com.discordapp.Discord
    com.github.tchx84.Flatseal
    com.jetbrains.Rider
    com.valvesoftware.Steam
    com.visualstudio.code
    net.davidotek.pupgui2
    net.veloren.airshipper
    org.signal.Signal
    org.videolan.VLC
)

echo "Installing System Packages..."
for package_name in "${PACKAGE_LIST[@]}"; do
    if [ "$PACKAGE_MANAGER" == "dnf" ]; then
        if ! rpm -q "$package_name" &>/dev/null; then
            echo "Installing $package_name (dnf)..."
            if sudo dnf install "$package_name" -y; then
                echo "$package_name has been installed."
            else
                echo "WARNING: Failed to install $package_name. It may not be available in the repositories."
            fi
        else
            echo "$package_name already installed."
        fi

    elif [ "$PACKAGE_MANAGER" == "apt" ]; then
        # For apt, check if package provides the command or is installed
        # dpkg-query is generally more reliable for checking installed status
        actual_package_name=$package_name
        if [ "$package_name" == "fd-find" ] && ! dpkg -s fd-find &>/dev/null ; then
            # On some newer Ubuntu/Debian, 'fd-find' might be the package,
            # but user might want 'fd' if it's a different source or a metapackage.
            # For now, we stick to fd-find.
            : # Keep actual_package_name as fd-find
        fi

        if ! dpkg-query -W -f='${Status}' "$actual_package_name" 2>/dev/null | grep -q "ok installed"; then
            echo "Installing $actual_package_name (apt)..."
            sudo apt install "$actual_package_name" -y
            echo "$actual_package_name has been installed."
        else
            echo "$actual_package_name already installed."
        fi
    fi
done

# Post-install for fd-find on Debian/Ubuntu (create symlink)
if [ "$PACKAGE_MANAGER" == "apt" ] && command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    if dpkg-query -W -f='${Status}' "fd-find" 2>/dev/null | grep -q "ok installed"; then
        echo "Creating symlink for fd from fdfind..."
        sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd 
    fi
fi


echo "Installing Flatpak Applications..."
if command -v flatpak &> /dev/null; then
    for flatpak_name in "${FLATPAK_LIST[@]}"; do
        if ! flatpak list --app | grep -q "$flatpak_name"; then
            echo "Installing Flatpak $flatpak_name..."
            flatpak install flathub "$flatpak_name" -y
            echo "$flatpak_name has been installed."
        else
            echo "Flatpak $flatpak_name already installed."
        fi
    done
else
    echo "WARNING: flatpak command not found. Skipping Flatpak app installation."
fi

echo "--- Package Installation Finished ---"

