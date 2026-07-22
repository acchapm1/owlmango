#!/usr/bin/env bash
set -euo pipefail

# Prerequisite installer for owlmango.
# Installs yay-bin (AUR helper) and the Rust toolchain (rustup + stable),
# both required before running install/local.
#
# Usage:
#   bash install/prereqs.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log()     { echo -e "${BLUE}==>${NC} $*"; }
success() { echo -e "${GREEN}==>${NC} $*"; }
error()   { echo -e "${RED}==>${NC} $*" >&2; }
die()     { error "$@"; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# --- Install yay-bin (AUR helper) ---------------------------------------------

install_yay_bin() {
  if pacman -Q yay-bin >/dev/null 2>&1; then
    success "yay-bin already installed"
    return 0
  fi

  log "Installing yay-bin build dependencies (git, base-devel)..."
  sudo pacman -S --needed --noconfirm git base-devel

  log "Building yay-bin from AUR..."
  tmp_dir=$(mktemp -d)
  trap 'rm -rf "$tmp_dir"' EXIT

  git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp_dir/yay-bin" ||
    die "Failed to clone yay-bin AUR repo"

  (cd "$tmp_dir/yay-bin" && makepkg -s --noconfirm) ||
    die "Failed to build yay-bin"

  # yay-bin conflicts with yay, and `pacman --noconfirm` answers no to the
  # conflict-removal prompt, so the old package has to go before pacman -U.
  if pacman -Q yay >/dev/null 2>&1; then
    sudo pacman -R --noconfirm yay
  fi

  sudo pacman -U --noconfirm "$tmp_dir/yay-bin/"*.pkg.tar* ||
    die "Failed to install yay-bin package"

  success "yay-bin installed"
}

# --- Install Rust toolchain ---------------------------------------------------

install_rust() {
  if have cargo; then
    success "rust already installed (cargo found)"
    return 0
  fi

  log "Installing rustup..."
  sudo pacman -S --needed --noconfirm rustup

  log "Initializing rust stable toolchain..."
  rustup default stable || rustup toolchain install stable

  # rustup places cargo in ~/.cargo/bin; make it visible for the rest of the run.
  case ":$PATH:" in
    *":$HOME/.cargo/bin:"*) : ;;
    *) PATH="$HOME/.cargo/bin:$PATH"; export PATH ;;
  esac

  have cargo || die "cargo unavailable after rustup setup"
  success "rust installed (stable toolchain)"
}

# --- Main ---------------------------------------------------------------------

main() {
  log "owlmango prerequisites (yay-bin, rust)"

  if ! have pacman; then
    log "pacman not found; skipping prerequisites (Arch-only)"
    exit 0
  fi

  have sudo || die "sudo is required to install prerequisites"

  install_yay_bin
  install_rust

  success "Prerequisites installed"
}

main "$@"
