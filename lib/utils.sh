#!/bin/bash
# utils - Shared provisioning helpers for Debian 13
# Summary: Provides logging, package, and command helpers for idempotent setup.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Print an informational message.
# @param $1 Message text.
# @return 0 on success.
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Print a success message.
# @param $1 Message text.
# @return 0 on success.
log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

# Print a warning message.
# @param $1 Message text.
# @return 0 on success.
log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Print an error message.
# @param $1 Message text.
# @return 0 on success.
log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Print a skip message.
# @param $1 Message text.
# @return 0 on success.
log_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
}

# Check if a command exists.
# @param $1 Command name.
# @return 0 when available, 1 otherwise.
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install one APT package when missing.
# @param $1 Package name.
# @return 0 on success.
apt_install() {
    local package="$1"

    if dpkg -l "$package" 2>/dev/null | grep -q "^ii"; then
        log_skip "$package already installed"
        return 0
    fi

    log_info "Installing $package..."
    export DEBIAN_FRONTEND=noninteractive
    if sudo apt install -y "$package"; then
        log_success "$package installed"
        return 0
    fi

    log_error "Failed to install $package"
    return 1
}

# Ensure the script runs with root privileges (auto-elevate with sudo).
# @return 0 on success, re-executes with sudo otherwise.
require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_info "Requesting root privileges..."
        exec sudo "$0" "$@"
    fi
}
