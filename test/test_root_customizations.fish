#!/usr/bin/env fish

source (dirname (status -f))/helpers.fish

run_test_suite "Root Customizations Tests"

set -g INSTALL_LOG "$HOME/owlmango-install-root.log"

test_start "Install script runs with root customizations"
bash "$DOTFILES_ROOT/install/local" >"$INSTALL_LOG" 2>&1 || true
test_pass

test_start "Root fish config exists"
if sudo test -f "/root/.config/fish/config.fish"
    test_pass
else
    test_fail "Root fish config.fish not found"
end

test_start "Root fish config disables greeting"
if sudo grep -q "set -g fish_greeting" "/root/.config/fish/config.fish"
    test_pass
else
    test_fail "fish_greeting not set in root config"
end

test_start "Root bat config is symlinked"
if sudo test -L "/root/.config/bat"
    test_pass
else
    test_fail "Root bat config not symlinked"
end

test_start "Root btop config is symlinked"
if sudo test -L "/root/.config/btop"
    test_pass
else
    test_fail "Root btop config not symlinked"
end

test_start "Root fish prompt configs are symlinked"
if sudo test -L "/root/.config/fish/conf.d/00-colors.fish"
    test_pass
else
    test_fail "Root fish prompt configs not symlinked"
end

test_start "Root fish functions are symlinked"
if sudo test -L "/root/.config/fish/functions/fish_prompt.fish"
    test_pass
else
    test_fail "Root fish functions not symlinked"
end

test_summary
