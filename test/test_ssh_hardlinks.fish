#!/usr/bin/env fish
# Test SSH hardlink functionality

source (dirname (status -f))/helpers.fish

run_test_suite "SSH Hardlink Tests"

set -g INSTALL_LOG "$HOME/owlmango-install-ssh.log"

# Run installation first
bash "$DOTFILES_ROOT/install/local" --no-root >"$INSTALL_LOG" 2>&1

# Test 1: SSH directory is created
test_start "SSH directory exists"
assert_dir_exists "$HOME/.ssh"

# Test 2: SSH config file exists in home directory
test_start "SSH config exists in ~/.ssh/"
assert_file_exists "$HOME/.ssh/config"

# Test 3: SSH config file exists in repo
test_start "SSH config exists in repo"
assert_file_exists "$DOTFILES_ROOT/config/ssh/config"

# Test 4: SSH config is NOT a symlink
test_start "SSH config is NOT a symlink"
assert_not_symlink "$HOME/.ssh/config"

# Test 5: SSH config files are hardlinked when possible
test_start "SSH config files are hardlinked when possible"
set -l repo_dev (stat -c %d "$DOTFILES_ROOT/config/ssh/config" 2>/dev/null)
set -l home_dev (stat -c %d "$HOME/.ssh/config" 2>/dev/null)
if test "$repo_dev" = "$home_dev"
    assert_hardlink "$HOME/.ssh/config" "$DOTFILES_ROOT/config/ssh/config"
else
    test_pass
end

# Test 6: SSH .gitignore exists in home directory
test_start "SSH .gitignore exists in ~/.ssh/"
assert_file_exists "$HOME/.ssh/.gitignore"

# Test 7: SSH .gitignore files are hardlinked when possible
test_start "SSH .gitignore files are hardlinked when possible"
set -l repo_dev (stat -c %d "$DOTFILES_ROOT/config/ssh/.gitignore" 2>/dev/null)
set -l home_dev (stat -c %d "$HOME/.ssh/.gitignore" 2>/dev/null)
if test "$repo_dev" = "$home_dev"
    assert_hardlink "$HOME/.ssh/.gitignore" "$DOTFILES_ROOT/config/ssh/.gitignore"
else
    test_pass
end

# Test 8: SSH config.local file is created
test_start "SSH config.local file is created"
assert_file_exists "$HOME/.ssh/config.local"

# Test 9: SSH config includes config.local
test_start "SSH config includes config.local"
assert_contains "$HOME/.ssh/config" "config.local"

# Test 10: SSH config has reasonable permissions (600 or 644)
test_start "SSH config has reasonable permissions"
set -l perms (stat -c %a "$HOME/.ssh/config" 2>/dev/null)
if test "$perms" = "600" -o "$perms" = "644"
    test_pass
else
    test_fail "Expected 600 or 644, got $perms"
end

# Test 11: SSH directory has correct permissions
test_start "SSH directory has correct permissions (700)"
set -l perms (stat -c %a "$HOME/.ssh" 2>/dev/null)
assert_equal "$perms" "700"

# Test 12: Editing hardlinked file updates both locations
test_start "Editing hardlinked file updates both locations"
set -l repo_dev (stat -c %d "$DOTFILES_ROOT/config/ssh/config" 2>/dev/null)
set -l home_dev (stat -c %d "$HOME/.ssh/config" 2>/dev/null)
set -l repo_inode (stat -c %i "$DOTFILES_ROOT/config/ssh/config" 2>/dev/null)
set -l home_inode (stat -c %i "$HOME/.ssh/config" 2>/dev/null)
if test "$repo_dev" = "$home_dev" -a "$repo_inode" = "$home_inode"
    echo "# Test comment" >> "$HOME/.ssh/config"
    assert_contains "$DOTFILES_ROOT/config/ssh/config" "# Test comment"
else
    test_pass
end

# Test 13: Private keys can coexist with hardlinked config
test_start "Private keys can be created alongside config"
touch "$HOME/.ssh/id_test"
assert_file_exists "$HOME/.ssh/id_test"

# Test 14: SSH .gitignore contains *.pub pattern
test_start "SSH .gitignore ignores public keys"
assert_contains "$HOME/.ssh/.gitignore" "*.pub"

# Test 15: SSH .gitignore contains config.local pattern
test_start "SSH .gitignore ignores config.local"
assert_contains "$HOME/.ssh/.gitignore" "config.local"

test_summary
