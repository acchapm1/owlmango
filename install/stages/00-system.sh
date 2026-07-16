#!/usr/bin/env sh
set -eu

log() { printf '%s\n' "$*"; }

have() { command -v "$1" >/dev/null 2>&1; }

cli_only_enabled() {
  [ "${CLI_ONLY:-0}" = "1" ]
}

PKG_MANAGER=""
DISTRO=""
PKG_LOG_DIR="/tmp/owlmango-install"

# Wayle shell — built from source (the wayle-mango fork adds the
# mango-workspaces module and MangoWM compositor detection).
WAYLE_REPO="${WAYLE_REPO:-https://github.com/theblack-don/wayle-mango.git}"
WAYLE_SRC_DIR="${WAYLE_SRC_DIR:-$HOME/.local/share/owlmango/wayle-mango}"

init_pkg_logging() {
  mkdir -p "$PKG_LOG_DIR" >/dev/null 2>&1 || true
}

run_pkg_cmd() {
  label=$1
  shift
  log_file=$(mktemp "$PKG_LOG_DIR/${label}-XXXXXX.log" 2>/dev/null || echo "$PKG_LOG_DIR/${label}-$(date +%Y%m%d-%H%M%S)-$$.log")

  if "$@" >"$log_file" 2>&1; then
    return 0
  fi

  if [ "$label" = "pacman" ]; then
    if grep -Eq "nothing to do|up to date -- skipping" "$log_file" 2>/dev/null; then
      return 0
    fi
  fi

  log "error: ${label} failed; see $log_file for details"
  return 1
}

detect_package_manager() {
  # owlmango is Arch-only: Mango (mangowm-git) and Wayle build cleanly there.
  if have pacman; then
    PKG_MANAGER="pacman"
    DISTRO="arch"
    return 0
  fi

  return 1
}

prepare_package_manager() {
  # Arch-only; pacman needs no pre-update step here (--needed handles freshness).
  :
}

ensure_pacman_keyring() {
  if [ "$PKG_MANAGER" != "pacman" ]; then
    return 0
  fi

  if ! have sudo || ! have pacman-key; then
    log "note: pacman-key not available; skipping keyring init"
    return 0
  fi

  keyring_dir="/etc/pacman.d/gnupg"
  pubring="$keyring_dir/pubring.gpg"
  if [ -f "$pubring" ]; then
    return 0
  fi

  log "initializing pacman keyring"
  if ! run_pkg_cmd pacman-key sudo pacman-key --init; then
    log "warning: pacman-key --init failed"
    return 0
  fi

  if ! run_pkg_cmd pacman-key sudo pacman-key --populate archlinux; then
    log "warning: pacman-key --populate failed"
  fi
}

pacman_install() {
  if ! have sudo || ! have pacman; then
    return 1
  fi

  run_pkg_cmd pacman sudo pacman -S --needed --noconfirm "$@"
}

pacman_remove() {
  if ! have sudo || ! have pacman; then
    return 1
  fi

  if ! pacman_has_pkg "$@"; then
    return 0
  fi

  run_pkg_cmd pacman sudo pacman -R --noconfirm "$@"
}

pacman_has_pkg() {
  for pkg in "$@"; do
    if ! pacman -Q "$pkg" >/dev/null 2>&1; then
      return 1
    fi
  done

  return 0
}

pacman_pkg_version() {
  pkg=$1

  if ! have pacman; then
    return 1
  fi

  pacman -Q "$pkg" 2>/dev/null | awk '{print $2}'
}

