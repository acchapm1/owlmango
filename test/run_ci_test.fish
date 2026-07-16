#!/usr/bin/env fish

# Usage: ./test/run_ci_test.fish <distro> <test_name>
# Example: ./test/run_ci_test.fish arch test_basic_install.fish

set -l distro "arch"
if test (count $argv) -ge 1
  set distro $argv[1]
end

set -l test_name "test_basic_install.fish"
if test (count $argv) -ge 2
  set test_name $argv[2]
end

set -l repo_root (cd (dirname (status -f))/..; and pwd)

switch $distro
  case arch
    set image "archlinux:latest"
    set setup_cmd "pacman-key --init >/dev/null 2>&1; pacman-key --populate archlinux >/dev/null 2>&1; pacman -Syu --noconfirm && pacman -S --noconfirm fish git sudo base-devel coreutils bash"
    set sudo_group "wheel"
  case '*'
    echo "Unknown distro: $distro"
    echo "Usage: (status -f) <arch> <test_name>"
    exit 1
end

echo "Running test: $test_name on $distro"

set -l docker_cmd "set -euo pipefail; $setup_cmd; useradd -m -G $sudo_group -s /usr/bin/fish testuser; echo '%$sudo_group ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/$sudo_group; cp -r /repo /home/testuser/dotfiles; chown -R testuser:testuser /home/testuser/dotfiles; rm -rf /home/testuser/dotfiles/config/packages; su - testuser -c \"cd /home/testuser/dotfiles && fish test/$test_name\""

docker run --rm -v "$repo_root:/repo:ro" "$image" bash -c "$docker_cmd"
