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

NDK_VERSION="27.2.12479018"
NDK_RELEASE="r27c"
NDK_ZIP="android-ndk-${NDK_RELEASE}-linux.zip"

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

    log_info "Linking .ssh, .gitconfig and Work from host..."
    [ -e "$CODE_BOX_HOME/.ssh" ] || ln -s "$HOME/.ssh" "$CODE_BOX_HOME/.ssh"
    [ -e "$CODE_BOX_HOME/.gitconfig" ] || ln -s "$HOME/.gitconfig" "$CODE_BOX_HOME/.gitconfig"
    [ -e "$CODE_BOX_HOME/Work" ] || ln -s "$HOME/Work" "$CODE_BOX_HOME/Work"

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
    distrobox enter "$CODE_BOX_NAME" -- sudo apt install -y curl wget git git-lfs gpg apt-transport-https ca-certificates micro
    distrobox enter "$CODE_BOX_NAME" -- sudo apt install -y gnome-keyring libsecret-1-0 dbus-user-session
    distrobox enter "$CODE_BOX_NAME" -- sudo apt install -y gh jq shellcheck ripgrep
}

# Configure environment variables for cross-compilation tools.
# @return 0 on success.
configure_code_env() {
    log_info "Configuring environment variables inside '$CODE_BOX_NAME'..."
    distrobox enter "$CODE_BOX_NAME" -- env NDK_VERSION="$NDK_VERSION" bash -c '
set -euo pipefail

PROFILE="$HOME/.profile"
MARKER="# kc-crosstools"

if grep -qF "$MARKER" "$PROFILE" 2>/dev/null; then
    exit 0
fi

cat >> "$PROFILE" << EOF

# kc-crosstools
export ANDROID_HOME="\${ANDROID_HOME:-\${XDG_DATA_HOME:-\$HOME/.local/share}/android-sdk}"
export ANDROID_NDK_HOME="\$ANDROID_HOME/ndk/$NDK_VERSION"
export PATH="\$ANDROID_HOME/ndk/$NDK_VERSION:\$PATH"
EOF
'
}

# Install cross-compilation toolchains inside the isolated environment.
# @return 0 on success.
install_code_cross_tools() {
    log_info "Installing cross-compilation toolchains inside '$CODE_BOX_NAME'..."

    distrobox enter "$CODE_BOX_NAME" -- sudo apt install -y \
        gcc g++ cmake make ninja-build patchelf unzip \
        \
        gcc-mingw-w64-x86-64 g++-mingw-w64-x86-64 \
        gcc-mingw-w64-i686 g++-mingw-w64-i686 \
        \
        gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
        gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf \
        gcc-arm-linux-gnueabi g++-arm-linux-gnueabi \
        \
        gcc-i686-linux-gnu g++-i686-linux-gnu \
        gcc-riscv64-linux-gnu g++-riscv64-linux-gnu \
        gcc-powerpc64le-linux-gnu g++-powerpc64le-linux-gnu \
        gcc-mips-linux-gnu g++-mips-linux-gnu \
        gcc-mipsel-linux-gnu g++-mipsel-linux-gnu \
        gcc-mips64el-linux-gnuabi64 g++-mips64el-linux-gnuabi64 \
        gcc-s390x-linux-gnu g++-s390x-linux-gnu \
        gcc-loongarch64-linux-gnu g++-loongarch64-linux-gnu

    distrobox enter "$CODE_BOX_NAME" -- env NDK_VERSION="$NDK_VERSION" NDK_RELEASE="$NDK_RELEASE" NDK_ZIP="$NDK_ZIP" bash -c '
set -euo pipefail

ANDROID_HOME="${ANDROID_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/android-sdk}"
NDK_DIR="$ANDROID_HOME/ndk/$NDK_VERSION"

if [ -d "$NDK_DIR" ]; then
    exit 0
fi

mkdir -p "$ANDROID_HOME/ndk"
TMP=$(mktemp -d)
curl -fL "https://dl.google.com/android/repository/$NDK_ZIP" -o "$TMP/ndk.zip"
unzip -q "$TMP/ndk.zip" -d "$TMP"
mv "$TMP/android-ndk-$NDK_RELEASE" "$NDK_DIR"
ln -sf "$NDK_VERSION" "$ANDROID_HOME/ndk/${NDK_VERSION%%.*}"
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

printf "Types: deb\nURIs: https://packages.microsoft.com/repos/code\nSuites: stable\nComponents: main\nArchitectures: amd64\nSigned-By: /usr/share/keyrings/microsoft.gpg\n" \
    | sudo tee /etc/apt/sources.list.d/vscode.sources >/dev/null

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
    configure_code_env
    install_vscode
    install_antigravity
    export_code_apps
    log_success "Isolated code environment is ready at $CODE_BOX_HOME."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
