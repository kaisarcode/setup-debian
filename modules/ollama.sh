#!/bin/bash
# ollama - Ollama with GPU support for Debian 13
# Summary: Installs NVIDIA container toolkit and prepares Ollama.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

set -euo pipefail

# Install NVIDIA Container Toolkit.
install_nvidia_toolkit() {
    if command -v nvidia-ctk >/dev/null 2>&1; then
        log_skip "NVIDIA Container Toolkit is already installed."
        return 0
    fi

    log_info "Installing NVIDIA Container Toolkit..."
    
    # Debian 13 (Trixie) often has it in the repos or needs the NVIDIA repo.
    # We'll try the official NVIDIA repo for the most up-to-date version.
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    
    sudo apt update
    apt_install "nvidia-container-toolkit"

    # Configure the toolkit for Podman (generate CDI spec)
    log_info "Configuring NVIDIA CDI for Podman..."
    sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
}

# Run the ollama provisioning.
main() {
    local PROJECT_ROOT
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$PROJECT_ROOT/lib/utils.sh"

    log_info "Running Ollama Provisioning..."
    install_nvidia_toolkit
    log_success "Ollama environment is ready."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
