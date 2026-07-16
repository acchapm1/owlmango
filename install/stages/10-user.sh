#!/usr/bin/env sh
set -eu

repo_root=${REPO_ROOT:?}
cfg_root=${CFG_ROOT:?}
backup_root=${BACKUP_ROOT:?}

log() { printf '%s\n' "$*"; }

should_merge_dir() {
  tool=$1
  case "$tool" in
    gtk-3.0|xdg-desktop-portal)
      return 1
      ;;
  esac
  return 0
}

backup_path() {
  p=$1
  if [ -L "$p" ] || [ -e "$p" ]; then
    mkdir -p "$backup_root"
    base=$(basename -- "$p")
    mv "$p" "$backup_root/$base"
  fi
}

merge_dir() {
  src=$1
  dst=$2
  shift 2
  [ -d "$src" ] || return 0
  mkdir -p "$dst"
  rsync -a --ignore-existing "$@" "$src/" "$dst/" >/dev/null 2>&1 || true
}

link_dir() {
  tool=$1
  src="$repo_root/config/$tool"
  dst="$cfg_root/$tool"

  [ -d "$src" ] || return 0

  if should_merge_dir "$tool"; then
    if [ -d "$dst" ] && [ ! -L "$dst" ]; then
      merge_dir "$dst" "$src"
    fi
  fi

  if [ -L "$dst" ]; then
    cur=$(readlink -f "$dst" 2>/dev/null || true)
    if [ "$cur" = "$src" ]; then
      ln -sfn "$src" "$dst"
      return 0
    fi
  fi

  backup_path "$dst"
  ln -s "$src" "$dst"
  log "linked $dst -> $src"
}


link_gui_dir() {
  if [ "${CLI_ONLY:-0}" = "1" ]; then
    return 0
  fi
  link_dir "$@"
}


mkdir -p "$cfg_root"
mkdir -p "$backup_root"

