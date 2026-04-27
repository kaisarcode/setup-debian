#!/bin/bash
# syncthing - Syncthing file synchronization for Debian 13
# Summary: Installs Syncthing and enables bidirectional sync for ~/Work.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

set -euo pipefail

SYNC_DIR="$HOME/Work"

# Install Syncthing from Debian main.
# @return 0 on success.
install_syncthing() {
    if command_exists syncthing; then
        log_skip "Syncthing is already installed."
        return 0
    fi

    log_info "Installing Syncthing..."
    apt_install "syncthing"
}

# Enable and start Syncthing as a user systemd service.
# @return 0 on success.
enable_syncthing_service() {
    if systemctl --user is-enabled syncthing >/dev/null 2>&1; then
        log_skip "Syncthing user service already enabled."
        return 0
    fi

    log_info "Enabling Syncthing user service..."
    systemctl --user enable --now syncthing
    log_success "Syncthing service enabled."
}

# Enable lingering so the user service starts at boot without login.
# @return 0 on success.
enable_linger() {
    if loginctl show-user "$USER" 2>/dev/null | grep -q "Linger=yes"; then
        log_skip "Linger already enabled for $USER."
        return 0
    fi

    log_info "Enabling linger for $USER..."
    sudo loginctl enable-linger "$USER"
    log_success "Linger enabled."
}

# Ensure the Work directory exists.
# @return 0 on success.
ensure_sync_dir() {
    if [[ -d "$SYNC_DIR" ]]; then
        log_skip "Sync directory already exists: $SYNC_DIR"
        return 0
    fi

    log_info "Creating sync directory: $SYNC_DIR"
    mkdir -p "$SYNC_DIR"
    log_success "Sync directory created."
}

# Print post-install pairing instructions.
# @return 0 on success.
print_pairing_instructions() {
    log_success "Syncthing is running. Open the web UI to complete device pairing:"
    echo ""
    echo "  http://127.0.0.1:8384"
    echo ""
    echo "Steps to pair this machine with another:"
    echo "  1. On each machine run: syncthing --device-id"
    echo "  2. In the web UI: Add Remote Device using the other machine's ID"
    echo "  3. Share the '~/Work' folder with the paired device"
    echo "  4. Accept the share on the other machine"
    echo ""
    echo "Tip: use Tailscale IPs for transport — no port forwarding needed."
}

# Run the Syncthing provisioning.
# @return 0 on success.
main() {
    local PROJECT_ROOT
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$PROJECT_ROOT/lib/utils.sh"

    log_info "Running Syncthing Provisioning..."
    install_syncthing
    ensure_sync_dir
    enable_linger
    enable_syncthing_service
    print_pairing_instructions
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