install_yay_bin() {
  if [ "$PKG_MANAGER" != "pacman" ]; then
    return 0
  fi

  if ! have sudo || ! have pacman; then
    return 0
  fi

  if pacman_has_pkg yay-bin; then
    return 0
  fi

  if pacman_has_pkg yay; then
    pacman_remove yay || true
  fi

  if ! have git || ! have makepkg; then
    log "note: git or makepkg missing; cannot install yay-bin"
    return 0
  fi

  local tmp_dir
  tmp_dir=$(mktemp -d)
  if ! git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp_dir/yay-bin" >/dev/null 2>&1; then
    log "warning: failed to clone yay-bin AUR repo"
    rm -rf "$tmp_dir"
    return 0
  fi

  if ! (cd "$tmp_dir/yay-bin" && makepkg -si --noconfirm) >/dev/null 2>&1; then
    log "warning: failed to build/install yay-bin"
    rm -rf "$tmp_dir"
    return 0
  fi

  rm -rf "$tmp_dir"
  log "installed yay-bin from AUR"
}

install_pkgs() {
  if [ "$PKG_MANAGER" = "pacman" ]; then
    pacman_install "$@"
    return $?
  fi

  return 1
}

read_pkg_list() {
  awk 'NF && $1 !~ /^#/' "$1"
}

filter_pkg_list() {
  pkg_list=$1
  printf '%s\n' "$pkg_list"
}

install_pkg_list() {
  local pkg_file="$1"
  local label="$2"
  local pkg_list=""

  if [ ! -f "$pkg_file" ]; then
    log "note: missing $pkg_file"
    return 1
  fi

  pkg_list=$(read_pkg_list "$pkg_file")
  pkg_list=$(filter_pkg_list "$pkg_list")
  if [ -z "$pkg_list" ]; then
    return 1
  fi

  set -- $pkg_list
  local pkg_summary="$*"
  if ! install_pkgs "$@"; then
    log "warning: some ${label} packages failed to install (this may be expected)"
  fi
  if [ "$PKG_MANAGER" = "pacman" ]; then
    log "installed ${label} packages via $PKG_MANAGER: $pkg_summary"
  else
    log "installed ${label} packages via $PKG_MANAGER"
  fi

  return 0
}

install_cli_packages() {
  local cli_pkgs_file="$REPO_ROOT/config/packages/$DISTRO/cli/packages.txt"

  if install_pkg_list "$cli_pkgs_file" "CLI"; then
    if ! have fish; then
      log "error: fish shell failed to install - this is a critical package"
      log "please install fish manually and re-run the installer"
      return 1
    fi
  fi
}

install_gui_packages() {
  if cli_only_enabled; then
    log "skipping GUI packages (--cli-only flag)"
    return 0
  fi

  local gui_pkgs_file="$REPO_ROOT/config/packages/$DISTRO/gui/packages.txt"
  install_pkg_list "$gui_pkgs_file" "GUI" || true
}

install_aur_pkgs() {
  if [ "$#" -eq 0 ]; then
    return 0
  fi

  if have paru; then
    run_pkg_cmd paru paru -S --needed --noconfirm "$@"
    log "installed/verified AUR packages (paru)"
  elif have yay; then
    run_pkg_cmd yay yay -S --needed --noconfirm "$@"
    log "installed/verified AUR packages (yay)"
  else
    log "warning: paru/yay not found; cannot install AUR packages:"
    printf '  %s\n' "$@"
    log "install paru or yay, then re-run installer"
    return 1
  fi

  return 0
}

load_aur_packages() {
  local aur_pkgs=""
  local file=""

  if [ "$#" -eq 0 ]; then
    return 0
  fi

  for file in "$@"; do
    if [ ! -f "$file" ]; then
      continue
    fi

    aur_pkgs="${aur_pkgs} $(read_pkg_list "$file")"
  done

  printf '%s\n' "$aur_pkgs" | awk 'NF'
}

aur_cli_files() {
  printf '%s\n' "$REPO_ROOT/config/packages/arch/cli/aur.txt"
}

aur_gui_files() {
  printf '%s\n' "$REPO_ROOT/config/packages/arch/gui/aur.txt"
}

