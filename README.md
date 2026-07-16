# owlmango

**Mango-based Wayland desktop configuration for Arch Linux**

A modern dotfiles system built around the [Mango](https://github.com/mangowm/mango) Wayland compositor (a fast dwl-based WM) and the [Wayle](https://wayle.app) desktop shell. Bash is the default shell, with Fish and Nushell installed and ready to opt into. Ghostty is the terminal. Ships with automated installation, a Docker-based test suite, and remote SSH deployment.

> owlmango is a fork of na-distro, re-targeted from Niri to MangoWM and from the waybar/swaync/swayosd stack to the Wayle shell. It focuses on Arch Linux / CachyOS.

## Features

- **Mango Compositor** — fast, feature-rich dwl-based tiling Wayland compositor with tags, animations, and IPC
- **Wayle Shell** — Rust/GTK4 desktop shell providing the bar, notifications, OSD, wallpaper, and device controls, with a Mango workspaces module (from the [wayle-mango](https://github.com/theblack-don/wayle-mango) fork)
- **Bash default** — bash stays the login shell for both user and root; Fish and Nushell are installed and available via `exec fish` / `exec nu`
- **Ghostty terminal** — GPU-accelerated terminal, themed Adwaita Pastel Dark
- **CLI-only Mode** — headless server installations without GUI components
- **Remote Bootstrap** — one-command SSH deployment to remote servers
- **Comprehensive Testing** — Docker-based test suite on Arch
- **Hardlinked SSH Config** — bidirectional editing between repo and ~/.ssh/

## Quick Start

### Fresh Machine Bootstrap

Install on a new machine with a single command — installs git, clones the repo, and runs the full installer:

```bash
# Full GUI installation
curl -fsSL https://raw.githubusercontent.com/acchapm1/owlmango/main/install/install.sh | bash

# CLI-only (servers/headless)
curl -fsSL https://raw.githubusercontent.com/acchapm1/owlmango/main/install/install.sh | bash -s -- --cli-only
```

### Local Installation

If you already have the repo cloned:

```bash
# Full GUI installation (Mango + Wayle + all tools)
./install/local

# CLI-only installation (servers/headless)
./install/local --cli-only

# Skip root customizations
./install/local --no-root

# Combined flags
./install/local --cli-only --no-root
```

### Remote Installation

Deploy to a remote server via SSH:

```bash
# Basic remote installation (always CLI-only)
./install/remote user@server.example.com

# Custom SSH port
./install/remote -p 2222 user@server.local

# With SSH key
./install/remote -i ~/.ssh/id_rsa user@192.168.1.100

# Dry run (preview without executing)
./install/remote --dry-run user@server
```

## What's Included

### Full Installation (GUI)

**Window Manager & Desktop:**

- Mango — dwl-based tiling Wayland compositor (`mangowm-git` from AUR)
- Wayle — desktop shell: bar, notifications, OSD, wallpaper, device controls (built from source)
- swaylock + swayidle — screen locking and idle management
- greetd — autologin / login manager launching Mango

**Applications:**

- Ghostty — GPU-accelerated terminal emulator
- Neovim — modern Vim with Lua configuration and Adwaita Pastel Dark theme
- Walker — application launcher (Elephant backend)
- Various GUI tools (evince, loupe, celluloid, etc.)

**Theming:**

- Adwaita Pastel Dark theme across Mango, Wayle, Ghostty, and GTK/Qt
- Papirus icon theme

### CLI-only Installation (Servers)

**Shell:**

- Bash (default) with Fish and Nushell available to opt into
- Fish config with custom Adwaita-themed prompt and Git integration

**CLI Tools:**

- bat, fzf, htop/btop, jq, mise, git, and more

**System:**

- Docker + docker-compose
- SSH configuration with hardlinks
- Gnome Keyring + gcr-ssh-agent
- Systemd user services

## Installation Details

### Shells

owlmango installs **bash**, **fish**, and **nushell** but leaves **bash as the
login shell** for both the user and root. Nothing runs `chsh`. To use another
shell interactively:

```bash
exec fish   # or
exec nu
```

Root still receives a Fish config (prompt, functions) so that Fish looks right
if you invoke it manually as root — but root's login shell also stays bash.

### Directory Structure

```
~/.config/              # Configuration symlinks
~/.local/share/         # Application data (incl. wayle-mango source checkout)
~/.ssh/                 # SSH config (hardlinked)
~/.local/state/config-backups/  # Backup of replaced configs
```

### Package Organization

```
config/packages/
└── arch/
    ├── cli/packages.txt    # Arch CLI tools (bat, fish, nushell, git, etc.)
    └── gui/
        ├── packages.txt    # Arch GUI repo packages (ghostty, wayle deps, etc.)
        └── aur.txt         # AUR packages (mangowm-git, walker-bin, etc.)
```

Mango is installed via AUR (`mangowm-git`). Wayle is built from source from the
[wayle-mango](https://github.com/theblack-don/wayle-mango) fork (which adds the
`mango-workspaces` bar module and MangoWM detection); the installer sets up the
Rust toolchain via `rustup` and runs `cargo install`.

### Flags

- `--cli-only` — install only CLI tools, skip all GUI configurations
- `--no-root` — skip root user customizations
- `--fingerprint` — enable fingerprint authentication for swaylock

Installer flags are saved to `~/.config/owlmango/install.flags` and reused on subsequent runs.

## Testing

Docker-based test suite (Arch):

```bash
# Run all tests
./test/run_tests.fish

# Run a specific test
./test/run_tests.fish --test test_cli_only_flag.fish

# Interactive debugging
./test/run_tests.fish --interactive
```

**Test Coverage:**

- Basic installation (Mango / Wayle / Ghostty configs linked)
- CLI-only mode (GUI configs absent)
- No-root flag
- SSH hardlinks
- Fish greeting disabled
- Root customizations
- Backup functionality

## Supported Distributions

### Arch Linux / CachyOS

- Full support with pacman
- AUR packages via paru/yay (installer bootstraps `yay-bin` if needed)
- All GUI components available

owlmango is Arch-focused because Mango (`mangowm-git`) and Wayle build cleanly
there. Other distros are not currently targeted.

## Configuration Files

**Mango** (`config/mango/`):

- `config.conf` — main configuration (env, input, tag layouts, includes, autostart)
- `theme.conf` — colors, gaps, borders, animations
- `binds.conf` — key/mouse/axis bindings (MOD = Super)
- `autostart.sh` — launched via `exec-once`; starts Wayle, portals, polkit, idle/lock, launcher
- `scripts/` — helper scripts (lock, screenshot-picker, power-off-monitors)
- `host.conf` — machine-specific overrides (not tracked in git; created on install)

**Wayle** (`config/wayle/config.toml`):

- Bar layout (with the `mango-workspaces` module), styling, and module settings.
  Edits hot-reload. Full reference at [wayle.app/config](https://wayle.app/config/).

**Ghostty** (`config/ghostty/config`):

- Font, padding, keybindings, and the Adwaita Pastel Dark palette.

**Fish** (`config/fish/`):

- `conf.d/`, `functions/`, `completions/` — prompt and helpers (used when you opt into Fish).

**SSH:**

- `config/ssh/config` — hardlinked to `~/.ssh/config`
- `~/.ssh/config.local` — machine-specific overrides (not in repo)

## Customization

### Host-specific Mango Config

The installer creates `~/.config/mango/host.conf`, sourced by `config.conf`.
Add machine-specific rules there, e.g. a monitor layout:

```ini
# monitorrule=eDP-1,0.55,1,tile,0,1.0,0,0,1920,1080,60.0
```

### SSH Local Overrides

Use `~/.ssh/config.local` for machine-specific SSH config:

```ssh-config
Host work-server
    HostName 192.168.1.100
    User admin
    IdentityFile ~/.ssh/work_key
```

### Custom Package Lists

Edit the package files in `config/packages/arch/{cli,gui}/` to customize
installed packages.

## System Requirements

**Minimum (CLI-only):**

- Arch Linux / CachyOS
- Git, Bash
- ~100MB disk space

**Full GUI:**

- Wayland-compatible graphics drivers
- Rust toolchain (installed automatically via rustup for the Wayle build)
- ~2GB disk space including build artifacts

## Credits

- **Mango** — https://github.com/mangowm/mango
- **Wayle** — https://wayle.app · https://github.com/wayle-rs/wayle
- **wayle-mango fork** — https://github.com/theblack-don/wayle-mango
- **Ghostty** — https://ghostty.org
- **Fish Shell** — https://fishshell.com
- **Adwaita Theme** — GNOME Project
- Forked from na-distro.

## License

Personal dotfiles configuration. Use at your own discretion.
