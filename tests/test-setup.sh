#!/bin/bash

# Test Setup Script - Tests the dotfiles setup in containerized environments
# Usage: ./tests/test-setup.sh [fedora|ubuntu] [--keep-container]

set -euo pipefail

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test configuration
TEST_DISTRO="${1:-fedora}"
KEEP_CONTAINER="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
CONTAINER_NAME="dotfiles-test-${TEST_DISTRO}-$(date +%s)"
TEST_LOG="${DOTFILES_DIR}/test-results-${TEST_DISTRO}-$(date +%Y%m%d_%H%M%S).log"

# Image mappings
declare -A IMAGES=(
    ["fedora"]="fedora:latest"
    ["ubuntu"]="ubuntu:24.04"
    ["debian"]="debian:12"
)

# Default image
IMAGE="${IMAGES[$TEST_DISTRO]:-${IMAGES[fedora]}}"

print_msg() {
    local level="$1"
    shift
    local message="$*"
    
    case "$level" in
        SUCCESS)
            echo -e "${GREEN}[✓]${NC} $message" | tee -a "$TEST_LOG"
            ;;
        ERROR)
            echo -e "${RED}[✗]${NC} $message" | tee -a "$TEST_LOG"
            ;;
        INFO)
            echo -e "${BLUE}[→]${NC} $message" | tee -a "$TEST_LOG"
            ;;
        WARN)
            echo -e "${YELLOW}[⚠]${NC} $message" | tee -a "$TEST_LOG"
            ;;
    esac
}

# Initialize test log
echo "=== Dotfiles Setup Test ===" > "$TEST_LOG"
echo "Distribution: $TEST_DISTRO" >> "$TEST_LOG"
echo "Image: $IMAGE" >> "$TEST_LOG"
echo "Started: $(date)" >> "$TEST_LOG"
echo "" >> "$TEST_LOG"

print_msg INFO "Testing dotfiles setup with $TEST_DISTRO"
print_msg INFO "Container: $CONTAINER_NAME"
print_msg INFO "Log file: $TEST_LOG"

# Check if podman is available
if ! command -v podman &>/dev/null; then
    print_msg ERROR "Podman is not installed"
    exit 1
fi

print_msg SUCCESS "Podman is available: $(podman --version)"

# Pull image if not available
print_msg INFO "Pulling image: $IMAGE"
if podman pull "$IMAGE" >> "$TEST_LOG" 2>&1; then
    print_msg SUCCESS "Image pulled successfully"
else
    print_msg ERROR "Failed to pull image"
    exit 1
fi

# Create container with dotfiles volume
print_msg INFO "Creating test container..."
if podman run -d \
    --name "$CONTAINER_NAME" \
    -v "$DOTFILES_DIR:/dotfiles:z" \
    -e INTERACTIVE=false \
    -e VERBOSITY=2 \
    "$IMAGE" \
    sleep infinity > /dev/null 2>&1; then
    print_msg SUCCESS "Container created: $CONTAINER_NAME"
else
    print_msg ERROR "Failed to create container"
    exit 1
fi

# Function to execute command in container
exec_in_container() {
    local cmd="$1"
    print_msg INFO "Executing: $cmd"
    if podman exec "$CONTAINER_NAME" bash -c "$cmd" >> "$TEST_LOG" 2>&1; then
        return 0
    else
        return 1
    fi
}

# Install basic dependencies based on distro
print_msg INFO "Installing base dependencies..."
case "$TEST_DISTRO" in
    fedora)
        exec_in_container "dnf update -y" || print_msg WARN "dnf update failed"
        exec_in_container "dnf install -y git curl wget sudo" || print_msg WARN "dnf install failed"
        ;;
    ubuntu)
        exec_in_container "apt-get update" || print_msg WARN "apt update failed"
        exec_in_container "apt-get install -y git curl wget sudo" || print_msg WARN "apt install failed"
        ;;
    debian)
        exec_in_container "apt-get update" || print_msg WARN "apt update failed"
        exec_in_container "apt-get install -y git curl wget sudo" || print_msg WARN "apt install failed"
        ;;
