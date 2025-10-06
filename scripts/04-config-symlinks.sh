#!/bin/bash

# 04-config-symlinks.sh
# Copies Starship config, configures Teams for Linux, and symlinks dotfiles.
# Relies on SCRIPT_ROOT_DIR being set by the caller.

echo "--- Starting Configuration and Symlinking ---"

if [ -z "$SCRIPT_ROOT_DIR" ]; then
    echo "ERROR: SCRIPT_ROOT_DIR must be set in the environment."
    exit 1
fi

# Starship Config File
STARSHIP_CONFIG_SOURCE="${SCRIPT_ROOT_DIR}/terminal/starship.toml"
STARSHIP_CONFIG_DEST_DIR="$HOME/.config"
STARSHIP_CONFIG_DEST_FILE="${STARSHIP_CONFIG_DEST_DIR}/starship.toml"

echo ""
echo "Setting up Starship configuration..."
if [ -f "$STARSHIP_CONFIG_SOURCE" ]; then
    mkdir -p "$STARSHIP_CONFIG_DEST_DIR"
    cp "$STARSHIP_CONFIG_SOURCE" "$STARSHIP_CONFIG_DEST_FILE"
    echo "Copied starship.toml to $STARSHIP_CONFIG_DEST_FILE"
else
    echo "WARNING: Starship config source not found: $STARSHIP_CONFIG_SOURCE. Skipping copy."
fi

#  Teams for Linux Configuration 
echo ""
echo "Setting up Teams for Linux (Community/Flatpak) configuration..."
TEAMS_FLATPAK_DIR="$HOME/.var/app/com.github.IsmaelMartinez.teams_for_linux"

# Only proceed if the application data directory exists
if [ -d "$TEAMS_FLATPAK_DIR" ]; then
    # Check for jq dependency
    if ! command -v jq &> /dev/null; then
        echo "WARNING: 'jq' is not installed. Skipping Teams for Linux config."
    else
        CONFIG_DIR="${TEAMS_FLATPAK_DIR}/config/teams-for-linux"
        CONFIG_FILE="${CONFIG_DIR}/config.json"

        # Ensure the target directory exists
        mkdir -p "$CONFIG_DIR"

        # Safely add/update the disableAutogain setting using jq
        # This handles a non-existent file gracefully by creating an empty JSON object
        cat "$CONFIG_FILE" 2>/dev/null || echo "{}" | jq '.disableAutogain = true' > "${CONFIG_FILE}.tmp"
        mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

        echo "Successfully configured 'disableAutogain: true' in $CONFIG_FILE"
    fi
else
    echo "Teams for Linux Flatpak directory not found. Skipping configuration."
fi

# Symlink files (keeping the original simple approach)

echo ""
echo "Symlinking dotfiles..."
FILES=('vimrc' 'vim' 'bashrc' 'zsh' 'agignore' 'gitconfig' 'gitignore' 'commit-conventions.txt' 'aliases.zsh')

for file in "${FILES[@]}"; do
    echo ""
    echo "Symlinking $file to $HOME"
    
    # Check if source file exists first
    if [ -e "${SCRIPT_ROOT_DIR}/${file}" ]; then
        ln -sf "${SCRIPT_ROOT_DIR}/${file}" "$HOME/.$file"
        if [ $? -eq 0 ]; then
            echo "${SCRIPT_ROOT_DIR}/${file} ~> $HOME/.$file"
        else
            echo "Install failed to symlink $file."
            exit 1
        fi
    else
        echo "WARNING: Source file not found: ${SCRIPT_ROOT_DIR}/${file}. Skipping."
    fi
done

echo ""
echo "--- Configuration and Symlinking Finished ---"