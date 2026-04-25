#!/bin/bash
# sunshine - Sunshine streaming server for Debian 13
# Summary: Installs and optimizes Sunshine for NVIDIA GPUs.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

set -euo pipefail

# Install Sunshine from latest release.
install_sunshine() {
    if command_exists sunshine; then
        log_skip "Sunshine is already installed."
        return 0
    fi

    log_info "Installing Sunshine..."
    # Note: Using the Trixie-specific debian package
    local DEB_URL="https://github.com/LizardByte/Sunshine/releases/latest/download/sunshine-debian-trixie-amd64.deb"
    
    curl -L --output /tmp/sunshine.deb "$DEB_URL"
    sudo apt install -y /tmp/sunshine.deb || sudo apt install -y -f
    rm /tmp/sunshine.deb

    # Add uinput module to load at boot
    echo "uinput" | sudo tee /etc/modules-load.d/uinput.conf
    sudo modprobe uinput

    # Add udev rules for input simulation (Mouse/Keyboard/Gamepad)
    sudo bash -c 'cat <<EOF > /etc/udev/rules.d/60-sunshine.rules
KERNEL=="uinput", GROUP="input", MODE="0660"
EOF'
    sudo udevadm control --reload-rules
    sudo udevadm trigger
}

# Configure hardware permissions.
configure_permissions() {
    local primary_user
    primary_user=$(id -un 1000)
    
    log_info "Configuring hardware permissions for $primary_user..."
    sudo usermod -aG video,render,input "$primary_user"
}

# Create optimized Sunshine configuration.
configure_sunshine() {
    local primary_user
    local user_home
    primary_user=$(id -un 1000)
    user_home=$(getent passwd "$primary_user" | cut -d: -f6)

    log_info "Creating optimized Sunshine configuration..."
    sudo -u "$primary_user" mkdir -p "$user_home/.config/sunshine"
    
    sudo -u "$primary_user" bash -c "cat <<EOF > $user_home/.config/sunshine/sunshine.conf
# Sunshine Optimized Config
encoder = nvenc
nvenc_preset = p4
min_threads = 4
port = 47989
fec_percentage = 20
max_bitrate = 50000
EOF"
}

# Create and enable systemd user service.
setup_service() {
    local primary_user
    local user_home
    primary_user=$(id -un 1000)
    user_home=$(getent passwd "$primary_user" | cut -d: -f6)

    log_info "Setting up Sunshine as a user service..."
    sudo -u "$primary_user" mkdir -p "$user_home/.config/systemd/user/"
    
    sudo -u "$primary_user" bash -c "cat <<EOF > $user_home/.config/systemd/user/sunshine.service
[Unit]
Description=Sunshine Game Stream Host
After=graphical-session.target

[Service]
Type=simple
ExecStartPre=/bin/sleep 5
Environment=DISPLAY=:0
ExecStart=/usr/bin/sunshine
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF"

    # Enable service and lingering
    sudo -u "$primary_user" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus systemctl --user daemon-reload || true
    sudo -u "$primary_user" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus systemctl --user enable sunshine || true
    sudo loginctl enable-linger "$primary_user"
}

# Run the sunshine provisioning.
main() {
    local PROJECT_ROOT
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$PROJECT_ROOT/lib/utils.sh"

    log_info "Running Sunshine Provisioning..."
    install_sunshine
    configure_permissions
    configure_sunshine
    setup_service
    log_success "Sunshine is ready."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
