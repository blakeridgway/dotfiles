Perfect! Now let me create an enhanced README that incorporates all the improvements while maintaining your style and clarity:Perfect! Now I have all the context. Let me create an enhanced README that incorporates all the improvements while keeping your style:

```markdown
# Development Environment Setup

> A comprehensive, production-ready dotfiles and setup automation suite for Linux development machines.

## Overview

This is a collection of scripts and dotfiles for setting up a fresh Linux installation with all necessary development tools, configured shells, and optimized workflows. The system automatically detects your Linux distribution and configures everything appropriately.

### Key Features

✨ **Intelligent Setup**
- Automatic distribution detection (Fedora, Ubuntu, Debian, Pop! OS)
- Distro-aware package management (DNF, APT)
- Modular architecture for selective component installation
- Idempotent design (safe to run multiple times)

🛡️ **Reliability & Safety**
- Comprehensive error handling with detailed logging
- Automatic backups before making changes
- Dry-run mode to preview changes
- Health check verification system
- Uninstall capability for clean removal

🎯 **Developer Experience**
- Multiple verbosity levels for debugging
- Structured logging with timestamps
- Resume capability for interrupted setups
- Interactive and non-interactive modes
- Clear progress indicators

## Quick Start

### Clone the repository

```bash
git clone <your-dotfiles-repo> ~/dotfiles
cd ~/dotfiles
```

### Preview changes (recommended first step)

```bash
# See what would be installed without executing anything
./main-setup.sh --dry-run
```

### Run setup

```bash
# Standard setup with prompts
./main-setup.sh

# Non-interactive (for automation)
./main-setup.sh --non-interactive

# Verbose output for debugging
./main-setup.sh -vv

# Skip specific components
./main-setup.sh --skip-docker --skip-postgresql
```

## What Gets Installed

### System Foundation
- **Package Manager Updates:** System-wide package updates and security patches
- **Flathub Repository:** Sandboxed application deployment
- **System Utilities:** btop, curl, wget, ripgrep, fd-find, jq, zsh

### Development Tools

#### Languages & Runtimes
- **Rust** (via rustup) - Latest stable toolchain
- **Go** (latest from golang.org) - Complete installation with PATH setup
- **Python 3** with pip - For scripting and package management
- **.NET SDK** (Fedora only) - Full .NET development environment

#### Editors & IDEs
- **Neovim** (latest from GitHub) - Modern vim replacement with Lua support
- **Hack Nerd Font** - Terminal font with icon support
- **Visual Studio Code** (Flatpak) - Full IDE with extensions

#### Terminal Enhancement
- **Starship** - Cross-shell prompt with git integration
- **Oh-My-Posh** - Windows Terminal inspired prompt
- **Zsh** - Modern shell with better defaults
- **Git** with global configuration - Version control setup

### Platform-Specific (Fedora)

When running on Fedora, additional developer tools are installed:

- **PostgreSQL** - Full server installation with management tools
- **Docker** - Container engine with user group configuration
- **Docker Compose** - Multi-container orchestration
- **Development Headers** - Compilation tools (fontconfig-devel, openssl-devel)

### Optional Applications (Flatpak)

Easy-to-install sandboxed applications:

- **Bitwarden** - Password management
- **Flatseal** - Flatpak permissions management
- **Discord** - Communication
- **Rider** - JetBrains .NET IDE
- **Steam** - Gaming platform
- **ProtonUp-Qt** - Proton version manager
- **VLC** - Media player
- **Signal** - Encrypted messaging

## Configuration

### setup.conf

Customize your installation by editing `setup.conf`:

```bash
# Enable/disable specific tools
INSTALL_NEOVIM=true
INSTALL_GO=true
INSTALL_RUST=true
INSTALL_OMP=true
INSTALL_STARSHIP=true
INSTALL_FLATPAK_APPS=true

# Fedora-specific components
INSTALL_DOCKER=true
INSTALL_POSTGRESQL=true
INSTALL_DOTNET=true

# Verbosity level (0=quiet, 1=normal, 2=verbose)
VERBOSITY=1
```

## Command-Line Options

```bash
Usage: ./main-setup.sh [OPTIONS]

Setup Options:
  --dry-run              Preview changes without executing
  --non-interactive      Skip all prompts (for automation)
  -v, --verbose          Increase verbosity (repeatable: -vv, -vvv)
  -q, --quiet            Decrease verbosity
  
