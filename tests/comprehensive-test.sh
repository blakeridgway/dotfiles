#!/bin/bash

# Comprehensive Test Suite - Tests all distributions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="${SCRIPT_DIR}/results"
mkdir -p "$RESULTS_DIR"

print_header() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  $1"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

print_header "Comprehensive Dotfiles Setup Tests"

echo "Starting tests for all supported distributions..."
echo "Results will be saved to: $RESULTS_DIR"
echo ""

# Test distributions
DISTROS=("fedora" "ubuntu" "debian")

# Track results
declare -A RESULTS

for distro in "${DISTROS[@]}"; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Testing: $distro"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if bash "$SCRIPT_DIR/test-setup.sh" "$distro"; then
        RESULTS[$distro]="✓ PASS"
        echo "✓ $distro: PASSED"
    else
        RESULTS[$distro]="✗ FAIL"
        echo "✗ $distro: FAILED"
    fi
    echo ""
done

# Print summary
print_header "Test Summary"

for distro in "${DISTROS[@]}"; do
    echo "${RESULTS[$distro]} - $distro"
done

echo ""
echo "Test logs saved in: $RESULTS_DIR"
echo "Check individual logs for details"

exit 0