#!/bin/bash

# Health Check Script - Verifies all installations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/helpers.sh"

init_logging

print_msg INFO "=== Health Check ==="
echo ""

declare -i passed=0
declare -i failed=0

check_command() {
    local cmd="$1"
    local description="${2:-$cmd}"
    
    if command -v "$cmd" &>/dev/null; then
        local version
        version=$("$cmd" --version 2>/dev/null | head -n1 || echo "installed")
        print_msg SUCCESS "$description: $version"
        ((passed++))
    else
        print_msg ERROR "$description: NOT FOUND"
        ((failed++))
    fi
}

check_file() {
    local file="$1"
    local description="${2:-$file}"
    
    if [ -e "$file" ]; then
        print_msg SUCCESS "$description exists"
        ((passed++))
    else
        print_msg ERROR "$description: NOT FOUND"
        ((failed++))
    fi
}

print_msg INFO "Core Tools:"
check_command "git" "Git"
check_command "curl" "cURL"
check_command "wget" "Wget"
check_command "zsh" "Zsh"

echo ""
print_msg INFO "Development Tools:"
check_command "nvim" "Neovim"
check_command "go" "Go"
check_command "rustc" "Rust"
check_command "dotnet" ".NET"
check_command "python3" "Python 3"

echo ""
print_msg INFO "Terminal Prompt:"
check_command "starship" "Starship"
check_command "oh-my-posh" "Oh-My-Posh"

echo ""
print_msg INFO "Configuration Files:"
check_file "$HOME/.config/starship.toml" "Starship config"
check_file "$HOME/.gitconfig" "Git config"
check_file "$HOME/.zshrc" "Zsh config"

echo ""
print_msg INFO "Services (Fedora):"
if command -v systemctl &>/dev/null; then
    for service in docker postgresql; do
        if systemctl is-enabled "$service" &>/dev/null; then
            print_msg SUCCESS "$service service enabled"
            ((passed++))
        elif systemctl is-active "$service" &>/dev/null; then
            print_msg WARN "$service running but not enabled"
            ((passed++))
        else
            print_msg DEBUG "$service not available"
        fi
    done
fi

echo ""
print_msg INFO "Summary: $passed passed, $failed failed"

if [ $failed -eq 0 ]; then
    print_msg SUCCESS "All checks passed!"
    exit 0
else
    print_msg WARN "$failed checks failed"
    exit 1
fi