#!/usr/bin/env sh
set -eu

repo_root=${REPO_ROOT:?}
ts=${TS:?}
login_user=${LOGIN_USER:-}

if [ "${NO_ROOT:-0}" = "1" ]; then
  printf '%s\n' "skipping root customizations (--no-root flag)"
  exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    exec sudo env REPO_ROOT="$REPO_ROOT" TS="$TS" LOGIN_USER="$USER" FINGERPRINT="${FINGERPRINT:-0}" CLI_ONLY="${CLI_ONLY:-0}" sh "$REPO_ROOT/install/stages/20-root.sh"
  fi
  echo "error: root stage requires sudo" >&2
  exit 1
fi

state_root=${XDG_STATE_HOME:-/root/.local/state}
backup_root="$state_root/config-backups/$ts"
mkdir -p "$backup_root"

backup_path() {
  p=$1
  if [ -e "$p" ] || [ -L "$p" ]; then
    base=$(basename -- "$p")
    mv "$p" "$backup_root/$base" >/dev/null 2>&1 || true
  fi
}

configure_iwd() {
  iwd_src="$repo_root/config/iwd/main.conf"
  iwd_dst="/etc/iwd/main.conf"

  [ -f "$iwd_src" ] || return 0

  mkdir -p /etc/iwd
  if [ -f "$iwd_dst" ]; then
    mkdir -p "$backup_root/iwd"
    cp "$iwd_dst" "$backup_root/iwd/main.conf" >/dev/null 2>&1 || true
  fi

  cp "$iwd_src" "$iwd_dst"
  chmod 644 "$iwd_dst"
  echo "configured iwd main.conf"
}

