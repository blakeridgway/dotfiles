#!/bin/bash

# Main setup script
# Calls other scripts to perform post-installation tasks.

# --- Global Variables & Helper Functions ---
# SCRIPT_ROOT_DIR will be the directory where main-setup.sh is located
export SCRIPT_ROOT_DIR
SCRIPT_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
export SCRIPTS_DIR="${SCRIPT_ROOT_DIR}/scripts"

# Function to detect the Linux distribution
detect_linux_distro() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/lsb-release ]; then
        # shellcheck disable=SC1091
        . /etc/lsb-release
        echo "$DISTRIBUTOR_ID"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/redhat-release ]; then
        if grep -qi "fedora" /etc/redhat-release; then
            echo "fedora"
        elif grep -qi "centos" /etc/redhat-release; then
            echo "centos"
        elif grep -qi "red hat enterprise linux" /etc/redhat-release; then
            echo "rhel"
        else
            echo "redhat"
        fi
    else
        echo "unknown"
    fi
}

# Function to prompt user for yes/no
prompt_yes_no() {
    local prompt_text="$1"
    local response
    
    while true; do
        read -r -p "$prompt_text (y/n): " response
        case "$response" in
            [yY][eE][sS]|[yY]) return 0 ;;
            [nN][oO]|[nN]) return 1 ;;
            *) echo "Please answer y or n." ;;
        esac
    done
}

# Function to run a script if approved
run_script() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"
    
    if ! bash "$script_path"; then
        echo "ERROR: $script_name failed."
        return 1
    fi
    return 0
}

# Detect the Linux distribution and set package manager
export DISTRO
DISTRO=$(detect_linux_distro)

export PACKAGE_MANAGER
case "$DISTRO" in
    fedora|rhel|centos)
        PACKAGE_MANAGER="dnf"
        ;;
    debian|ubuntu|pop)
        PACKAGE_MANAGER="apt"
        ;;
    *)
        echo "Unsupported distribution: $DISTRO"
        exit 1
        ;;
esac

echo "Detected Distribution: $DISTRO"
echo "Using Package Manager: $PACKAGE_MANAGER"
echo "Script Root Directory: $SCRIPT_ROOT_DIR"
echo "--------------------------------------------------"
echo ""

# --- Prompt for Setup Options ---

echo "Select which setup tasks to run:"
echo ""

prompt_yes_no "Run system preparation (00-system-prep.sh)?" && RUN_SYSTEM_PREP=1 || RUN_SYSTEM_PREP=0
prompt_yes_no "Run package installation (01-package-install.sh)?" && RUN_PKG_INSTALL=1 || RUN_PKG_INSTALL=0
prompt_yes_no "Run dev tools setup (02-dev-tools-setup.sh)?" && RUN_DEV_TOOLS=1 || RUN_DEV_TOOLS=0

if [ "$DISTRO" == "fedora" ]; then
    prompt_yes_no "Run Fedora .NET setup (03-fedora-dotnet-setup.sh)?" && RUN_DOTNET=1 || RUN_DOTNET=0
else
    RUN_DOTNET=0
fi

prompt_yes_no "Run config symlinks setup (04-config-symlinks.sh)?" && RUN_CONFIG_SYMLINKS=1 || RUN_CONFIG_SYMLINKS=0

echo ""
echo "--------------------------------------------------"
echo ""

# --- Execute Setup Scripts ---

if [ $RUN_SYSTEM_PREP -eq 1 ]; then
    echo "Executing 00-system-prep.sh..."
    if ! run_script "${SCRIPTS_DIR}/00-system-prep.sh"; then
        echo "ERROR: 00-system-prep.sh failed."
        exit 1
    fi
    echo "--------------------------------------------------"
fi

if [ $RUN_PKG_INSTALL -eq 1 ]; then
    echo "Executing 01-package-install.sh..."
    if ! run_script "${SCRIPTS_DIR}/01-package-install.sh"; then
        echo "ERROR: 01-package-install.sh failed."
        exit 1
    fi
    echo "--------------------------------------------------"
fi

if [ $RUN_DEV_TOOLS -eq 1 ]; then
    echo "Executing 02-dev-tools-setup.sh..."
    if ! run_script "${SCRIPTS_DIR}/02-dev-tools-setup.sh"; then
        echo "ERROR: 02-dev-tools-setup.sh failed."
        exit 1
    fi
    echo "--------------------------------------------------"
fi

if [ $RUN_DOTNET -eq 1 ]; then
    echo "Executing 03-fedora-dotnet-setup.sh..."
    if ! run_script "${SCRIPTS_DIR}/03-fedora-dotnet-setup.sh"; then
        echo "ERROR: 03-fedora-dotnet-setup.sh failed."
    fi
    echo "--------------------------------------------------"
fi

if [ $RUN_CONFIG_SYMLINKS -eq 1 ]; then
    echo "Executing 04-config-symlinks.sh..."
    if ! run_script "${SCRIPTS_DIR}/04-config-symlinks.sh"; then
        echo "ERROR: 04-config-symlinks.sh failed."
    fi
    echo "--------------------------------------------------"
fi

echo ""
echo "#####################################"
echo "# Main setup script finished!       #"
echo "#####################################"
echo "Please review the output for any manual steps or errors."
echo "You may need to restart your terminal or log out/log in for all changes to take effect."

exit 0