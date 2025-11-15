#!/bin/bash

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_msg() {
    local level="$1"
    shift
    local msg="$*"
    
    case "$level" in
        SUCCESS) echo -e "${GREEN}[✓]${NC} $msg" ;;
        ERROR) echo -e "${RED}[✗]${NC} $msg" ;;
        INFO) echo -e "${BLUE}[→]${NC} $msg" ;;
    esac
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check dependencies
print_msg INFO "Checking dependencies..."

if ! command -v podman &>/dev/null; then
    print_msg ERROR "Podman is not installed"
    print_msg INFO "Install with: sudo dnf install -y podman (Fedora)"
    print_msg INFO "          or: sudo apt install -y podman (Ubuntu/Debian)"
    exit 1
fi

print_msg SUCCESS "Podman is installed: $(podman --version)"

# Check if rootless socket is available
if ! podman info &>/dev/null; then
    print_msg ERROR "Podman cannot be accessed. Try: systemctl --user start podman.socket"
    exit 1
fi

print_msg SUCCESS "Podman is accessible"

# Run tests
print_msg INFO "Starting test suite..."
echo ""

case "${1:-all}" in
    fedora)
        print_msg INFO "Testing Fedora setup..."
        bash "$SCRIPT_DIR/test-setup.sh" fedora
        ;;
    ubuntu)
        print_msg INFO "Testing Ubuntu setup..."
        bash "$SCRIPT_DIR/test-setup.sh" ubuntu
        ;;
    debian)
        print_msg INFO "Testing Debian setup..."
        bash "$SCRIPT_DIR/test-setup.sh" debian
        ;;
    all)
        print_msg INFO "Testing all distributions..."
        bash "$SCRIPT_DIR/comprehensive-test.sh"
        ;;
    *)
        echo "Usage: $0 [fedora|ubuntu|debian|all]"
        exit 1
        ;;
esac

print_msg SUCCESS "Tests completed!"

exit 0