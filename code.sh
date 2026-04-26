#!/bin/bash
# code - Isolated code environment for Debian 13
# Summary: Installs VS Code and Antigravity inside a Distrobox environment.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

set -euo pipefail

CODE_BOX_NAME="code"
CODE_BOX_IMAGE="debian:trixie"
CODE_BOX_HOME="$HOME/.isolated/$CODE_BOX_NAME"

# Install host container dependencies.
# @return 0 on success.
install_code_host_dependencies() {
    log_info "Installing host dependencies for isolated code environment..."
    apt_install "podman"
    apt_install "distrobox"
    apt_install "uidmap"
    apt_install "slirp4netns"
    apt_install "fuse-overlayfs"
}

# Create isolated Distrobox environment.
# @return 0 on success.
create_code_environment() {
    if distrobox list | awk '{print $3}' | grep -qx "$CODE_BOX_NAME"; then
        log_skip "Distrobox environment '$CODE_BOX_NAME' already exists."
        return 0
    fi

    log_info "Creating isolated home at $CODE_BOX_HOME..."
    mkdir -p "$CODE_BOX_HOME"

    log_info "Creating Distrobox environment '$CODE_BOX_NAME'..."
    distrobox create \
        --name "$CODE_BOX_NAME" \
        --image "$CODE_BOX_IMAGE" \
        --home "$CODE_BOX_HOME" \
        --yes
}

# Install base packages inside the isolated environment.
# @return 0 on success.
install_code_base_packages() {
    log_info "Installing base packages inside '$CODE_BOX_NAME'..."
    distrobox enter "$CODE_BOX_NAME" -- sudo apt update
    distrobox enter "$CODE_BOX_NAME" -- sudo apt install -y curl wget git gpg apt-transport-https ca-certificates
    distrobox enter "$CODE_BOX_NAME" -- sudo apt install -y gnome-keyring libsecret-1-0 dbus-user-session
}

# Install cross-compilation toolchains inside the isolated environment.
# @return 0 on success.
install_code_cross_tools() {
    log_info "Installing cross-compilation toolchains inside '$CODE_BOX_NAME'..."

    distrobox enter "$CODE_BOX_NAME" -- sudo apt install -y \
        gcc g++ cmake make ninja-build patchelf unzip \
        gcc-mingw-w64-x86-64 g++-mingw-w64-x86-64 \
        gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

    distrobox enter "$CODE_BOX_NAME" -- bash -c '
set -euo pipefail

NDK_ROOT="${KC_NDK_ROOT:-}"
if [ -z "$NDK_ROOT" ] && [ -n "${KC_TOOLCHAINS:-}" ]; then
    NDK_ROOT="$KC_TOOLCHAINS/ndk/android-ndk-r27c"
fi
if [ -z "$NDK_ROOT" ]; then
    NDK_ROOT="$HOME/.local/share/kaisarcode/toolchains/ndk/android-ndk-r27c"
fi

if [ -d "$NDK_ROOT" ]; then
    exit 0
fi

mkdir -p "$(dirname "$NDK_ROOT")"
TMP=$(mktemp -d)
curl -fL "https://dl.google.com/android/repository/android-ndk-r27c-linux.zip" -o "$TMP/ndk.zip"
unzip -q "$TMP/ndk.zip" -d "$TMP"
mv "$TMP/android-ndk-r27c" "$NDK_ROOT"
rm -rf "$TMP"
'
}

# Install VS Code inside the isolated environment.
# @return 0 on success.
install_vscode() {
    log_info "Installing VS Code inside '$CODE_BOX_NAME'..."

    distrobox enter "$CODE_BOX_NAME" -- bash -c '
set -euo pipefail

if command -v code >/dev/null 2>&1; then
    exit 0
fi

wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor \
    | sudo tee /usr/share/keyrings/microsoft.gpg >/dev/null

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
    | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null

sudo apt update
sudo apt install -y code
'
}

# Install Antigravity inside the isolated environment.
# @return 0 on success.
install_antigravity() {
    log_info "Installing Antigravity inside '$CODE_BOX_NAME'..."

    distrobox enter "$CODE_BOX_NAME" -- bash -c '
set -euo pipefail

if command -v antigravity >/dev/null 2>&1; then
    exit 0
fi

sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg \
    | sudo gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg

echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" \
    | sudo tee /etc/apt/sources.list.d/antigravity.list >/dev/null

sudo apt update
sudo apt install -y antigravity
'
}

# Export installed applications to the host desktop menu.
# @return 0 on success.
export_code_apps() {
    log_info "Exporting VS Code to host menu..."
    distrobox enter "$CODE_BOX_NAME" -- distrobox-export --app code || true

    log_info "Exporting Antigravity to host menu..."
    distrobox enter "$CODE_BOX_NAME" -- distrobox-export --app antigravity || true
}

# Run the isolated code environment provisioning.
# @return 0 on success.
main() {
    local PROJECT_ROOT
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$PROJECT_ROOT/lib/utils.sh"

    log_info "Running Isolated Code Environment Provisioning..."
    install_code_host_dependencies
    create_code_environment
    install_code_base_packages
    install_code_cross_tools
    install_vscode
    install_antigravity
    export_code_apps
    log_success "Isolated code environment is ready at $CODE_BOX_HOME."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
