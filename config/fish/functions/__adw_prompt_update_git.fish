function __adw_prompt_update_git --description "Cache git branch for prompt" --on-variable PWD
    # Cache the current git branch for the prompt.
    # Runs only when PWD changes (cd), so the prompt stays fast.

    set -g __adw_git_branch ""

    status is-interactive; or return

    command git -C "$PWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; or return

    set -l branch (command git -C "$PWD" symbolic-ref --quiet --short HEAD 2>/dev/null)
    if test -z "$branch"
        # Detached HEAD.
        set branch (command git -C "$PWD" rev-parse --short HEAD 2>/dev/null)
    end

    set -g __adw_git_branch "$branch"
end

function __adw_prompt_git_preexec --description "Mark git refresh" --on-event fish_preexec
    status is-interactive; or return
    set -l cmd "$argv[1]"
    string match -rq '^\s*(command\s+)?git(\s|$)' -- "$cmd"; or return
    set -g __adw_git_refresh_needed 1
end

function __adw_prompt_git_postexec --description "Refresh git cache" --on-event fish_postexec
    status is-interactive; or return
    if set -q __adw_git_refresh_needed; and test "$__adw_git_refresh_needed" = 1
        set -e __adw_git_refresh_needed
        __adw_prompt_update_git
    end
end
