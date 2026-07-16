if command -q ruby
  function rr --wraps='rails routes | grep -Ev "\\s(rails|active_storage|action_mailbox|turbo/native|/cable)/"' --description 'alias rr=rails routes | grep -Ev "\\s(rails|active_storage|action_mailbox|turbo/native|/cable)/"'
    rails routes | grep -Ev "\s(rails|active_storage|action_mailbox|turbo/native|/cable)/" $argv
  end
end
