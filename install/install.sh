#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script for owlmango dotfiles.
# Installs git, clones (or updates) the repo, then runs the local installer.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/brochapman/owlmango/main/install/install.sh | bash
#   curl -fsSL ... | bash -s -- --cli-only --no-root
#   bash install/install.sh --fingerprint

REPO_URL="${DOTFILES_REPO_URL:-https://github.com/brochapman/owlmango}"
INSTALL_DIR="$HOME/.local/share/owlmango"
BRANCH="${DOTFILES_BRANCH:-main}"

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

# --- Detect package manager ---------------------------------------------------

detect_package_manager() {
  if have pacman; then
    echo "pacman"
  elif have apt-get; then
    echo "apt"
  else
    die "Unsupported system: neither pacman nor apt-get found"
  fi
}

# --- Install git if missing ---------------------------------------------------

install_git() {
  if have git; then
    return 0
  fi

  log "Installing git..."
  local pm
  pm=$(detect_package_manager)

  case "$pm" in
    pacman)
      sudo pacman -Sy --needed --noconfirm git
      ;;
    apt)
      sudo apt-get update -qq
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq git
      ;;
  esac

  have git || die "Failed to install git"
  success "git installed"
}

# --- Install neovim if missing -------------------------------------------------

install_neovim() {
  if have nvim; then
    return 0
  fi

  log "Installing neovim..."
  local pm
  pm=$(detect_package_manager)

  case "$pm" in
    pacman)
      sudo pacman -Sy --needed --noconfirm neovim
      ;;
    apt)
      sudo apt-get update -qq
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq neovim
      ;;
  esac

  have nvim || die "Failed to install neovim"
  success "neovim installed"
}

# --- Clone or update repo -----------------------------------------------------

clone_or_update() {
  if [ ! -d "$INSTALL_DIR" ]; then
    log "Cloning $REPO_URL -> $INSTALL_DIR"
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone "$REPO_URL" "$INSTALL_DIR"
    success "Repository cloned"
    return 0
  fi

  if [ ! -d "$INSTALL_DIR/.git" ]; then
    die "$INSTALL_DIR exists but is not a git repository"
  fi

  log "Updating existing repository..."
  git -C "$INSTALL_DIR" fetch origin
  git -C "$INSTALL_DIR" reset --hard "origin/$BRANCH"
  success "Repository updated"
}

# --- Main ---------------------------------------------------------------------

main() {
  log "owlmango bootstrap"

  install_git
  install_neovim
  clone_or_update

  log "Running local installer..."
  exec sh "$INSTALL_DIR/install/local" "$@"
}

main "$@"