Component Control:
  --skip-docker          Skip Docker installation
  --skip-postgresql      Skip PostgreSQL installation
  --skip-dotnet          Skip .NET installation
  --skip-flatpak         Skip Flatpak applications
  
Debugging:
  --resume-from SCRIPT   Resume from specific script (e.g., 02-dev-tools-setup.sh)
  -h, --help             Show this help message
  --version              Show version information

Examples:
  # Preview what would happen
  ./main-setup.sh --dry-run

  # Standard setup with confirmations
  ./main-setup.sh

  # Fully automated setup
  ./main-setup.sh --non-interactive

  # Verbose debugging
  ./main-setup.sh -vv --skip-flatpak

  # Resume after interruption
  ./main-setup.sh --resume-from 02-dev-tools-setup.sh
```

## Setup Scripts

The installation is organized into modular scripts that can be run independently:

### 00-system-prep.sh
Prepares the system for installation:
- Updates all system packages
- Configures Flathub repository
- Validates system requirements

### 01-package-install.sh
Installs system packages and Flatpak applications:
- Common development packages
- Distro-specific packages
- Flatpak applications
- Handles package name variations across distributions

### 02-dev-tools-setup.sh
Installs modern development tools:
- Neovim with Python support (pynvim)
- Nerd fonts for terminal icons
- Go with automatic PATH setup
- Rust toolchain via rustup
- Oh-My-Posh terminal prompt
- Starship prompt
- Comprehensive error handling for each tool

### 03-fedora-dotnet-setup.sh
**Fedora-specific** .NET development environment:
- PostgreSQL server initialization
- Docker daemon setup with user permissions
- .NET SDK installation
- Automated database initialization
- Service enablement and startup

### 04-config-symlinks.sh
Applies your dotfiles configuration:
- Symlinks dotfiles to home directory
- Backup existing configurations
- Starship prompt configuration
- Teams for Linux configuration (if installed)

## Dotfiles

Configuration files that will be symlinked to your home directory:

| File | Purpose |
|------|---------|
| `.vimrc` & `.vim/` | Vim/Neovim configuration |
| `.zshrc` & `.zsh/` | Zsh shell configuration |
| `.bashrc` | Bash shell configuration |
| `.gitconfig` | Git configuration **[requires your credentials]** |
| `.gitignore` | Global Git ignore patterns |
| `.agignore` | Silver Searcher ignore patterns |
| `.aliases.zsh` | Zsh-specific aliases |
| `.aliases.bash` | Bash-specific aliases |
| `commit-conventions.txt` | Git commit message template |

### Important: Git Configuration

**Before running setup**, edit `gitconfig` and replace the placeholder credentials:

```bash
nano gitconfig  # or your preferred editor
# Update:
# [user]
#     name = Your Name
#     email = your.email@example.com
```

## Post-Installation

After setup completes, follow these steps:

### 1. Verify Installation

```bash
# Run health check
bash lib/health-check.sh

# Review the checklist
cat POST-SETUP-CHECKLIST.md
```

### 2. Shell Configuration

```bash
# Configure Git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Generate SSH key
ssh-keygen -t ed25519 -C "your.email@example.com"
```

### 3. Terminal Setup

- **Font:** Set your terminal to use "Hack Nerd Font"
- **Theme:** Terminal theme configuration depends on your terminal emulator
- **Reload:** Log out and log back in for environment changes to take effect

### 4. For Docker (Fedora)

```bash
# IMPORTANT: Log out and log back in after setup
# This allows docker group permissions to take effect

# Verify Docker works
docker run hello-world

# Start Docker service (if not already started)
sudo systemctl start docker
sudo systemctl enable docker
```

### 5. For VS Code

Install recommended extensions:
- **C# Dev Kit** - C# development
- **GitLens** - Enhanced Git integration
- **Prettier** - Code formatter
- **NuGet Package Manager** - .NET package management

### 6. Restore from Backups

If needed, restore from automatic backups:

```bash
# List available backups
ls -la .backups/

# Restore a file
cp .backups/vimrc.backup.1234567890 ~/.vimrc
```

## Logging & Debugging

### View Logs

```bash
# Full setup log
cat setup.log

