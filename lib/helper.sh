# Shared helper functions for all scripts

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging variables
LOG_FILE="${LOG_FILE:-setup.log}"
VERBOSITY="${VERBOSITY:-1}"

# Initialize logging
init_logging() {
    touch "$LOG_FILE"
    echo "Setup started at $(date)" >> "$LOG_FILE"
}

# Log messages with timestamp
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Print to console based on verbosity
print_msg() {
    local level="$1"
    shift
    local message="$*"
    
    case "$level" in
        ERROR)
            echo -e "${RED}[ERROR]${NC} $message" >&2
            log "ERROR" "$message"
            ;;
        SUCCESS)
            echo -e "${GREEN}[✓]${NC} $message"
            log "INFO" "$message"
            ;;
        WARN)
            echo -e "${YELLOW}[⚠]${NC} $message"
            log "WARN" "$message"
            ;;
        INFO)
            if [ "$VERBOSITY" -ge 1 ]; then
                echo -e "${BLUE}[→]${NC} $message"
            fi
            log "INFO" "$message"
            ;;
        DEBUG)
            if [ "$VERBOSITY" -ge 2 ]; then
                echo -e "${BLUE}[DEBUG]${NC} $message"
            fi
            log "DEBUG" "$message"
            ;;
    esac
}

# Error handler
error_exit() {
    local message="$1"
    local line_no="${2:-unknown}"
    print_msg ERROR "Fatal error on line $line_no: $message"
    exit 1
}

# Trap errors
trap_error() {
    error_exit "Command failed" "$LINENO"
}

# Set up error trapping
setup_error_trapping() {
    trap trap_error ERR
    trap 'print_msg INFO "Setup interrupted"; exit 130' INT
}

# Check if running with sudo when needed
require_sudo() {
    if ! sudo -v &>/dev/null; then
        error_exit "This script requires sudo access"
    fi
}

# Check for required commands
require_command() {
    local cmd="$1"
    local package_manager="${2:-unknown}"
    
    if ! command -v "$cmd" &>/dev/null; then
        print_msg ERROR "Required command '$cmd' not found"
        if [ "$package_manager" != "unknown" ]; then
            print_msg INFO "Try installing with: $package_manager install $cmd"
        fi
        return 1
    fi
    return 0
}

# Check network connectivity
check_network() {
    if ! ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
        print_msg WARN "No internet connectivity detected"
        return 1
    fi
    return 0
}

# Check disk space (requires MB)
check_disk_space() {
    local required_mb="$1"
    local target_dir="${2:-.}"
    local available=$(df "$target_dir" | awk 'NR==2 {print $4}')
    
    if [ "$available" -lt "$((required_mb * 1024))" ]; then
        print_msg ERROR "Insufficient disk space. Required: ${required_mb}MB, Available: $((available / 1024))MB"
        return 1
    fi
    return 0
}

# Download file with retry logic
download_file() {
    local url="$1"
    local output="$2"
    local max_attempts=3
    local attempt=1
    
    print_msg INFO "Downloading from $url"
    
    while [ $attempt -le $max_attempts ]; do
        if curl -fsSL --max-time 30 "$url" -o "$output"; then
            print_msg SUCCESS "Download successful"
            return 0
        fi
        
        print_msg WARN "Download attempt $attempt failed, retrying..."
        attempt=$((attempt + 1))
        sleep 2
    done
    
    error_exit "Failed to download $url after $max_attempts attempts"
}

# Execute command (dry-run aware)
execute() {
    local description="$1"
    shift
    local cmd="$@"
    
    print_msg INFO "$description"
    print_msg DEBUG "Command: $cmd"
    
    if [ "$DRY_RUN" = true ]; then
        print_msg DEBUG "[DRY-RUN] Would execute: $cmd"
        return 0
    fi
    
    if eval "$cmd"; then
        print_msg SUCCESS "$description completed"
        return 0
    else
        print_msg ERROR "$description failed"
        return 1
    fi
}

