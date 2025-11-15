#!/bin/bash

# Configuration and Symlinks Setup

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/helpers.sh"

setup_error_trapping
init_logging

if [ -z "$SCRIPT_ROOT_DIR" ]; then
    error_exit "SCRIPT_ROOT_DIR must be set" "$LINENO"
fi

print_msg INFO "=== Configuration and Symlinks Setup ==="

BACKUP_DIR="${SCRIPT_ROOT_DIR}/.backups"
mkdir -p "$BACKUP_DIR"

# Starship Configuration
print_msg INFO "Setting up Starship configuration..."
STARSHIP_CONFIG_SOURCE="${SCRIPT_ROOT_DIR}/terminal/starship.toml"
STARSHIP_CONFIG_DEST="$HOME/.config/starship.toml"

if [ -f "$STARSHIP_CONFIG_SOURCE" ]; then
    mkdir -p "$HOME/.config"
    backup_file "$STARSHIP_CONFIG_DEST" "$BACKUP_DIR" || true
    execute "Copying Starship config" "cp $STARSHIP_CONFIG_SOURCE $STARSHIP_CONFIG_DEST"
else
    print_msg WARN "Starship config not found: $STARSHIP_CONFIG_SOURCE"
fi

# Teams for Linux Configuration
print_msg INFO "Setting up Teams for Linux configuration..."
TEAMS_FLATPAK_DIR="$HOME/.var/app/com.github.IsmaelMartinez.teams_for_linux"

if [ -d "$TEAMS_FLATPAK_DIR" ]; then
    if ! command -v jq &>/dev/null; then
        print_msg WARN "jq not installed, skipping Teams config"
    else
        CONFIG_DIR="${TEAMS_FLATPAK_DIR}/config/teams-for-linux"
        CONFIG_FILE="${CONFIG_DIR}/config.json"
        
        mkdir -p "$CONFIG_DIR"
        
        print_msg INFO "Configuring Teams auto-gain setting..."
        # Safely update JSON with jq
        if [ -f "$CONFIG_FILE" ]; then
            backup_file "$CONFIG_FILE" "$BACKUP_DIR"
        fi
        
        jq '.disableAutogain = true' "${CONFIG_FILE:--}" > "${CONFIG_FILE}.tmp" 2>/dev/null || echo '{"disableAutogain": true}' > "${CONFIG_FILE}.tmp"
        mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
        
        print_msg SUCCESS "Teams configuration updated"
    fi
else
    print_msg DEBUG "Teams for Linux not found (expected if not installed)"
fi

# Dotfiles Symlinking
print_msg INFO "Symlinking dotfiles..."

declare -a DOTFILES=('vimrc' 'vim' 'bashrc' 'zsh' 'agignore' 'gitconfig' 'gitignore' 'commit-conventions.txt' 'aliases.zsh' 'aliases.bash')

for dotfile in "${DOTFILES[@]}"; do
    SOURCE="${SCRIPT_ROOT_DIR}/${dotfile}"
    TARGET="$HOME/.$dotfile"
    
    if [ -e "$SOURCE" ]; then
        safe_symlink "$SOURCE" "$TARGET" "$BACKUP_DIR"
    else
        print_msg DEBUG "Source not found: $SOURCE (skipping)"
    fi
done

# Add additional config symlinks if they exist
if [ -f "${SCRIPT_ROOT_DIR}/terminal/starship.toml" ]; then
    safe_symlink "${SCRIPT_ROOT_DIR}/terminal/starship.toml" "$HOME/.config/starship.toml" "$BACKUP_DIR"
fi

print_msg SUCCESS "Configuration and symlinks setup completed"
print_msg INFO "Backups saved to: $BACKUP_DIR"