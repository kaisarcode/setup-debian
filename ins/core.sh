#!/bin/bash
# core - Debian 13 base system preparation
# Summary: Configures repositories and installs base tools.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

set -euo pipefail

# Configure Debian 13 repositories.
# @return 0 on success.
setup_repositories() {
    local os_name
    os_name=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2)

    if [ -z "$os_name" ]; then
        log_error "Cannot detect OS version."
        return 1
    fi

    log_info "Configuring repositories for $os_name (main contrib non-free non-free-firmware)..."

    cat <<EOF | sudo tee /etc/apt/sources.list > /dev/null
deb http://deb.debian.org/debian/ $os_name main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security $os_name-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian/ $os_name-updates main contrib non-free non-free-firmware
EOF

    sudo apt update -qq
}

# Install core system packages.
# @return 0 on success.
install_core_packages() {
    local packages=(
        "curl"
        "wget"
        "pciutils"
        "grep"
        "acl"
        "sudo"
        "openssh-server"
        "avahi-daemon"
        "htop"
        "tree"
        "git"
        "micro"
        "tmux"
    )

    for pkg in "${packages[@]}"; do
        apt_install "$pkg"
    done
}

# Ensure basic services are enabled.
# @return 0 on success.
enable_core_services() {
    log_info "Ensuring core services are active..."
    sudo systemctl enable --now ssh avahi-daemon 2>/dev/null || true
}

# Run the core provisioning.
main() {
    local PROJECT_ROOT
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$PROJECT_ROOT/lib/utils.sh"

    log_info "Running Core Provisioning..."
    setup_repositories
    install_core_packages
    enable_core_services
    log_success "Core Provisioning complete."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
