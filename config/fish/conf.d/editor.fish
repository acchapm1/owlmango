if test -z $EDITOR
  set -l EDITOR_COMMAND

  if command -q zeditor
    set EDITOR_COMMAND zeditor
  else if command -q zed
    set EDITOR_COMMAND zed
  else
    set EDITOR_COMMAND flatpak run dev.zed.Zed
  end

  set -x EDITOR (string join ' ' $EDITOR_COMMAND) -w

end
