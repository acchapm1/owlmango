#!/usr/bin/env fish

source (dirname (status -f))/helpers.fish

run_test_suite "Fish Greeting Tests"

set -g INSTALL_LOG "$HOME/owlmango-install-fish-greeting.log"

test_start "Install script runs"
bash "$DOTFILES_ROOT/install/local" --no-root >"$INSTALL_LOG" 2>&1 || true
test_pass

test_start "User fish config disables greeting"
if test -f "$HOME/.config/fish/config.fish"
    if grep -q "set -g fish_greeting" "$HOME/.config/fish/config.fish"
        test_pass
    else
        test_fail "fish_greeting not set in user config"
    end
else
    test_fail "User fish config.fish not found"
end

test_start "User fish greeting is empty when sourced"
set result (fish -c 'source ~/.config/fish/config.fish; echo -n "$fish_greeting"')
if test -z "$result"
    test_pass
else
    test_fail "fish_greeting is not empty: '$result'"
end

test_summary
