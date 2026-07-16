if command -q ruby
  function rails
    set -l cmd (command -v rails)

    if test -f bin/rails
      ./bin/rails $argv
    else if test -e Gemfile && grep -q rails Gemfile
      bundle exec rails $argv
    else
      command rails $argv
    end

  end
end
