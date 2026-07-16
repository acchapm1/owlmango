#!/usr/bin/env fish

set -l script_dir (cd (dirname (status -f)); and pwd)
set -l tests \
  test_basic_install.fish \
  test_cli_only_flag.fish \
  test_no_root_flag.fish \
  test_ssh_hardlinks.fish \
  test_fish_greeting.fish \
  test_root_customizations.fish \
  test_backup_functionality.fish

set -l distros arch
set -l failed 0
set -l passed 0

echo "================================"
echo "Running All CI Tests"
echo "================================"
echo ""

for distro in $distros
  echo "Testing on $distro..."
  echo "--------------------------------"

  for test in $tests
    printf "  %s ... " $test
    if fish "$script_dir/run_ci_test.fish" "$distro" "$test" >/dev/null 2>&1
      echo "✓ PASS"
      set passed (math $passed + 1)
    else
      echo "✗ FAIL"
      set failed (math $failed + 1)
    end
  end

  echo ""
end

echo "================================"
echo "Test Summary"
echo "================================"
echo "Passed: $passed"
echo "Failed: $failed"
echo ""

if test $failed -eq 0
  echo "✓ ALL TESTS PASSED"
  exit 0
end

echo "✗ SOME TESTS FAILED"
exit 1
