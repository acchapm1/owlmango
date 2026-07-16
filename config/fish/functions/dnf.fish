if command -q dnf
  function dnf --wraps=yum --description 'alias dnf=sudo dnf'
      sudo dnf $argv
  end
end
