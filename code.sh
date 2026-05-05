#!/bin/bash
# code - Native development environment for Debian 13
# Summary: Installs cross-compilation toolchains, VS Code, and Antigravity on the host.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

set -euo pipefail

NDK_VERSION="27.2.12479018"
NDK_RELEASE="r27c"
NDK_ZIP="android-ndk-${NDK_RELEASE}-linux.zip"

# Install cross-compilation toolchains and build tools.
# @return 0 on success.
install_cross_tools() {
    log_info "Installing cross-compilation toolchains..."

    apt_install "gcc"
    apt_install "g++"
    apt_install "cmake"
    apt_install "make"
    apt_install "ninja-build"
    apt_install "patchelf"
    apt_install "unzip"

    apt_install "gcc-mingw-w64-x86-64"
    apt_install "g++-mingw-w64-x86-64"
    apt_install "gcc-mingw-w64-i686"
    apt_install "g++-mingw-w64-i686"

    apt_install "gcc-aarch64-linux-gnu"
    apt_install "g++-aarch64-linux-gnu"
    apt_install "gcc-arm-linux-gnueabihf"
    apt_install "g++-arm-linux-gnueabihf"
    apt_install "gcc-arm-linux-gnueabi"
    apt_install "g++-arm-linux-gnueabi"

    apt_install "gcc-i686-linux-gnu"
    apt_install "g++-i686-linux-gnu"
    apt_install "gcc-riscv64-linux-gnu"
    apt_install "g++-riscv64-linux-gnu"
    apt_install "gcc-powerpc64le-linux-gnu"
    apt_install "g++-powerpc64le-linux-gnu"
    apt_install "gcc-mips-linux-gnu"
    apt_install "g++-mips-linux-gnu"
    apt_install "gcc-mipsel-linux-gnu"
    apt_install "g++-mipsel-linux-gnu"
    apt_install "gcc-mips64el-linux-gnuabi64"
    apt_install "g++-mips64el-linux-gnuabi64"
    apt_install "gcc-s390x-linux-gnu"
    apt_install "g++-s390x-linux-gnu"
    apt_install "gcc-loongarch64-linux-gnu"
    apt_install "g++-loongarch64-linux-gnu"
}

# Install Android NDK.
# @return 0 on success.
install_ndk() {
    local ANDROID_HOME="${ANDROID_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/android-sdk}"
    local NDK_DIR="$ANDROID_HOME/ndk/$NDK_VERSION"

    if [ -d "$NDK_DIR" ]; then
        log_skip "Android NDK $NDK_VERSION already installed."
        return 0
    fi

    log_info "Installing Android NDK $NDK_RELEASE..."
    mkdir -p "$ANDROID_HOME/ndk"
    local TMP
    TMP=$(mktemp -d)
    curl -fL "https://dl.google.com/android/repository/$NDK_ZIP" -o "$TMP/ndk.zip"
    unzip -q "$TMP/ndk.zip" -d "$TMP"
    mv "$TMP/android-ndk-$NDK_RELEASE" "$NDK_DIR"
    ln -sf "$NDK_VERSION" "$ANDROID_HOME/ndk/${NDK_VERSION%%.*}"
    rm -rf "$TMP"
}

# Configure NDK environment variables in ~/.profile.
# @return 0 on success.
configure_ndk_env() {
    local ANDROID_HOME="${ANDROID_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/android-sdk}"
    local PROFILE="$HOME/.profile"
    local MARKER="# kc-crosstools"

    if grep -qF "$MARKER" "$PROFILE" 2>/dev/null; then
        log_skip "NDK environment already configured."
        return 0
    fi

    log_info "Configuring NDK environment variables..."
    cat >> "$PROFILE" << EOF

# kc-crosstools
export ANDROID_HOME="\${ANDROID_HOME:-\${XDG_DATA_HOME:-\$HOME/.local/share}/android-sdk}"
export ANDROID_NDK_HOME="\$ANDROID_HOME/ndk/$NDK_VERSION"
export PATH="\$ANDROID_HOME/ndk/$NDK_VERSION:\$PATH"
EOF
}

# Install VS Code on the host.
# @return 0 on success.
install_vscode() {
    if command -v code >/dev/null 2>&1; then
        log_skip "VS Code already installed."
        return 0
    fi

    log_info "Installing VS Code..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor \
        | sudo tee /usr/share/keyrings/microsoft.gpg >/dev/null

    printf "Types: deb\nURIs: https://packages.microsoft.com/repos/code\nSuites: stable\nComponents: main\nArchitectures: amd64\nSigned-By: /usr/share/keyrings/microsoft.gpg\n" \
        | sudo tee /etc/apt/sources.list.d/vscode.sources >/dev/null

    sudo apt update
    apt_install "code"
}

# Install Antigravity on the host.
# @return 0 on success.
install_antigravity() {
    if command -v antigravity >/dev/null 2>&1; then
        log_skip "Antigravity already installed."
        return 0
    fi

    log_info "Installing Antigravity..."
    sudo mkdir -p /etc/apt/keyrings

    curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg \
        | sudo gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg

    echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" \
        | sudo tee /etc/apt/sources.list.d/antigravity.list >/dev/null

    sudo apt update
    apt_install "antigravity"
}

# Run the native development environment provisioning.
# @return 0 on success.
main() {
    local PROJECT_ROOT
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$PROJECT_ROOT/lib/utils.sh"

    log_info "Running Native Development Environment Provisioning..."
    install_cross_tools
    install_ndk
    configure_ndk_env
    install_vscode
    install_antigravity
    log_success "Native development environment is ready."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
