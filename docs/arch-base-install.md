# Arch Linux Base Install for owlmango

This guide takes a machine from the Arch ISO to a system where the owlmango
installer (`install/install.sh` bootstrap or `./install/local`) runs to
completion — including the AUR steps, which have prerequisites a stock Arch
base install does not include.

## What the installer requires (and why)

| Requirement | Why the installer needs it |
|---|---|
| Arch Linux / CachyOS (pacman) | owlmango is Arch-only; the system stage exits early without pacman |
| A regular user in `wheel`, **not root** | `makepkg` refuses to run as root; AUR builds (`yay-bin`, `mangowm-git`, …) fail silently when the installer runs as root |
| `sudo` | Every privileged step uses sudo; without it the installer skips package installation entirely |
| `base-devel` | Provides `makepkg`, `fakeroot`, `debugedit` — required to build `yay-bin` and all AUR packages. **Not in the CLI package list**, so it must exist before the installer runs (see the yay warning below) |
| `git` | Cloning the repo, AUR package repos, and the wayle-mango source |
| Working network | Package downloads, AUR clones, the Wayle source build |
| `networkmanager` (GUI installs) | Wayle's network module; enable it during base install so first boot has connectivity |

> **Pre-install `yay-bin` or `paru`, not `yay`.** The installer standardizes
> on `yay-bin`: an installed `yay-bin` (or `paru`) is left untouched, but an
> installed `yay` package is swapped for `yay-bin` once the replacement has
> built successfully (`install/stages/00-system.sh`, `install_yay_bin`). That
> build needs `base-devel` and a non-root user, so have both in place before
> running the installer.

## Part 1 — Install the base OS

Two paths. `archinstall` is faster; the manual path shows exactly what must be
present at the end.

### Option A: archinstall (recommended)

Boot the Arch ISO, connect to the network (`iwctl` for Wi‑Fi), then:

```bash
archinstall
```

Choose whatever disk/filesystem layout you like; these selections are the ones
that matter for owlmango:

- **Profile:** Minimal (owlmango installs the desktop itself — do not pick a
  desktop profile)
- **Audio:** pipewire (the GUI package list expects it)
- **Network configuration:** *Use NetworkManager*
- **User account:** create a regular user and answer **yes** to superuser
  (sudo/wheel)
- **Additional packages:** `base-devel git sudo neovim`

Reboot into the installed system and continue with Part 2.

### Option B: Manual install

Boot the ISO, connect to the network, and partition for UEFI (adjust device
names; this example uses `/dev/nvme0n1` with an EFI partition and a root
partition):

```bash
# Partition: 1 GiB EFI (type ef00) + rest root (type 8300), e.g. with:
cfdisk /dev/nvme0n1

mkfs.fat -F32 /dev/nvme0n1p1
mkfs.ext4 /dev/nvme0n1p2

mount /dev/nvme0n1p2 /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot
```

Install the base system **including the owlmango prerequisites**:

```bash
pacstrap -K /mnt base base-devel linux linux-firmware \
  networkmanager git sudo neovim
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
```

Inside the chroot:

```bash
# Time and locale
ln -sf /usr/share/zoneinfo/America/Phoenix /etc/localtime
hwclock --systohc
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

# Hostname
echo 'owlmango-box' > /etc/hostname

# Root password
passwd

# Regular user in wheel (the installer must run as this user, never root)
useradd -mG wheel alan
passwd alan

# Give wheel sudo (the installer later adds NOPASSWD via /etc/sudoers.d/)
EDITOR=nvim visudo   # uncomment: %wheel ALL=(ALL:ALL) ALL

# Bootloader (systemd-boot, UEFI)
bootctl install
cat > /boot/loader/entries/arch.conf <<EOF
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=$(blkid -s PARTUUID -o value /dev/nvme0n1p2) rw
EOF
echo 'default arch.conf' > /boot/loader/loader.conf

# Network on first boot
systemctl enable NetworkManager

exit
```

Then `umount -R /mnt && reboot`.

## Part 2 — First-boot checklist

Log in as the **regular user** (not root) and verify every prerequisite:

```bash
ping -c1 archlinux.org          # network up
sudo -v                         # sudo works for this user
command -v git makepkg          # git and base-devel present
```

If `makepkg` is missing:

```bash
sudo pacman -S --needed base-devel git
```

Optional but recommended — pre-install the AUR helper the installer expects,
so the AUR stage never depends on the silent `yay-bin` bootstrap:

```bash
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin && makepkg -si && cd .. && rm -rf yay-bin
```

(Again: `yay-bin`, not `yay` — the installer deletes the `yay` package.)

## Part 3 — Run the owlmango installer

Fresh-machine bootstrap (installs git if needed, clones the repo to
`~/.local/share/owlmango`, runs the local installer):

```bash
# Full GUI install
curl -fsSL https://raw.githubusercontent.com/acchapm1/owlmango/main/install/install.sh | bash

# CLI-only (servers / headless)
curl -fsSL https://raw.githubusercontent.com/acchapm1/owlmango/main/install/install.sh | bash -s -- --cli-only
```

Or from an existing clone:

```bash
./install/local                  # full GUI
./install/local --cli-only       # CLI tools only
./install/local --no-root        # skip root customizations
./install/local --fingerprint    # swaylock fingerprint support
```

Notes:

- Flags are saved to `~/.config/owlmango/install.flags` and **reused on every
  subsequent run**. If a past run used `--cli-only`, later plain runs stay
  CLI-only until you edit or delete that file.
- Package-manager output is logged to `/tmp/owlmango-install/*.log` — check
  there first when a step reports a warning.
- The full GUI install builds Wayle from source (Rust); expect the first run
  to take a while and use ~2 GB including build artifacts.

## Part 4 — Verify

```bash
fish --version                          # critical CLI package
pacman -Q yay-bin                       # AUR helper installed
yay -Q mangowm-git 2>/dev/null          # GUI: compositor from AUR
command -v wayle                        # GUI: shell built from source
systemctl status greetd                 # GUI: login manager
```

## Troubleshooting

### "yay/paru not found" during the AUR stage

The installer bootstraps `yay-bin` from the AUR, which requires `base-devel`
(for `makepkg`) and a regular non-root user (makepkg refuses to build as
root). When the bootstrap can't run, the AUR stage warns that paru/yay is
missing; the build output is in `/tmp/owlmango-install/makepkg-*.log`.

Fix — install the prerequisites and the helper manually, then re-run:

```bash
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin && makepkg -si            # run as your regular user, not root
```

Because the installed package is named `yay-bin`, the installer keeps it.

Note: installer versions before July 2026 removed an installed `yay` package
*before* building its replacement, so a failed build left the system with no
AUR helper — and a manually reinstalled `yay` was removed again on the next
run. The current installer only swaps `yay` for `yay-bin` after a successful
build; if yay keeps vanishing, update your clone of this repo.

### Installer skips all packages ("sudo not found")

Install sudo as root (`pacman -S sudo`), add your user to `wheel`, enable
wheel in `visudo`, then re-run as the regular user.

### AUR builds fail as root

Never run `install/local` (or the curl bootstrap) as root. Log in as the wheel
user; the installer escalates with sudo where needed.

### GPG / keyring errors from pacman

```bash
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman -Sy archlinux-keyring
```

(The installer runs the first two automatically when the keyring is absent.)

### A previous run's flags keep applying

```bash
cat ~/.config/owlmango/install.flags   # see what's saved
rm ~/.config/owlmango/install.flags    # forget saved flags
```
