# Restore WAYLAND_DISPLAY for shells launched from Zed
# This allows Wayland apps launched from Zed's terminal to work correctly
# when Zed itself is forced to use XWayland due to NVIDIA bugs

if test -n "$ZED_ORIGINAL_WAYLAND_DISPLAY" -a -z "$WAYLAND_DISPLAY"
    set -gx WAYLAND_DISPLAY $ZED_ORIGINAL_WAYLAND_DISPLAY
end