# Confirm action (interactive mode)
confirm() {
    local prompt="$1"
    local default="${2:-y}"
    
    if [ "$INTERACTIVE" = false ]; then
        return 0
    fi
    
    local response
    read -p "$(echo -e ${BLUE}$prompt${NC}) (y/n) [$default]: " response
    response="${response:-$default}"
    
    [[ "$response" =~ ^[Yy]$ ]]
}

# Backup file if it exists
backup_file() {
    local file="$1"
    local backup_dir="${2:-.backups}"
    
    if [ -e "$file" ]; then
        mkdir -p "$backup_dir"
        local backup_name="$(basename "$file").backup.$(date +%s)"
        cp -r "$file" "$backup_dir/$backup_name"
        print_msg SUCCESS "Backed up $file to $backup_dir/$backup_name"
        return 0
    fi
    return 1
}

# Safe symlink with backup
safe_symlink() {
    local source="$1"
    local target="$2"
    local backup_dir="${3:-.backups}"
    
    if [ ! -e "$source" ]; then
        print_msg ERROR "Source file not found: $source"
        return 1
    fi
    
    # Backup existing file if it's not already a symlink to the same source
    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
            print_msg DEBUG "$target already symlinked correctly"
            return 0
        fi
        
        backup_file "$target" "$backup_dir"
    fi
    
    ln -sf "$source" "$target"
    print_msg SUCCESS "Symlinked $source -> $target"
}

# Detect Linux distro
detect_linux_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        echo "$DISTRIBUTOR_ID" | tr '[:upper:]' '[:lower:]'
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

# Get appropriate package manager
get_package_manager() {
    local distro="$1"
    
    case "$distro" in
        fedora|rhel|centos)
            echo "dnf"
            ;;
        debian|ubuntu|pop)
            echo "apt"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Install package (distro-aware)
install_package() {
    local package="$1"
    local package_manager="$2"
    
    print_msg INFO "Installing $package"
    
    if [ "$package_manager" = "dnf" ]; then
        if rpm -q "$package" &>/dev/null; then
            print_msg DEBUG "$package already installed"
            return 0
        fi
        execute "Installing $package via dnf" "sudo dnf install -y '$package'"
        
    elif [ "$package_manager" = "apt" ]; then
        if dpkg-query -W -f='\${Status}' "$package" 2>/dev/null | grep -q "ok installed"; then
            print_msg DEBUG "$package already installed"
            return 0
        fi
        execute "Installing $package via apt" "sudo apt install -y '$package'"
    else
        error_exit "Unknown package manager: $package_manager"
    fi
}

# Check if Flatpak app is installed
is_flatpak_installed() {
    local flatpak_id="$1"
    flatpak list --app 2>/dev/null | grep -q "$flatpak_id"
}

# Install Flatpak app
install_flatpak_app() {
    local app_id="$1"
    
    if ! command -v flatpak &>/dev/null; then
        print_msg WARN "Flatpak not installed, skipping $app_id"
        return 1
    fi
    
    if is_flatpak_installed "$app_id"; then
        print_msg DEBUG "Flatpak app $app_id already installed"
        return 0
    fi
    
    print_msg INFO "Installing Flatpak app $app_id"
    execute "Installing $app_id" "flatpak install flathub '$app_id' -y"
}

# Progress indicator
show_progress() {
    local current="$1"
    local total="$2"
    local description="$3"
    
    local percentage=$((current * 100 / total))
    echo -e "${BLUE}[$current/$total]${NC} $description ($percentage%)"
}

export -f print_msg log error_exit require_sudo require_command check_network
export -f check_disk_space download_file execute confirm backup_file safe_symlink
export -f detect_linux_distro get_package_manager install_package is_flatpak_installed
export -f install_flatpak_app show_progress init_logging setup_error_trapping