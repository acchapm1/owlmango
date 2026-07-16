#!/usr/bin/env fish
# Test --cli-only flag functionality

source (dirname (status -f))/helpers.fish

run_test_suite "--cli-only Flag Tests"

set -g INSTALL_LOG "$HOME/owlmango-install-cli-only.log"

# Run installation with --cli-only flag
bash "$DOTFILES_ROOT/install/local" --no-root --cli-only >"$INSTALL_LOG" 2>&1 || true

# Test 1: Install with --cli-only flag runs
test_start "Install with --cli-only flag runs"
if test -e "$HOME/.config"
    test_pass
else
    test_fail "Install script did not create .config directory"
end

# Test 2: CLI configs ARE created with --cli-only
test_start "Fish config IS created with --cli-only"
assert_symlink "$HOME/.config/fish"

# Test 3: Bat config is created
test_start "Bat config IS created with --cli-only"
assert_symlink "$HOME/.config/bat"

# Test 4: Git config is created
test_start "Git config IS created with --cli-only"
assert_symlink "$HOME/.config/git"

# Test 5: Htop config is created
test_start "Htop config IS created with --cli-only"
assert_symlink "$HOME/.config/htop"

# Test 6: FZF config is created
test_start "FZF config IS created with --cli-only"
assert_symlink "$HOME/.config/fzf"

# Test 7: Mango config is NOT created with --cli-only
test_start "Mango config is NOT created with --cli-only"
assert_file_not_exists "$HOME/.config/mango"

# Test 8: Wayle config is NOT created with --cli-only
test_start "Wayle config is NOT created with --cli-only"
assert_file_not_exists "$HOME/.config/wayle"

# Test 9: Ghostty config is NOT created with --cli-only
test_start "Ghostty config is NOT created with --cli-only"
assert_file_not_exists "$HOME/.config/ghostty"

# Test 10: UWSM config is NOT created with --cli-only
test_start "UWSM config is NOT created with --cli-only"
assert_file_not_exists "$HOME/.config/uwsm"

# Test 11: Swaylock config is NOT created with --cli-only
test_start "Swaylock config is NOT created with --cli-only"
assert_file_not_exists "$HOME/.config/swaylock"

# Test 12: Walker config is NOT created with --cli-only
test_start "Walker config is NOT created with --cli-only"
assert_file_not_exists "$HOME/.config/walker"

# Test 13: SSH config is NOT created with --cli-only (skipped for remote servers)
test_start "SSH config is NOT created with --cli-only"
assert_file_not_exists "$HOME/.ssh/config"

# Test 14: Systemd user directory exists
test_start "Systemd user directory exists with --cli-only"
assert_dir_exists "$HOME/.config/systemd/user"

# Test 15: GUI systemd services are NOT linked
test_start "GUI (walker) service is NOT linked with --cli-only"
assert_file_not_exists "$HOME/.config/systemd/user/walker.service"

# Test 16: CLI systemd services ARE linked
test_start "Gnome-keyring service IS linked with --cli-only"
assert_file_exists "$HOME/.config/systemd/user/gnome-keyring-daemon.service"

test_summary