install_aur_packages() {
  local aur_pkgs=""

  if [ "$PKG_MANAGER" != "pacman" ]; then
    return 0
  fi

  aur_pkgs=$(load_aur_packages $(aur_cli_files))
  if [ "${CLI_ONLY:-0}" = "0" ]; then
    aur_pkgs="$aur_pkgs $(load_aur_packages $(aur_gui_files))"
  fi

  aur_pkgs=$(printf '%s\n' "$aur_pkgs" | awk 'NF')
  if [ -z "$aur_pkgs" ]; then
    return 0
  fi

  set -- $aur_pkgs
  install_aur_pkgs "$@" || true
}

ensure_wheel_nopasswd() {
  if ! have sudo; then
    log "note: sudo not found; cannot configure wheel NOPASSWD"
    return 0
  fi

  if ! have visudo; then
    log "note: visudo not found; install sudo to validate sudoers"
    return 0
  fi

  local sudo_group="wheel"
  if grep -q "^sudo:" /etc/group 2>/dev/null; then
    sudo_group="sudo"
  fi

  tmp=$(mktemp)
  cat >"$tmp" <<EOF
%${sudo_group} ALL=(ALL:ALL) NOPASSWD: ALL

# Allow a small set of env vars for ${sudo_group} (useful for git signing, terminals, and editor tooling).
# Note: SSH uses SSH_AUTH_SOCK; SSH_AUTH_SOCKET is included for compatibility.
Defaults:%${sudo_group} env_keep += "SSH_AUTH_SOCK SSH_AUTH_SOCKET SSH_CONNECTION TERM EDITOR"
EOF
  sudo install -m 0440 -o root -g root "$tmp" /etc/sudoers.d/10-wheel-nopasswd
  rm -f "$tmp"

  sudo visudo -cf /etc/sudoers >/dev/null
  log "configured /etc/sudoers.d/10-wheel-nopasswd for %${sudo_group}"
}

install_packages() {
  if ! have sudo; then
    log "note: sudo not found; cannot install packages"
    return 0
  fi

  if ! detect_package_manager; then
    log "note: no supported package manager found (pacman)"
    log "owlmango targets Arch Linux / CachyOS"
    return 0
  fi

  init_pkg_logging

  log "detected package manager: $PKG_MANAGER"

  ensure_pacman_keyring
  prepare_package_manager
  install_cli_packages
  install_gui_packages

  install_custom_packages
  install_yay_bin
  install_aur_packages
}

install_custom_packages() {
  install_wayle || true
}

# Build and install the Wayle shell (wayle-mango fork) from source.
# The fork adds the mango-workspaces bar module and MangoWM detection, which
# the upstream `wayle-bin` AUR package does not carry. Skipped for --cli-only.
install_wayle() {
  if cli_only_enabled; then
    return 0
  fi

  if have wayle; then
    log "wayle already installed"
    return 0
  fi

  if ! have git; then
    log "warning: git missing; cannot build wayle"
    return 1
  fi

  ensure_rust_toolchain || return 1

  if ! have cargo; then
    log "warning: cargo unavailable after rustup setup; cannot build wayle"
    return 1
  fi

  log "building wayle from source ($WAYLE_REPO)"

  mkdir -p "$(dirname "$WAYLE_SRC_DIR")" >/dev/null 2>&1 || true

  if [ -d "$WAYLE_SRC_DIR/.git" ]; then
    git -C "$WAYLE_SRC_DIR" pull --ff-only >/dev/null 2>&1 || true
  elif ! git clone --depth 1 "$WAYLE_REPO" "$WAYLE_SRC_DIR" >/dev/null 2>&1; then
    log "warning: failed to clone wayle-mango repo"
    return 1
  fi

  if ! run_pkg_cmd cargo cargo install --path "$WAYLE_SRC_DIR/wayle" --locked; then
    log "warning: wayle build failed; see log in $PKG_LOG_DIR"
    return 1
  fi

  run_pkg_cmd cargo cargo install --path "$WAYLE_SRC_DIR/crates/wayle-settings" --locked || \
    log "note: wayle-settings build failed (optional GUI)"

  if have wayle; then
    wayle icons setup >/dev/null 2>&1 || true
    log "installed wayle (bar/notifications/OSD/wallpaper shell)"
  fi
}