# Follow logs in real-time
tail -f setup.log

# Check for errors
grep -i error setup.log

# Check for warnings
grep -i warn setup.log
```

### Debug Information

- All operations are logged to `setup.log` with timestamps
- Each script creates detailed debug output
- State tracking in `.setup-state` file
- Backups stored in `.backups/` directory

### Verbosity Levels

- **Quiet (-q):** Only errors
- **Normal (default):** Basic progress information
- **Verbose (-v):** Detailed operation information
- **Very Verbose (-vv):** Debug-level output with command details

## Troubleshooting

### Script Failed Mid-Way?

Resume from where it left off:

```bash
# Check what script failed
grep ERROR setup.log

# Resume from that script
./main-setup.sh --resume-from 02-dev-tools-setup.sh
```

### Network Issues?

```bash
# Check internet connectivity
ping -c 1 8.8.8.8

# Retry downloads manually if needed
```

### Package Not Found?

```bash
# Check what packages are available
dnf search package-name        # For Fedora
apt-cache search package-name  # For Ubuntu/Debian
```

### Permission Denied?

```bash
# Ensure sudo works without password (for automation)
sudo -v

# Check sudo access
sudo ls /
```

## Supported Distributions

| Distribution | Status | Notes |
|-------------|--------|-------|
| **Fedora 40+** | ✅ Full | All features including .NET |
| **Fedora 39** | ✅ Full | All features |
| **Ubuntu 24.04** | ✅ Full | Core tools, no .NET |
| **Ubuntu 22.04** | ✅ Full | Core tools, no .NET |
| **Debian 12** | ✅ Full | Core tools, no .NET |
| **Debian 11** | ✅ Full | Core tools, no .NET |
| **Pop! OS** | ✅ Full | Ubuntu-based, all features |

## Uninstall

To remove all installed components and restore backups:

```bash
bash lib/uninstall.sh
```

This script will:
- Remove development tools and languages
- Restore dotfile backups
- Preserve manual configurations
- Ask for confirmation before each removal

## Health Check

Verify that all components installed successfully:

```bash
bash lib/health-check.sh
```

Output includes:
- ✓ Installation verification
- ✓ Configuration file checks
- ✓ Service status (Docker, PostgreSQL)
- ✓ Version information
- ✓ Summary of passed/failed checks

## Architecture & Design

### Error Handling

- All scripts use `set -euo pipefail` for strict error checking
- Trap handlers catch errors and provide detailed context
- Non-fatal errors are clearly marked as warnings
- Script exits with non-zero on any critical error

### Logging System

- Structured logging with timestamps and severity levels
- Both file and console output (with colors)
- Separate error stream for proper redirection
- Log levels: DEBUG, INFO, WARN, ERROR, FATAL

### Safety Features

- All destructive operations backed up first
- Temporary files (.tmp suffix) during operations
- Symlink verification after creation
- Network connectivity checks before downloads
- Disk space validation before large installations

### Modular Design

- Scripts source helper functions from `lib/helpers.sh`
- Configuration centralized in `setup.conf`
- Independent package managers abstraction
- Easy to extend with additional tools

## Advanced Usage

### Automation & CI/CD

```bash
# Fully automated setup for deployment
./main-setup.sh --non-interactive --skip-flatpak

# Capture all output
./main-setup.sh 2>&1 | tee setup-run-$(date +%s).log

# Check result
echo $?  # 0 = success, non-zero = failure
```

### Development

```bash
# Run with maximum debug output
VERBOSITY=2 ./main-setup.sh -vv

# View all commands being executed
bash -x ./main-setup.sh

# Resume from specific point
./main-setup.sh --resume-from 02-dev-tools-setup.sh
```

### Customization

```bash
# Create your own config
cp setup.conf setup.custom.conf
# Edit setup.custom.conf with your preferences
# Source it before running
source setup.custom.conf && ./main-setup.sh
```

## Contributing

Found an issue or want to add support for a new tool? Contributions welcome!

## License

See LICENSE file for details.

## Acknowledgments

- Script structure inspired by production deployment systems
- Error handling patterns from advanced bash best practices
- Component selection based on modern development workflows

---

**Last Updated:** November 2025  
**Current Version:** 2.0 (Enhanced with comprehensive error handling, logging, and safety features)