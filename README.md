# KCS Debian 13 Provisioning Tool

Modular and idempotent system for provisioning Debian 13 (Trixie) environments.

## Architecture

1.  **Library (`lib/`)**: Shared logic and idempotency helpers (`apt_install`, `log_*`).
2.  **Installers (`ins/`)**: Atomic provisioning units.

## Quick Start (Bare Metal)

To install the project on a new machine and start the setup:

```bash
# 1. As root, install sudo and add your user to the group
su -
apt update && apt install -y sudo git
usermod -aG sudo <your_user>
reboot

# 2. Back as normal user, clone and run the setup
git clone https://github.com/kaisarcode/setup-debian
```

## Helper Tools (`bin/`)

Standalone utilities for system management:

- **`inc <subcommand>`**: Unified manager for Incus containers (create, clone, sync, etc.).
- **`aid`**: Runs Aider inside a Podman container.
- **`owi`**: Starts Open WebUI against a remote Ollama server.
- **`iso`**: Run an isolated envitonment using podman/distrobox.
- **`xmouse` / `xres`**: Utilities for switching between normal and tablet-friendly mouse/DPI settings (useful for convertible devices).