# Ensure a usable Rust toolchain via rustup (installed as a repo package).
ensure_rust_toolchain() {
  if have cargo; then
    return 0
  fi

  if ! have rustup; then
    log "warning: rustup not installed; cannot provide cargo for wayle build"
    return 1
  fi

  log "initializing rust stable toolchain via rustup"
  rustup default stable >/dev/null 2>&1 || rustup toolchain install stable >/dev/null 2>&1 || true

  # rustup places cargo in ~/.cargo/bin; make it visible for the rest of the run.
  if [ -d "$HOME/.cargo/bin" ]; then
    case ":$PATH:" in
      *":$HOME/.cargo/bin:"*) : ;;
      *) PATH="$HOME/.cargo/bin:$PATH"; export PATH ;;
    esac
  fi

  have cargo
}

ensure_docker_group() {
  target_user=${SUDO_USER:-$USER}

  if [ -z "${target_user:-}" ]; then
    return 0
  fi

  if ! have sudo; then
    log "note: sudo not found; cannot add user to docker group"
    return 0
  fi

  if ! have getent; then
    log "note: getent not found; cannot check docker group"
    return 0
  fi

  if ! getent group docker >/dev/null 2>&1; then
    log "note: docker group missing; ensure docker package is installed"
    return 0
  fi

  if id -nG "$target_user" 2>/dev/null | grep -qw docker; then
    return 0
  fi

  log "adding $target_user to docker group"
  sudo usermod -aG docker "$target_user" >/dev/null 2>&1 || true
  log "note: re-login required for docker group to apply"
}

enable_docker_service() {
  if ! have sudo; then
    log "note: sudo not found; cannot enable docker service"
    return 0
  fi

  if ! have systemctl; then
    log "note: systemctl not found; cannot enable docker service"
    return 0
  fi

  if ! systemctl list-unit-files docker.service >/dev/null 2>&1; then
    log "note: docker service not available"
    return 0
  fi

  systemctl enable --now docker.service >/dev/null 2>&1 || true
  log "enabled docker service"
}

enable_user_linger() {
  if ! command -v loginctl >/dev/null 2>&1; then
    return 0
  fi

  linger=$(loginctl show-user "$USER" -p Linger 2>/dev/null | awk -F= '{print $2}' || true)
  if [ "${linger:-}" = "yes" ]; then
    return 0
  fi

  log "enabling systemd linger for $USER"
  if loginctl enable-linger "$USER" >/dev/null 2>&1; then
    :
  elif command -v sudo >/dev/null 2>&1; then
    sudo loginctl enable-linger "$USER" >/dev/null 2>&1 || true
  fi

  return 0
}

ensure_wheel_nopasswd
install_packages
enable_docker_service
ensure_docker_group

install_fingerprint_enabled() {
  if have sudo && have pacman; then
    pacman_install fprintd || true
    log "installed fprintd for fingerprint authentication"
  fi

  pacman_remove swaylock 2>/dev/null || true
  install_aur_pkgs swaylock-fprintd-git || true
}

install_fingerprint_disabled() {
  if have sudo && have pacman; then
    pacman_remove swaylock-fprintd-git 2>/dev/null || true
    pacman_install swaylock || true
    log "installed swaylock without fingerprint authentication"
  fi
}

configure_fingerprint_packages() {
  if cli_only_enabled; then
    log "skipping fingerprint/swaylock packages (--cli-only flag)"
    return 0
  fi

  if [ "${FINGERPRINT:-0}" = "1" ]; then
    install_fingerprint_enabled
    return 0
  fi

  install_fingerprint_disabled
}

configure_fingerprint_packages
