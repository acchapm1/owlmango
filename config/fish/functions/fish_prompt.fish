function fish_prompt --description "Adwaita prompt"
    set -l last_status $status

    # Colors come from conf.d/prompt.fish
    set -l c_path $__adw_prompt_path
    set -l c_muted $__adw_prompt_muted
    set -l c_red $__adw_prompt_red
    set -l c_orange_muted $__adw_prompt_orange_muted
    set -l c_at $__adw_prompt_at
    set -l c_cyan $__adw_prompt_cyan
    set -l c_branch $__adw_prompt_branch

    # CWD
    set_color --bold $c_path
    echo -n (prompt_pwd)

    # Git (cached; updated on directory change)
    if set -q __adw_git_branch; and test -n "$__adw_git_branch"
        set_color --bold $c_at
        echo -n ':'
        set_color normal
        set_color $c_branch
        echo -n "$__adw_git_branch"
    end

    # Duration (only show when > 1s)
    if set -q CMD_DURATION; and test $CMD_DURATION -gt 1000
        set -l d_ms $CMD_DURATION
        set -l d

        if test $d_ms -lt 60000
            # Under 1 minute: show 1 decimal, e.g. 30.6s
            set d (math --scale=1 "$d_ms/1000")"s"
        else
            # 1 minute and above: round seconds.
            set -l total_s (math --scale=0 "($d_ms+500)/1000")
            set -l days (math --scale=0 "$total_s/86400")
            set -l rem (math --scale=0 "$total_s%86400")
            set -l hours (math --scale=0 "$rem/3600")
            set rem (math --scale=0 "$rem%3600")
            set -l mins (math --scale=0 "$rem/60")
            set -l secs (math --scale=0 "$rem%60")

            set d ""
            if test $days -gt 0
                set d "$d""$days""d"
            end
            if test $hours -gt 0 -o $days -gt 0
                set d "$d""$hours""h"
            end
            if test $mins -gt 0 -o $hours -gt 0 -o $days -gt 0
                set d "$d""$mins""m"
            end
            set d "$d""$secs""s"
        end

        set_color $c_orange_muted
        printf ' %s' $d
    end

    # Exit status
    if test $last_status -ne 0
        set_color $c_red
        printf ' | %s' $last_status
    end

    # Prompt symbol
    set_color normal
    echo -n ' '
    if test (id -u) -eq 0
        set_color $c_red
        echo -n '#'
    else if test $last_status -ne 0
        set_color $c_red
        echo -n '❱'
    else
        set_color $c_cyan
        echo -n '❱'
    end

    set_color normal
    echo -n ' '
end
