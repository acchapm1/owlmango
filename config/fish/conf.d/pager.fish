# Pager settings (use bat as a syntax-highlighting preprocessor for less)

if status is-interactive
    if command -sq bat
        # Use the repo theme by default.
        set -gx BAT_THEME "Adwaita Pastel Dark"

        # Ensure less can show ANSI colors.
        set -gx LESS "-R"

        # Keep less as the pager, but use bat to render files with syntax highlighting.
        # This affects: `less some-file.ext`
        set -gx LESSOPEN "| bat --theme=\"$BAT_THEME\" --style=plain --color=always --paging=never %s"
        set -gx LESSCLOSE ""

        # Common tools honor PAGER.
        set -gx PAGER "less"

        # Use bat for man pages with syntax highlighting
        # sed strips ANSI escape sequences that man outputs for bold/underline
        set -gx MANPAGER "sh -c 'sed -e \"s/\\x1b\\[[0-9;]*m//g\" | bat -l man -p'"
    end
end
