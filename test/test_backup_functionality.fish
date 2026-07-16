#!/usr/bin/env fish

source (dirname (status -f))/helpers.fish

run_test_suite "Backup Functionality Tests"

set -g INSTALL_LOG "$HOME/owlmango-install-backup.log"

test_start "Create existing config to be backed up"
mkdir -p "$HOME/.config/fish.old"
echo "old config" > "$HOME/.config/fish.old/test.fish"
mv "$HOME/.config/fish.old" "$HOME/.config/fish" 2>/dev/null || true
test_pass

test_start "Install script runs and backs up existing config"
bash "$DOTFILES_ROOT/install/local" --no-root >"$INSTALL_LOG" 2>&1 || true
test_pass

test_start "Backup directory was created"
assert_dir_exists "$HOME/.local/state/config-backups"

test_start "Fish config is now a symlink"
assert_symlink "$HOME/.config/fish"

test_summary
