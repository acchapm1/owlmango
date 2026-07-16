if command -q ruby
  function guard
    if test (count $argv) -eq 0
        set argv "-i"
    end

    set -l cmd (command -v guard)

    if test -f bin/guard
      ./bin/guard $argv
    else if test -e Gemfile && grep -q guard Gemfile
      bundle exec guard $argv
    else
      command guard $argv
    end
  end
end
