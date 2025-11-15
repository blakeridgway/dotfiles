#!/bin/bash

# Uninstall script - Removes installed components

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/helpers.sh"

setup_error_trapping
init_logging

print_msg INFO "=== Uninstall Script ==="
echo ""
echo "This script will uninstall components installed by the setup scripts."
echo ""

if ! confirm "Do you want to continue?"; then
    print_msg INFO "Uninstall cancelled"
    exit 0
fi

BACKUP_DIR="${SCRIPT_ROOT_DIR}/.backups"

# Restore dotfiles from backups
if [ -d "$BACKUP_DIR" ]; then
    print_msg INFO "Restoring dotfile backups..."
    for backup in "$BACKUP_DIR"/*.backup.*; do
        if [ -e "$backup" ]; then
            local original_name=$(basename "$backup" | sed 's/\.backup\..*//')
            local target="$HOME/.$original_name"
            execute "Restoring $original_name" "cp -r $backup $target"
        fi
    done
fi

# Uninstall development tools
print_msg INFO "Uninstalling development tools..."

if confirm "Uninstall Neovim?"; then
    execute "Removing Neovim" "sudo rm -rf /opt/nvim /opt/nvim-linux64 /usr/local/bin/nvim"
fi

if confirm "Uninstall Go?"; then
    execute "Removing Go" "sudo rm -rf /usr/local/go"
    print_msg INFO "Remove 'export PATH=\$PATH:/usr/local/go/bin' from ~/.bashrc and ~/.zshrc manually"
fi

if confirm "Uninstall Rust?"; then
    execute "Running Rust uninstaller" "rustup self uninstall -y" || true
    print_msg INFO "Remove 'source \$HOME/.cargo/env' from shell RC files manually"
fi

if confirm "Uninstall Starship?"; then
    execute "Removing Starship" "sudo rm -f /usr/local/bin/starship"
fi

if confirm "Uninstall Oh-My-Posh?"; then
    execute "Removing Oh-My-Posh" "sudo rm -f /usr/local/bin/oh-my-posh"
    execute "Removing Oh-My-Posh themes" "rm -rf $HOME/.poshthemes"
fi

# Uninstall Flatpak apps
if confirm "Uninstall Flatpak applications?"; then
    print_msg INFO "Uninstalling Flatpak apps..."
    flatpak list --app --columns=application | while read -r app; do
        if [ -n "$app" ] && [ "$app" != "Application ID" ]; then
            flatpak uninstall "$app" -y || true
        fi
    done
fi

print_msg SUCCESS "Uninstall completed"
print_msg INFO "Backups preserved in: $BACKUP_DIR"