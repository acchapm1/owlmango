function e --wraps=zeditor --description 'Launch Zed editor with NVIDIA workaround'
  set -l tool 

  if command -q zeditor
    set tool zeditor
  else if command -q zed
    set tool zed
  else
    set tool flatpak run dev.zed.Zed
  end

  set -x EDITOR (string join ' ' $tool) -w

  if test -z "$NIRI_SOCKET"
    command $tool $argv
    return $status
  end

  set -l use_xwayland 0
  if test -n "$WAYLAND_DISPLAY"
    if command -q nvidia-smi
      set use_xwayland 1
    else if command -q lspci
      if lspci | grep -i nvidia | grep -i vga >/dev/null 2>&1
        set use_xwayland 1
      end
    end
  end

  if test $use_xwayland -eq 1
    set -gx ZED_ORIGINAL_WAYLAND_DISPLAY $WAYLAND_DISPLAY

    set -l saved_wayland $WAYLAND_DISPLAY
    set -e WAYLAND_DISPLAY

    command $tool $argv
    set -l s $status
    set -gx WAYLAND_DISPLAY $saved_wayland
    return $s
  else
    command $tool $argv
    return $status
  end
end
