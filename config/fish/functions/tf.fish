if command -q terraform
  function tf --wraps=terraform --description 'alias tf=terraform'
    terraform $argv
  end
end
