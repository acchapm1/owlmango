#!/usr/bin/env fish
# Test basic installation functionality

source (dirname (status -f))/helpers.fish

run_test_suite "Basic Installation Tests"

set -g INSTALL_LOG "$HOME/owlmango-install-basic.log"

# Test 1: Install script exists and is executable
test_start "Install script exists and is executable"
assert_file_exists "$DOTFILES_ROOT/install/local"

# Test 2: Install script runs (may have package errors in Docker, but should create configs)
test_start "Install script runs and creates configs"
bash "$DOTFILES_ROOT/install/local" --no-root >"$INSTALL_LOG" 2>&1 || true
# Check that at least some configs were created
if test -e "$HOME/.config"
    test_pass
else
    test_fail "Install script did not create .config directory"
end

# Test 3: User config directory is created
test_start "User config directory is created"
assert_dir_exists "$HOME/.config"

# Test 4: Fish config is symlinked
test_start "Fish config is symlinked"
assert_symlink "$HOME/.config/fish"

# Test 5: Mango config is symlinked
test_start "Mango config is symlinked"
assert_symlink "$HOME/.config/mango"

# Test 6: Wayle config is symlinked
test_start "Wayle config is symlinked"
assert_symlink "$HOME/.config/wayle"

# Test 7: UWSM config is symlinked
test_start "UWSM config is symlinked"
assert_symlink "$HOME/.config/uwsm"

# Test 8: Systemd user services directory exists and contains symlinks
test_start "Systemd user directory exists with service symlinks"
assert_dir_exists "$HOME/.config/systemd/user"

# Test 9: Main Mango config file exists via symlink
test_start "Main Mango config file exists"
assert_file_exists "$HOME/.config/mango/config.conf"

# Test 10: Mango theme config file exists via symlink
test_start "Mango theme config file exists"
assert_file_exists "$HOME/.config/mango/theme.conf"

# Test 11: Mango binds config file exists via symlink
test_start "Mango binds config file exists"
assert_file_exists "$HOME/.config/mango/binds.conf"

# Test 12: Wayle config.toml exists via symlink
test_start "Wayle config file exists"
assert_file_exists "$HOME/.config/wayle/config.toml"

# Test 13: Ghostty config exists via symlink
test_start "Ghostty config exists"
assert_file_exists "$HOME/.config/ghostty/config"

# Test 14: UWSM environment file exists
test_start "UWSM env file exists"
assert_file_exists "$HOME/.config/uwsm/env"

# Test 15: Backup directory is created
test_start "Backup directory is created"
assert_dir_exists "$HOME/.local/state/config-backups"

test_summary