configure_systemd_networkd() {
  network_src="$repo_root/config/systemd/network"

  [ -d "$network_src" ] || return 0

  mkdir -p /etc/systemd/network
  for f in "$network_src"/*.network "$network_src"/*.netdev "$network_src"/*.link; do
    [ -f "$f" ] || continue
    bn=$(basename -- "$f")
    dst="/etc/systemd/network/$bn"

    if [ -f "$dst" ] || [ -L "$dst" ]; then
      mkdir -p "$backup_root/systemd-network"
      cp "$dst" "$backup_root/systemd-network/$bn" >/dev/null 2>&1 || true
    fi

    cp "$f" "$dst"
    chmod 644 "$dst"
  done

  if command -v systemctl >/dev/null 2>&1; then
    systemctl enable systemd-networkd.service >/dev/null 2>&1 || true
  fi
  echo "configured systemd-networkd for wired"
}

configure_resolv_conf() {
  resolv_conf="/etc/resolv.conf"
  resolved_stub="/run/systemd/resolve/stub-resolv.conf"
  resolved_resolv="/run/systemd/resolve/resolv.conf"

  target=""
  if [ -f "$resolved_stub" ]; then
    target="$resolved_stub"
  elif [ -f "$resolved_resolv" ]; then
    target="$resolved_resolv"
  else
    return 0
  fi

  if [ -L "$resolv_conf" ]; then
    current=$(readlink -f "$resolv_conf" 2>/dev/null || true)
    if [ "$current" = "$target" ]; then
      return 0
    fi
  fi

  if [ -e "$resolv_conf" ] || [ -L "$resolv_conf" ]; then
    mkdir -p "$backup_root/systemd-resolved"
    mv "$resolv_conf" "$backup_root/systemd-resolved/resolv.conf" >/dev/null 2>&1 || true
  fi

  ln -sfn "$target" "$resolv_conf"
}

configure_systemd_resolved() {
  resolved_src="$repo_root/config/systemd/resolved.conf.d"

  [ -d "$resolved_src" ] || return 0

  mkdir -p /etc/systemd/resolved.conf.d
  for f in "$resolved_src"/*.conf; do
    [ -f "$f" ] || continue
    bn=$(basename -- "$f")
    dst="/etc/systemd/resolved.conf.d/$bn"

    if [ -f "$dst" ] || [ -L "$dst" ]; then
      mkdir -p "$backup_root/systemd-resolved"
      cp "$dst" "$backup_root/systemd-resolved/$bn" >/dev/null 2>&1 || true
    fi

    cp "$f" "$dst"
    chmod 644 "$dst"
  done

  if command -v systemctl >/dev/null 2>&1; then
    systemctl enable --now systemd-resolved.service >/dev/null 2>&1 || true
    systemctl restart systemd-resolved.service >/dev/null 2>&1 || true
  fi

  configure_resolv_conf
  echo "configured systemd-resolved"
}

configure_dnsmasq() {
  dnsmasq_src="$repo_root/config/dnsmasq.d"
  dnsmasq_conf="/etc/dnsmasq.conf"
  confdir_line="conf-dir=/etc/dnsmasq.d/,*.conf"

  [ -d "$dnsmasq_src" ] || return 0

  if [ -f "$dnsmasq_conf" ]; then
    if ! grep -q "^${confdir_line}$" "$dnsmasq_conf" 2>/dev/null; then
      mkdir -p "$backup_root/dnsmasq"
      cp "$dnsmasq_conf" "$backup_root/dnsmasq/dnsmasq.conf" >/dev/null 2>&1 || true
      if grep -q "^conf-dir=/etc/dnsmasq.d,.conf$" "$dnsmasq_conf" 2>/dev/null; then
        sed -i "s|^conf-dir=/etc/dnsmasq.d,.conf$|$confdir_line|" "$dnsmasq_conf"
      else
        printf '%s\n' "$confdir_line" >>"$dnsmasq_conf"
      fi
    fi
  else
    printf '%s\n' "$confdir_line" >"$dnsmasq_conf"
    chmod 644 "$dnsmasq_conf"
  fi

  mkdir -p /etc/dnsmasq.d
  for f in "$dnsmasq_src"/*.conf; do
    [ -f "$f" ] || continue
    bn=$(basename -- "$f")
    dst="/etc/dnsmasq.d/$bn"

    if [ -f "$dst" ] || [ -L "$dst" ]; then
      mkdir -p "$backup_root/dnsmasq"
      cp "$dst" "$backup_root/dnsmasq/$bn" >/dev/null 2>&1 || true
    fi

    cp "$f" "$dst"
    chmod 644 "$dst"
  done

  if command -v systemctl >/dev/null 2>&1; then
    systemctl enable --now dnsmasq.service >/dev/null 2>&1 || true
    systemctl restart dnsmasq.service >/dev/null 2>&1 || true
  fi

  echo "configured dnsmasq for .test"
}

configure_sshd() {
  sshd_src="$repo_root/config/ssh/sshd_config.d/20-owlmango.conf"
  sshd_dst="/etc/ssh/sshd_config.d/20-owlmango.conf"
  sshd_main="/etc/ssh/sshd_config"

  [ -f "$sshd_src" ] || return 0

  if ! command -v sshd >/dev/null 2>&1; then
    echo "note: openssh not installed; skipping sshd setup"
    return 0
  fi

  mkdir -p /etc/ssh/sshd_config.d
  if [ -f "$sshd_dst" ]; then
    mkdir -p "$backup_root/sshd"
    cp "$sshd_dst" "$backup_root/sshd/20-owlmango.conf" >/dev/null 2>&1 || true
  fi

  cp "$sshd_src" "$sshd_dst"
  chmod 644 "$sshd_dst"

  # Stock Arch sshd_config includes sshd_config.d; add the Include for configs
  # that lack it. It must be the first directive because sshd keeps the first
  # value it sees for each option.
  if [ -f "$sshd_main" ] && ! grep -q '^Include /etc/ssh/sshd_config.d' "$sshd_main" 2>/dev/null; then
    mkdir -p "$backup_root/sshd"
    cp "$sshd_main" "$backup_root/sshd/sshd_config" >/dev/null 2>&1 || true
    sed -i '1i Include /etc/ssh/sshd_config.d/*.conf' "$sshd_main"
  fi

  if command -v systemctl >/dev/null 2>&1; then
    systemctl enable --now sshd.service >/dev/null 2>&1 || true
  fi
  echo "enabled sshd with password authentication"
}

disable_networkmanager() {
  if command -v systemctl >/dev/null 2>&1; then
    systemctl disable --now NetworkManager.service >/dev/null 2>&1 || true
  fi
  echo "disabled NetworkManager"
}

src_conf="$repo_root/config/fish/conf.d"
src_fn="$repo_root/config/fish/functions"

dst_base=/root/.config/fish
dst_conf="$dst_base/conf.d"
dst_fn="$dst_base/functions"

mkdir -p "$dst_conf" "$dst_fn"

cat > "$dst_base/config.fish" <<'EOF'
set -g fish_greeting

if status is-interactive
end
EOF

conf_files="00-colors.fish prompt.fish pager.fish adwaita-dark.fish fish_frozen_theme.fish fish_frozen_key_bindings.fish"
fn_files="fish_prompt.fish fish_right_prompt.fish fish_mode_prompt.fish __adw_prompt_update_git.fish"

for f in $conf_files; do
  [ -f "$src_conf/$f" ] || continue
  if [ -e "$dst_conf/$f" ] || [ -L "$dst_conf/$f" ]; then
    mkdir -p "$backup_root/fish-conf.d"
    mv "$dst_conf/$f" "$backup_root/fish-conf.d/$f" >/dev/null 2>&1 || true
  fi
  ln -sfn "$src_conf/$f" "$dst_conf/$f"
done

for f in $fn_files; do
  [ -f "$src_fn/$f" ] || continue
  if [ -e "$dst_fn/$f" ] || [ -L "$dst_fn/$f" ]; then
    mkdir -p "$backup_root/fish-functions"
    mv "$dst_fn/$f" "$backup_root/fish-functions/$f" >/dev/null 2>&1 || true
  fi
  ln -sfn "$src_fn/$f" "$dst_fn/$f"
done

backup_path /root/.config/bat
ln -sfn "$repo_root/config/bat" /root/.config/bat

backup_path /root/.config/btop
ln -sfn "$repo_root/config/btop" /root/.config/btop

if command -v bat >/dev/null 2>&1; then
  bat cache --build >/dev/null 2>&1 || true
fi

faillock_src="$repo_root/config/security/faillock.conf"
faillock_dst="/etc/security/faillock.conf"

if [ -f "$faillock_src" ]; then
  if [ -f "$faillock_dst" ]; then
    mkdir -p "$backup_root"
    cp "$faillock_dst" "$backup_root/faillock.conf" >/dev/null 2>&1 || true
  fi

  cp "$faillock_src" "$faillock_dst"
  chmod 644 "$faillock_dst"
  echo "configured faillock: account lockout disabled"
fi

greetd_cfg="/etc/greetd/config.toml"
greetd_src="$repo_root/config/greetd/config.toml"

if [ "${CLI_ONLY:-0}" = "1" ]; then
  echo "skipping greetd GUI login setup (--cli-only flag)"
elif [ -n "$login_user" ] && [ -f "$greetd_src" ]; then
  mkdir -p /etc/greetd

  if [ -f "$greetd_cfg" ]; then
    mkdir -p "$backup_root"
    cp "$greetd_cfg" "$backup_root/greetd-config.toml" >/dev/null 2>&1 || true
  fi

  sed "s/_USER_/$login_user/g" "$greetd_src" > "$greetd_cfg"
  chmod 644 "$greetd_cfg"

  for dm in gdm sddm lightdm ly; do
    systemctl disable "$dm.service" >/dev/null 2>&1 || true
  done

  # greetd is pulled in by graphical.target; minimal installs may default to
  # multi-user.target, which boots to a console login even with greetd enabled.
  systemctl set-default graphical.target >/dev/null 2>&1 || true

  if systemctl enable greetd.service >/dev/null 2>&1; then
    echo "configured greetd autologin for $login_user"
  else
    echo "warning: failed to enable greetd.service; boot will stop at a console login"
    echo "         (is the greetd package installed? it is skipped by --cli-only runs)"
  fi

  if ! command -v mango >/dev/null 2>&1; then
    echo "warning: mango compositor not found; greetd has nothing to launch"
    echo "         (mangowm-git installs from the AUR - check the AUR stage output)"
  fi
fi

if [ "${FINGERPRINT:-0}" = "1" ]; then
  systemctl enable fprintd.service >/dev/null 2>&1 || true
  echo "enabled fprintd service for fingerprint authentication"
  echo ""
  echo "NOTE: To enroll fingerprints, run:"
  echo "  fprintd-enroll"
else
  if command -v fprintd-list >/dev/null 2>&1 && [ -n "$login_user" ]; then
    if ! fprintd-list "$login_user" 2>/dev/null | grep -q "finger"; then
      systemctl disable fprintd.service >/dev/null 2>&1 || true
    fi
  fi
fi

# owlmango keeps bash as the default login shell everywhere (user and root).
# fish and nushell are installed and available to opt into interactively
# (e.g. `exec fish`), but the login shell is left as bash.
echo "leaving root login shell as bash (owlmango default)"

configure_sshd
configure_iwd
configure_systemd_networkd
configure_systemd_resolved
configure_dnsmasq
disable_networkmanager

