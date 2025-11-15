#!/bin/bash

# Development Tools Setup Script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/helpers.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../setup.conf"

setup_error_trapping
init_logging

print_msg INFO "=== Development Tools Setup ==="

# Detect OS and architecture
OS="$(uname | tr '[:upper:]' '[:lower:]')"
ARCH_RAW="$(uname -m)"
case "${ARCH_RAW}" in
    x86_64) ARCH=amd64 ;;
    aarch64|arm64) ARCH=arm64 ;;
    *) error_exit "Unsupported architecture: ${ARCH_RAW}" "$LINENO" ;;
esac

print_msg DEBUG "OS: $OS | Architecture: $ARCH"

# Helper to add to shell RC files safely
add_to_rc() {
    local rcfile="$1"
    local snippet="$2"
    
    if [ ! -f "$rcfile" ]; then
        print_msg DEBUG "$rcfile not found, creating..."
        touch "$rcfile"
    fi
    
    if ! grep -qxF "${snippet}" "${rcfile}"; then
        echo "" >> "${rcfile}"
        echo "# Added by development-tools-setup.sh" >> "${rcfile}"
        echo "${snippet}" >> "${rcfile}"
        print_msg SUCCESS "Updated $rcfile"
    fi
}

# Neovim Setup
if [ "$INSTALL_NEOVIM" = true ]; then
    print_msg INFO "Setting up Neovim..."
    if command -v nvim &>/dev/null; then
        local nvim_version
        nvim_version=$(nvim --version | head -n1)
        print_msg SUCCESS "Neovim already installed: $nvim_version"
    else
        print_msg INFO "Installing Neovim from latest release..."
        check_disk_space 500 /opt || error_exit "Insufficient disk space for Neovim" "$LINENO"
        
        local temp_dir
        temp_dir=$(mktemp -d)
        trap "rm -rf $temp_dir" EXIT
        
        download_file "https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz" \
            "${temp_dir}/nvim-linux64.tar.gz"
        
        execute "Installing Neovim to /opt" "sudo rm -rf /opt/nvim && sudo tar -C /opt -xzf ${temp_dir}/nvim-linux64.tar.gz"
        execute "Creating nvim symlink" "sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim"
        print_msg SUCCESS "Neovim installed"
    fi
    
    # Install pynvim
    print_msg INFO "Installing pynvim for Neovim Python support..."
    if /usr/bin/python3 -m pip show pynvim &>/dev/null; then
        print_msg SUCCESS "pynvim already installed"
    else
        execute "Installing pynvim" "/usr/bin/python3 -m pip install --user pynvim"
    fi
fi

# Nerd Font Installation
print_msg INFO "Setting up Hack Nerd Font..."
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

if fc-list | grep -qi "Hack Nerd Font"; then
    print_msg SUCCESS "Hack Nerd Font already installed"
else
    print_msg INFO "Installing Hack Nerd Font..."
    check_disk_space 100 "$HOME" || error_exit "Insufficient disk space for fonts" "$LINENO"
    
    local temp_font_dir
    temp_font_dir=$(mktemp -d)
    trap "rm -rf $temp_font_dir" EXIT
    
    download_file "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERDFONT_VERSION}/${NERDFONT_NAME}.zip" \
        "${temp_font_dir}/${NERDFONT_NAME}.zip"
    
    execute "Extracting fonts" "unzip -q ${temp_font_dir}/${NERDFONT_NAME}.zip -d ${temp_font_dir}/"
    execute "Copying font files" "find ${temp_font_dir} -maxdepth 1 \\( -name '*.ttf' -o -name '*.otf' \\) -exec cp {} $FONT_DIR/ \\;"
    execute "Updating font cache" "fc-cache -f -v"
    print_msg SUCCESS "Hack Nerd Font installed"
fi

# Go Installation
if [ "$INSTALL_GO" = true ]; then
    print_msg INFO "Setting up Go..."
    if ! command -v go &>/dev/null; then
        print_msg INFO "Installing Go..."
        check_disk_space 500 /usr/local || error_exit "Insufficient disk space for Go" "$LINENO"
        
        local latest_go
        latest_go=$(curl -fsSL https://go.dev/VERSION?m=text)
        local go_version="${latest_go#go}"
        local tar_file="go${go_version}.${OS}-${ARCH}.tar.gz"
        local dl_url="https://go.dev/dl/${tar_file}"
        
        print_msg INFO "Downloading Go $latest_go..."
        
        local temp_go_dir
        temp_go_dir=$(mktemp -d)
        trap "rm -rf $temp_go_dir" EXIT
        
        download_file "$dl_url" "${temp_go_dir}/${tar_file}"
        execute "Installing Go" "sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf ${temp_go_dir}/${tar_file}"
        
        # Add to PATH
        for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
            add_to_rc "$rc" 'export PATH=$PATH:/usr/local/go/bin'
        done
        
        print_msg SUCCESS "Go $latest_go installed"
    else
        local installed_go
        installed_go=$(go version | awk '{print $3}')
        print_msg SUCCESS "Go already installed: $installed_go"
    fi
fi

# Oh-My-Posh Installation
if [ "$INSTALL_OMP" = true ]; then
    print_msg INFO "Setting up Oh-My-Posh..."
    if ! command -v oh-my-posh &>/dev/null; then
        print_msg INFO "Installing Oh-My-Posh..."
        
        local bin_url="https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-${OS}-${ARCH}"
        local temp_bin
        temp_bin=$(mktemp)
        trap "rm -f $temp_bin" EXIT
        
        download_file "$bin_url" "$temp_bin"
        execute "Installing oh-my-posh" "sudo install -m755 $temp_bin /usr/local/bin/oh-my-posh"
        
        # Download theme
        mkdir -p "$HOME/.poshthemes"
        local theme_url="https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/jandedobbeleer.omp.json"
        download_file "$theme_url" "$HOME/.poshthemes/jandedobbeleer.omp.json"
        
        print_msg SUCCESS "Oh-My-Posh installed"
    else
        print_msg SUCCESS "Oh-My-Posh already installed: $(oh-my-posh --version | head -n1)"
    fi
fi

# Rust Installation
if [ "$INSTALL_RUST" = true ]; then
    print_msg INFO "Setting up Rust..."
    if ! command -v rustc &>/dev/null; then
        print_msg INFO "Installing Rust via rustup..."
        check_network || error_exit "Internet required for Rust installation" "$LINENO"
        
        execute "Running rustup installer" \
            "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path"
        
        # Add to PATH
        for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
            add_to_rc "$rc" 'source "$HOME/.cargo/env"'
        done
        
        print_msg SUCCESS "Rust installed via rustup"
    else
        print_msg SUCCESS "Rust already installed: $(rustc --version)"
    fi
fi

# Starship Installation
if [ "$INSTALL_STARSHIP" = true ]; then
    print_msg INFO "Setting up Starship..."
    if ! command -v starship &>/dev/null; then
        print_msg INFO "Installing Starship..."
        check_network || error_exit "Internet required for Starship installation" "$LINENO"
        
        execute "Running starship installer" \
            "curl -sS https://starship.rs/install.sh | sh -s -- -y"
        
        print_msg SUCCESS "Starship installed"
    else
        print_msg SUCCESS "Starship already installed: $(starship --version)"
    fi
fi

print_msg SUCCESS "Development tools setup completed"