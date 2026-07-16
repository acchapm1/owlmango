function fish_mode_prompt --description "Vi mode indicator"
    # Only show when using a non-default key binding set (e.g. vi).
    if test "$fish_key_bindings" = fish_default_key_bindings
        return
    end

    set -l c_muted $__adw_prompt_muted
    set -l c_blue $__adw_prompt_blue
    set -l c_orange $__adw_prompt_orange
    set -l c_red $__adw_prompt_red

    set -l mode $fish_bind_mode
    set -l label
    set -l color $c_muted

    switch $mode
        case default
            set label N
            set color $c_blue
        case insert
            set label I
            set color $c_orange
        case replace replace_one
            set label R
            set color $c_red
        case visual
            set label V
            set color $c_red
        case '*'
            set label $mode
            set color $c_muted
    end

    set_color $c_muted
    echo -n '['
    set_color --bold $color
    echo -n $label
    set_color $c_muted
    echo -n '] '
    set_color normal
end
