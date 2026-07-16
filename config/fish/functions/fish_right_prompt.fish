function fish_right_prompt --description "Adwaita context (ssh/container)"
    # Colors come from ~/.config/fish/conf.d/prompt.fish
    set -l c_muted $__adw_prompt_muted
    set -l c_red $__adw_prompt_red
    set -l c_host $__adw_prompt_at
    set -l c_branch $__adw_prompt_branch

    set -l show 0

    # SSH detection.
    if set -q SSH_CONNECTION
        set show 1
    end

    # Container detection.
    if test $show -eq 0
        if test -f /run/.containerenv -o -f /.dockerenv
            set show 1
        else if test -r /proc/1/cgroup
            set -l cg (command cat /proc/1/cgroup 2>/dev/null)
            if string match -rq '(docker|lxc|containerd|kubepods|podman)' -- $cg
                set show 1
            end
        end
    end

    if test $show -eq 1
        if test (id -u) -eq 0
            set_color --bold $c_red
            echo -n (whoami)
            set_color normal
            set_color $c_red
            echo -n '@'
            set_color --bold $c_red
            echo -n (hostname -s)
        else
            # User dim, host highlighted.
            set_color $c_branch
            echo -n (whoami)
            set_color normal
            set_color --bold $c_host
            echo -n '@'
            set_color $c_branch
            echo -n (hostname -s)
        end
        set_color normal
    end
end
