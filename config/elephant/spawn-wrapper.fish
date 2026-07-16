#!/usr/bin/env fish
# owlmango — launch prefix for elephant/walker.
# Mango has no compositor-mediated spawn (unlike `niri msg action spawn`), so
# detach the child into its own session and exec it directly.
exec setsid --fork $argv
