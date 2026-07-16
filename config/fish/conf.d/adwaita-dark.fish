# Fish color theme: Zed Adwaita Pastel Dark-ish
# Drop into ~/.config/fish/conf.d/ to apply.

# Core palette (matches Zed "Adwaita Pastel Dark")
set -l adw_bg 1e1e1e
set -l adw_fg ffffff
set -l adw_muted 808080

set -l adw_blue 62a0ea
set -l adw_red c01c28
set -l adw_green 2ec27e
set -l adw_yellow f5c211
set -l adw_purple a74aa8
set -l adw_cyan 0ab9dc

# Syntax highlighting
set -g fish_color_normal $adw_fg
set -g fish_color_command $adw_blue
set -g fish_color_keyword $adw_blue
set -g fish_color_param $adw_muted
set -g fish_color_option $adw_fg
set -g fish_color_quote $adw_green
set -g fish_color_redirection $adw_cyan
set -g fish_color_end $adw_muted
set -g fish_color_operator $adw_cyan
set -g fish_color_escape $adw_purple
set -g fish_color_autosuggestion $adw_muted
set -g fish_color_comment $adw_muted
set -g fish_color_error $adw_red

# Selection and search
set -g fish_color_selection --background=3a5a7a --foreground=$adw_fg
set -g fish_color_search_match --background=3a5a7a --foreground=$adw_fg

# Paths / status
set -g fish_color_cwd $adw_cyan
set -g fish_color_cwd_root $adw_red
set -g fish_color_valid_path --underline
set -g fish_color_status $adw_red
set -g fish_color_cancel $adw_red

# Pager (tab completion UI)
set -g fish_pager_color_prefix $adw_blue --bold
set -g fish_pager_color_completion $adw_fg
set -g fish_pager_color_description $adw_muted
set -g fish_pager_color_selected_prefix $adw_fg --bold
set -g fish_pager_color_selected_completion $adw_fg
set -g fish_pager_color_selected_description $adw_fg
set -g fish_pager_color_progress $adw_muted