if [ "${CLI_ONLY:-0}" = "0" ]; then
  ws_src="$repo_root/config/wayland-sessions"
  ws_dst="$HOME/.local/share/wayland-sessions"
  if [ -d "$ws_src" ]; then
    mkdir -p "$ws_dst"
    for f in "$ws_src"/*.desktop; do
      [ -e "$f" ] || continue
      bn=$(basename -- "$f")
      dst="$ws_dst/$bn"

      if [ -e "$dst" ] || [ -L "$dst" ]; then
        mkdir -p "$backup_root/wayland-sessions"
        mv "$dst" "$backup_root/wayland-sessions/$bn" >/dev/null 2>&1 || true
      fi

      ln -sfn "$f" "$dst"
    done
    log "linked wayland-sessions entries"
  fi
fi

bin_src="$repo_root/bin"
bin_dst="$HOME/.local/bin"
if [ -d "$bin_src" ]; then
  mkdir -p "$bin_dst"
  for f in "$bin_src"/*; do
    [ -e "$f" ] || continue
    bn=$(basename -- "$f")
    dst="$bin_dst/$bn"

    if [ -L "$dst" ]; then
      cur=$(readlink -f "$dst" 2>/dev/null || true)
      if [ "$cur" = "$f" ]; then
        ln -sfn "$f" "$dst"
        continue
      fi
    fi

    if [ -e "$dst" ] || [ -L "$dst" ]; then
      mkdir -p "$backup_root/local-bin"
      mv "$dst" "$backup_root/local-bin/$bn" >/dev/null 2>&1 || true
    fi

    ln -sfn "$f" "$dst"
  done
fi

if [ "${CLI_ONLY:-0}" = "0" ]; then
ssh_home="$HOME/.ssh"
ssh_cfg="$ssh_home/config"
ssh_gitignore="$ssh_home/.gitignore"
ssh_repo_cfg="$repo_root/config/ssh/config"
ssh_repo_gitignore="$repo_root/config/ssh/.gitignore"

if [ -L "$ssh_home" ]; then
  ssh_target=$(readlink -f "$ssh_home" 2>/dev/null || true)
  cfg_target=$(readlink -f "$cfg_root/ssh" 2>/dev/null || true)

  if [ -n "${ssh_target:-}" ] && [ -n "${cfg_target:-}" ] && [ "$ssh_target" = "$cfg_target" ]; then
    log "migrating ~/.ssh from symlink to real directory"
    mkdir -p "$backup_root/ssh"

    mkdir -p "$ssh_home.tmp"
    chmod 700 "$ssh_home.tmp" >/dev/null 2>&1 || true
    rsync -a --remove-source-files --exclude 'config' --exclude 'config.d' --exclude '.gitignore' "$ssh_target/" "$ssh_home.tmp/" >/dev/null 2>&1 || true

    mv "$ssh_home" "$backup_root/ssh/ssh-symlink" >/dev/null 2>&1 || true
    mv "$ssh_home.tmp" "$ssh_home" >/dev/null 2>&1 || true
    chmod 700 "$ssh_home" >/dev/null 2>&1 || true
  fi
fi

mkdir -p "$ssh_home" >/dev/null 2>&1 || true
chmod 700 "$ssh_home" >/dev/null 2>&1 || true

are_hardlinked() {
  f1=$1
  f2=$2
  [ -f "$f1" ] && [ -f "$f2" ] || return 1
  inode1=$(stat -c %i "$f1" 2>/dev/null || echo "0")
  inode2=$(stat -c %i "$f2" 2>/dev/null || echo "0")
  [ "$inode1" != "0" ] && [ "$inode1" = "$inode2" ]
}

link_or_copy_ssh_file() {
  src_file=$1
  dst_file=$2

  if ln "$src_file" "$dst_file" >/dev/null 2>&1; then
    log "hardlinked ~/.ssh/$(basename "$dst_file") to repo"
    return 0
  fi

  if cp -f "$src_file" "$dst_file" >/dev/null 2>&1; then
    log "copied ~/.ssh/$(basename "$dst_file") from repo"
    return 0
  fi

  log "warning: failed to link ~/.ssh/$(basename "$dst_file")"
  return 0
}

for src_file in "$ssh_repo_cfg" "$ssh_repo_gitignore"; do
  [ -f "$src_file" ] || continue

  base=$(basename "$src_file")
  dst_file="$ssh_home/$base"

  if are_hardlinked "$src_file" "$dst_file"; then
    log "~/.ssh/$base already hardlinked to repo"
    continue
  fi

  if [ -f "$dst_file" ] || [ -L "$dst_file" ]; then
    mkdir -p "$backup_root/ssh"
    mv "$dst_file" "$backup_root/ssh/$base" >/dev/null 2>&1 || true
    log "backed up existing ~/.ssh/$base"
  fi

  link_or_copy_ssh_file "$src_file" "$dst_file"
done
fi

link_dir bat
link_dir btop
link_dir fzf
link_dir git
link_dir htop
link_dir nvim

link_gui_dir ghostty
link_gui_dir bluetui
link_gui_dir elephant
link_gui_dir gtk-3.0
link_gui_dir gtk-4.0
link_gui_dir impala
link_gui_dir wayle
link_gui_dir xdg-desktop-portal
link_gui_dir qt5ct

# Mango compositor configuration
configure_mango() {
  if [ "${CLI_ONLY:-0}" = "1" ]; then
    return 0
  fi

  link_gui_dir mango

  # Seed a machine-specific host.conf (sourced by config.conf via source-optional).
  local mango_host="$cfg_root/mango/host.conf"
  if [ ! -f "$mango_host" ]; then
    cat > "$mango_host" << 'HOSTEOF'
# Host-specific Mango configuration
# Not tracked in git — customize for this machine.
# Example monitor rule:
#   monitorrule=eDP-1,0.55,1,tile,0,1.0,0,0,1920,1080,60.0
HOSTEOF
    log "created $mango_host"
  fi
}

# Wayle shell configuration
configure_wayle() {
  if [ "${CLI_ONLY:-0}" = "1" ]; then
    return 0
  fi

  link_gui_dir wayle
}

configure_swaylock() {
  if [ "${CLI_ONLY:-0}" = "1" ]; then
    return 0
  fi

  link_gui_dir swaylock

  # Manage fingerprint authentication (only if GUI enabled)
  swaylock_cfg="$cfg_root/swaylock/config"
  if [ "${FINGERPRINT:-0}" = "1" ]; then
    # Enable fingerprint if not already present
    if [ -f "$swaylock_cfg" ] && ! grep -q "^fingerprint" "$swaylock_cfg" 2>/dev/null; then
      printf '\n# Fingerprint authentication\nfingerprint\n' >> "$swaylock_cfg"
      log "enabled fingerprint authentication for swaylock"
    fi
  else
    # Remove fingerprint config if it was previously added
    if [ -f "$swaylock_cfg" ] && grep -q "^fingerprint" "$swaylock_cfg" 2>/dev/null; then
      sed -i '/^# Fingerprint authentication$/d; /^fingerprint$/d' "$swaylock_cfg"
      # Clean up trailing empty lines
      sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$swaylock_cfg" 2>/dev/null || true
      log "disabled fingerprint authentication for swaylock"
    fi
  fi
}

link_gui_dir qt6ct
link_gui_dir swayidle

link_gui_dir theme
link_gui_dir upower
link_gui_dir uwsm
link_gui_dir walker
link_gui_dir wiremix
link_dir zed

# OpenCode: avoid importing runtime/state.
if [ -d "$cfg_root/opencode" ] && [ ! -L "$cfg_root/opencode" ]; then
  merge_dir "$cfg_root/opencode" "$repo_root/config/opencode" \
    --exclude 'node_modules' \
    --exclude 'log' \
    --exclude 'storage' \
    --exclude 'snapshot' \
    --exclude 'tool-output' \
    --exclude 'bin' \
    --exclude 'auth.json'
fi
backup_path "$cfg_root/opencode"
ln -s "$repo_root/config/opencode" "$cfg_root/opencode"
log "linked $cfg_root/opencode -> $repo_root/config/opencode"

# Fish: avoid importing generated state.
if [ -d "$cfg_root/fish" ] && [ ! -L "$cfg_root/fish" ]; then
  merge_dir "$cfg_root/fish" "$repo_root/config/fish" \
    --exclude 'fish_variables' \
    --exclude 'fish_plugins'
fi
backup_path "$cfg_root/fish"
ln -s "$repo_root/config/fish" "$cfg_root/fish"
log "linked $cfg_root/fish -> $repo_root/config/fish"

# Mango compositor configuration
configure_mango

# Wayle shell configuration
configure_wayle

# Swaylock configuration
configure_swaylock

# Systemd user units: link files (don’t replace whole ~/.config/systemd).
unit_src="$repo_root/config/systemd/user"
unit_dst="$cfg_root/systemd/user"
if [ -d "$unit_src" ]; then
  mkdir -p "$unit_dst"



  # List of CLI-only services (non-GUI)
  cli_services="gnome-keyring-daemon.service"

  is_cli_systemd_unit() {
    candidate=$1
    for cli_svc in $cli_services; do
      if [ "$candidate" = "$cli_svc" ]; then
        return 0
      fi
    done
    [ "$candidate" = "scripts" ]
  }

  for f in "$unit_src"/*; do
    bn=$(basename "$f")

    # Skip GUI services if --cli-only flag is set
    if [ "${CLI_ONLY:-0}" = "1" ] && ! is_cli_systemd_unit "$bn"; then
      continue
    fi

    if [ -e "$unit_dst/$bn" ] || [ -L "$unit_dst/$bn" ]; then
      mkdir -p "$backup_root/systemd-user"
      mv "$unit_dst/$bn" "$backup_root/systemd-user/$bn" >/dev/null 2>&1 || true
    fi
    ln -sfn "$f" "$unit_dst/$bn"
  done

  systemctl --user daemon-reload >/dev/null 2>&1 || true

  # Enable service units
  for f in "$unit_src"/*.service; do
    [ -f "$f" ] || continue
    unit=$(basename "$f")

    # Skip GUI services if --cli-only flag is set
    if [ "${CLI_ONLY:-0}" = "1" ] && ! is_cli_systemd_unit "$unit"; then
      continue
    fi

    systemctl --user enable "$unit" >/dev/null 2>&1 || true
  done

  if [ "${CLI_ONLY:-0}" = "1" ]; then
    log "enabled CLI systemd user services (--cli-only)"
  else
    log "enabled systemd user services"
  fi

  # Keyring: use our user unit (auto-unlock) and disable socket activation.
  systemctl --user disable --now gnome-keyring-autounlock.service >/dev/null 2>&1 || true
  # gnome-keyring-daemon.socket may be enabled globally; mask it per-user to avoid conflicts.
  systemctl --user mask gnome-keyring-daemon.socket >/dev/null 2>&1 || true

  # SSH agent: enable gcr-ssh-agent socket (sets SSH_AUTH_SOCK automatically).
  systemctl --user enable gcr-ssh-agent.socket >/dev/null 2>&1 || true
  systemctl --user start gcr-ssh-agent.socket >/dev/null 2>&1 || true
  log "enabled gcr-ssh-agent for SSH authentication"
fi

# Ensure secrets directory exists (key file is user-provided).
mkdir -p "$cfg_root/secrets"
chmod 700 "$cfg_root/secrets" >/dev/null 2>&1 || true

# SSH secrets and config.local (skip if --cli-only)
if [ "${CLI_ONLY:-0}" = "0" ]; then
  # SSH secrets: host-specific overrides and optional key storage.
  mkdir -p "$cfg_root/secrets/ssh/config.d" >/dev/null 2>&1 || true
  chmod 700 "$cfg_root/secrets/ssh" "$cfg_root/secrets/ssh/config.d" >/dev/null 2>&1 || true

  # Create ~/.ssh/config.local if it doesn't exist (for local includes/overrides)
  ssh_cfg_local="$ssh_home/config.local"
  if [ ! -f "$ssh_cfg_local" ]; then
    umask 077
    touch "$ssh_cfg_local"
    chmod 600 "$ssh_cfg_local" >/dev/null 2>&1 || true
    log "created ~/.ssh/config.local for local SSH overrides"
  fi
fi

key_file="$cfg_root/secrets/gnome-keyring.key"
keyrings_dir="$HOME/.local/share/keyrings"

# Clean up a broken user override that can conflict with Secret Service.
# (This file is not a valid systemd unit on many systems.)
bad_secrets_unit="$cfg_root/systemd/user/org.freedesktop.secrets.service"
if [ -f "$bad_secrets_unit" ]; then
  if grep -q '^\[D-BUS Service\]' "$bad_secrets_unit" 2>/dev/null; then
    mkdir -p "$backup_root/systemd-user-extra"
    mv "$bad_secrets_unit" "$backup_root/systemd-user-extra/org.freedesktop.secrets.service" >/dev/null 2>&1 || true
    systemctl --user disable --now org.freedesktop.secrets.service >/dev/null 2>&1 || true
    systemctl --user daemon-reload >/dev/null 2>&1 || true
    log "removed broken user org.freedesktop.secrets.service override"
  fi
fi

# If no key exists, generate one and reinitialize GNOME keyrings.
if [ ! -f "$key_file" ]; then
  log "generating $key_file and reinitializing GNOME keyrings"

  umask 077
  mkdir -p "$cfg_root/secrets"
  head -c 32 /dev/urandom | base64 >"$key_file"
  chmod 600 "$key_file" >/dev/null 2>&1 || true

  if [ -e "$keyrings_dir" ]; then
    mkdir -p "$backup_root"
    mv "$keyrings_dir" "$backup_root/keyrings" >/dev/null 2>&1 || true
  fi
  mkdir -p "$keyrings_dir"
  chmod 700 "$keyrings_dir" >/dev/null 2>&1 || true

  # Ensure the login keyring is the default.
  printf '%s\n' login >"$keyrings_dir/default"

  # Create a fresh login.keyring by unlocking once with the generated key.
  # Only attempt if graphical session is active (uwsm running), otherwise skip
  # and let the service handle it on next login.
  runtime_dir=${XDG_RUNTIME_DIR:-"/run/user/$(id -u)"}
  if systemctl --user is-active graphical-session-pre.target >/dev/null 2>&1; then
    systemctl --user stop gnome-keyring-daemon.service >/dev/null 2>&1 || true
    systemctl --user start gnome-keyring-daemon.service >/dev/null 2>&1 || true
    cat "$key_file" | gnome-keyring-daemon --unlock --control-directory="$runtime_dir/keyring" >/dev/null 2>&1 || true
  else
    # No graphical session, just run gnome-keyring-daemon directly to initialize
    cat "$key_file" | gnome-keyring-daemon --unlock --control-directory="$runtime_dir/keyring" >/dev/null 2>&1 || true
  fi
fi

# If keyrings exist but no default is set, make login the default.
if [ -d "$keyrings_dir" ] && [ -f "$keyrings_dir/login.keyring" ] && [ ! -f "$keyrings_dir/default" ]; then
  umask 077
  printf '%s\n' login >"$keyrings_dir/default"
fi

# Elephant: enable the service for walker app launcher.
# (service starts automatically with graphical-session.target via uwsm)
if command -v elephant >/dev/null 2>&1; then
  elephant service enable >/dev/null 2>&1 || true
  log "enabled elephant service"
fi

# Walker: enable the service for faster launcher startup (skip if --cli-only)
# (service starts automatically with graphical-session.target via uwsm)
if [ "${CLI_ONLY:-0}" = "0" ]; then
  systemctl --user enable walker.service >/dev/null 2>&1 || true
  log "enabled walker service"
fi

# Bat: rebuild cache for custom themes.
if command -v bat >/dev/null 2>&1; then
  bat cache --build >/dev/null 2>&1 || true
fi

# GTK/GNOME settings: set icon theme, GTK theme, color scheme, and fonts.
if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans 11' >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface document-font-name 'Adwaita Sans 11' >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface monospace-font-name 'Adwaita Mono 10' >/dev/null 2>&1 || true
  log "applied GTK/GNOME theme settings"
fi

# Set Zen Browser as the default browser.
if command -v xdg-settings >/dev/null 2>&1; then
  xdg-settings set default-web-browser zen.desktop >/dev/null 2>&1 || true
  log "set Zen Browser as default browser"
fi

# Flatpak: configure to follow system theme (dark mode).
if command -v flatpak >/dev/null 2>&1; then
  flatpak override --user --env=ADW_DEBUG_COLOR_SCHEME=prefer-dark >/dev/null 2>&1 || true
  flatpak override --user --env=XDG_CURRENT_DESKTOP=GNOME >/dev/null 2>&1 || true
  flatpak override --user --filesystem=xdg-config/gtk-3.0:ro >/dev/null 2>&1 || true
  flatpak override --user --filesystem=xdg-config/gtk-4.0:ro >/dev/null 2>&1 || true
  flatpak override --user --filesystem=xdg-run/keyring >/dev/null 2>&1 || true
  flatpak override --user --talk-name=org.freedesktop.portal.Desktop >/dev/null 2>&1 || true
  flatpak override --user --talk-name=org.freedesktop.secrets >/dev/null 2>&1 || true
  flatpak override --user --talk-name=org.gnome.keyring >/dev/null 2>&1 || true
  log "configured flatpak for dark theme and keyring access"
fi