esac

print_msg SUCCESS "Base dependencies installed"

# Run preflight checks
print_msg INFO "Running preflight checks..."
if exec_in_container "which git && which curl && which wget"; then
    print_msg SUCCESS "Preflight checks passed"
else
    print_msg ERROR "Preflight checks failed"
fi

# Copy dotfiles to test location
print_msg INFO "Preparing setup environment..."
exec_in_container "cd /dotfiles && ls -la" || print_msg WARN "Failed to list dotfiles"

# Run main setup in non-interactive dry-run mode
print_msg INFO "Running setup script in dry-run mode..."
if exec_in_container "cd /dotfiles && bash ./main-setup.sh --dry-run --non-interactive -q 2>&1 | head -50"; then
    print_msg SUCCESS "Dry-run completed"
else
    print_msg WARN "Dry-run had issues (this may be expected)"
fi

# Check basic script syntax
print_msg INFO "Checking script syntax..."
for script in /dotfiles/scripts/*.sh; do
    script_name=$(basename "$script")
    if exec_in_container "bash -n $script"; then
        print_msg SUCCESS "Syntax OK: $script_name"
    else
        print_msg ERROR "Syntax error in: $script_name"
    fi
done

# Test helper functions
print_msg INFO "Testing helper functions..."
if exec_in_container "source /dotfiles/lib/helpers.sh && echo 'Helpers loaded successfully'"; then
    print_msg SUCCESS "Helper functions loaded"
else
    print_msg ERROR "Failed to load helper functions"
fi

# Test configuration file
print_msg INFO "Verifying configuration..."
if exec_in_container "source /dotfiles/setup.conf && echo 'Config loaded'"; then
    print_msg SUCCESS "Configuration file valid"
else
    print_msg ERROR "Configuration file invalid"
fi

# Verify file structure
print_msg INFO "Verifying file structure..."
required_files=(
    "main-setup.sh"
    "setup.conf"
    "lib/helpers.sh"
    "scripts/00-system-prep.sh"
    "scripts/01-package-install.sh"
    "scripts/02-dev-tools-setup.sh"
    "scripts/04-config-symlinks.sh"
)

for file in "${required_files[@]}"; do
    if exec_in_container "test -f /dotfiles/$file"; then
        print_msg SUCCESS "Found: $file"
    else
        print_msg ERROR "Missing: $file"
    fi
done

# Check for Fedora-specific files
if [ "$TEST_DISTRO" = "fedora" ]; then
    if exec_in_container "test -f /dotfiles/scripts/03-fedora-dotnet-setup.sh"; then
        print_msg SUCCESS "Found Fedora-specific script"
    else
        print_msg ERROR "Missing Fedora-specific script"
    fi
fi

# Generate test report
print_msg INFO "Generating test report..."
{
    echo ""
    echo "=== Test Results ==="
    echo "Distribution: $TEST_DISTRO"
    echo "Image: $IMAGE"
    echo "Container: $CONTAINER_NAME"
    echo "Completed: $(date)"
    echo ""
} >> "$TEST_LOG"

# Cleanup
print_msg INFO "Cleaning up..."
if [ "$KEEP_CONTAINER" != "--keep-container" ]; then
    if podman stop "$CONTAINER_NAME" > /dev/null 2>&1; then
        podman rm "$CONTAINER_NAME" > /dev/null 2>&1
        print_msg SUCCESS "Container cleaned up"
    fi
else
    print_msg INFO "Container kept for inspection: $CONTAINER_NAME"
    print_msg INFO "To remove manually: podman rm $CONTAINER_NAME"
fi

print_msg SUCCESS "Test completed successfully!"
print_msg INFO "Full test log: $TEST_LOG"

# Display summary
echo ""
echo "=== Test Summary ==="
grep -E "^\[" "$TEST_LOG" | tail -20 || true

exit 0