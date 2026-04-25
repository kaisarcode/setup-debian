# KCS Debian 13 Provisioning Tool

Modular and idempotent system for provisioning Debian 13 (Trixie) environments.

## Architecture

This project follows a 3-layer incremental architecture:

1.  **Library (`lib/`)**: Shared logic and idempotency helpers (`apt_install`, `log_*`).
2.  **Modules (`modules/`)**: Atomic provisioning units (core, drivers, desktop, virt, incus).
3.  **Profiles (`profiles/`)**: Recipes that orchestrate modules in an incremental way.

## Quick Start (Bare Metal)

To install the project on a new machine and start the setup:

```bash
# 1. As root, install sudo and add your user to the group
su -
apt update && apt install -y sudo git
usermod -aG sudo <your_user>
exit

# 2. Back as normal user, clone and run the setup
git clone https://github.com/kaisarcode/setup-debian
cd setup-debian
./profiles/base.sh
```

## Profiles

Profiles are incremental. You can execute them directly from the `profiles/` directory:

- **`./profiles/base.sh`**: Configures repositories and drivers (NVIDIA, Microcode, Audio). The system is left ready but without a graphical environment.
- **`./profiles/desktop.sh`**: Installs the base profile + MATE Desktop + Podman.
- **`./profiles/server.sh`**: Installs the base profile + Incus + Podman.
- **`./profiles/workstation.sh`**: Installs the desktop profile + Sunshine (optimized for RTX hosts).

## Helper Tools (`bin/`)

Standalone utilities for system management:

- **`inc <subcommand>`**: Unified manager for Incus containers (create, clone, sync, etc.).
- **`aid`**: Runs Aider inside a Podman container.
- **`owi`**: Starts Open WebUI against a remote Ollama server.
- **`xmouse` / `xres`**: Utilities for switching between normal and tablet-friendly mouse/DPI settings (useful for convertible devices).

## Idempotency

All modules verify if a package is already installed before taking action. You can safely execute any profile multiple times.
