#!/bin/bash
# drivers - Hardware detection and driver installation for Debian 13
# Summary: Installs microcode, NVIDIA drivers, and audio stack.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

set -euo pipefail

# Install CPU microcode.
install_microcode() {
    if grep -q 'AMD' /proc/cpuinfo; then
        log_info "AMD CPU detected. Installing microcode..."
        apt_install "amd64-microcode"
    elif grep -q 'Intel' /proc/cpuinfo; then
        log_info "Intel CPU detected. Installing microcode..."
        apt_install "intel-microcode"
    fi
}

# Install NVIDIA driver stack if hardware is detected.
install_nvidia() {
    if ! lspci | grep -qi 'nvidia'; then
        return 0
    fi

    log_info "NVIDIA GPU detected. Installing driver stack..."
    apt_install "dkms"
    apt_install "linux-headers-$(uname -r)"
    
    # Core driver packages for Debian 13
    apt_install "nvidia-driver"
    apt_install "firmware-misc-nonfree"
    apt_install "nvidia-settings"
    apt_install "nvtop"

    # Enable NVIDIA DRM Modeset for hardware capture support (required for Sunshine/NVENC)
    log_info "Enabling NVIDIA DRM modeset..."
    echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia-drm.conf
    sudo update-initramfs -u

    # Install NVIDIA Container Toolkit for Podman/Docker GPU support
    log_info "Installing NVIDIA Container Toolkit..."
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    
    sudo apt update
    apt_install "nvidia-container-toolkit"
    
    log_info "Configuring NVIDIA CDI for Podman..."
    sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
}

# Install PipeWire audio stack.
install_audio() {
    if ! lspci | grep -qi 'audio'; then
        return 0
    fi

    log_info "Audio hardware detected. Installing PipeWire stack..."
    apt_install "pipewire"
    apt_install "pipewire-audio-client-libraries"
    apt_install "wireplumber"
    apt_install "pavucontrol"

    # Enable for all users
    sudo systemctl --global enable pipewire.service 2>/dev/null || true
    sudo systemctl --global enable wireplumber.service 2>/dev/null || true
}

# Run the drivers provisioning.
main() {
    local PROJECT_ROOT
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$PROJECT_ROOT/lib/utils.sh"

    log_info "Running Drivers Provisioning..."
    install_microcode
    install_nvidia
    install_audio
    log_success "Drivers Provisioning complete."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
