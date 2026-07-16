#!/usr/bin/fish
# Test framework helpers for dotfiles installation tests

# Colors
set -g COLOR_RESET \e\[0m
set -g COLOR_RED \e\[31m
set -g COLOR_GREEN \e\[32m
set -g COLOR_YELLOW \e\[33m
set -g COLOR_BLUE \e\[34m
set -g COLOR_BOLD \e\[1m

# Test counters
set -g TEST_TOTAL 0
set -g TEST_PASSED 0
set -g TEST_FAILED 0
set -g TEST_SKIPPED 0

# Current test context
set -g CURRENT_TEST ""

# Repo root (one level above test directory)
set -g DOTFILES_ROOT (cd (dirname (status -f))/..; and pwd)

# Optional install log path for debugging
set -g INSTALL_LOG ""

# Print colored output
function print_color
    set -l color $argv[1]
    set -l message $argv[2..]
    echo -e "$color$message$COLOR_RESET"
end

# Start a test
function test_start
    set -g CURRENT_TEST $argv[1]
    set -g TEST_TOTAL (math $TEST_TOTAL + 1)
    print_color $COLOR_BLUE "  ▶ $CURRENT_TEST"
end

# Mark test as passed
function test_pass
    set -g TEST_PASSED (math $TEST_PASSED + 1)
    print_color $COLOR_GREEN "    ✓ PASS"
end

# Mark test as failed
function test_fail
    set -l reason $argv[1]
    set -g TEST_FAILED (math $TEST_FAILED + 1)
    print_color $COLOR_RED "    ✗ FAIL: $reason"
end

# Mark test as skipped
function test_skip
    set -l reason $argv[1]
    set -g TEST_SKIPPED (math $TEST_SKIPPED + 1)
    print_color $COLOR_YELLOW "    ⊘ SKIP: $reason"
end

# Print test summary
function test_summary
    echo ""
    print_color "$COLOR_BOLD" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$COLOR_BOLD" "Test Summary"
    print_color "$COLOR_BOLD" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Total:   $TEST_TOTAL"
    print_color $COLOR_GREEN "  Passed:  $TEST_PASSED"
    if test $TEST_FAILED -gt 0
        print_color $COLOR_RED "  Failed:  $TEST_FAILED"
    else
        echo "  Failed:  $TEST_FAILED"
    end
    if test $TEST_SKIPPED -gt 0
        print_color $COLOR_YELLOW "  Skipped: $TEST_SKIPPED"
    else
        echo "  Skipped: $TEST_SKIPPED"
    end
    print_color "$COLOR_BOLD" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if test $TEST_FAILED -gt 0; and test -n "$INSTALL_LOG"; and test -e "$INSTALL_LOG"
        print_color $COLOR_YELLOW "\nInstall log (last 200 lines): $INSTALL_LOG"
        tail -n 200 "$INSTALL_LOG"
    end

    # Return exit code
    if test $TEST_FAILED -gt 0
        return 1
    else
        return 0
    end
end

# Assertion: two values are equal
function assert_equal
    set -l actual $argv[1]
    set -l expected $argv[2]
    
    if test "$actual" = "$expected"
        test_pass
    else
        test_fail "Expected '$expected', got '$actual'"
    end
end

# Assertion: file exists
function assert_file_exists
    set -l file $argv[1]
    
    if test -e "$file"
        test_pass
    else
        test_fail "File does not exist: $file"
    end
end

# Assertion: file does not exist
function assert_file_not_exists
    set -l file $argv[1]
    
    if not test -e "$file"
        test_pass
    else
        test_fail "File should not exist: $file"
    end
end

# Assertion: path is a symlink
function assert_symlink
    set -l path $argv[1]
    
    if test -L "$path"
        test_pass
    else
        test_fail "Not a symlink: $path"
    end
end

# Assertion: path is NOT a symlink
function assert_not_symlink
    set -l path $argv[1]
    
    if not test -L "$path"
        test_pass
    else
        test_fail "Should not be a symlink: $path"
    end
end

# Assertion: two files are hardlinked (same inode)
function assert_hardlink
    set -l file1 $argv[1]
    set -l file2 $argv[2]
    
    if not test -e "$file1"
        test_fail "First file does not exist: $file1"
        return
    end
    
    if not test -e "$file2"
        test_fail "Second file does not exist: $file2"
        return
    end
    
    set -l inode1 (stat -c %i "$file1" 2>/dev/null)
    set -l inode2 (stat -c %i "$file2" 2>/dev/null)
    
    if test "$inode1" = "$inode2"
        test_pass
    else
        test_fail "Files are not hardlinked (inodes: $inode1 vs $inode2)"
    end
end

# Assertion: file contains string
function assert_contains
    set -l file $argv[1]
    set -l pattern $argv[2]
    
    if not test -e "$file"
        test_fail "File does not exist: $file"
        return
    end
    
    if grep -qF -- "$pattern" "$file" 2>/dev/null
        test_pass
    else
        test_fail "File does not contain '$pattern': $file"
    end
end

# Assertion: file does NOT contain string
function assert_not_contains
    set -l file $argv[1]
    set -l pattern $argv[2]
    
    if not test -e "$file"
        test_fail "File does not exist: $file"
        return
    end
    
    if not grep -qF -- "$pattern" "$file" 2>/dev/null
        test_pass
    else
        test_fail "File should not contain '$pattern': $file"
    end
end

# Assertion: directory exists
function assert_dir_exists
    set -l dir $argv[1]
    
    if test -d "$dir"
        test_pass
    else
        test_fail "Directory does not exist: $dir"
    end
end

# Assertion: command succeeds (exit code 0)
function assert_success
    set -l cmd $argv
    
    if eval $cmd >/dev/null 2>&1
        test_pass
    else
        test_fail "Command failed: $cmd"
    end
end

# Assertion: command fails (exit code non-zero)
function assert_fails
    set -l cmd $argv
    
    if not eval $cmd >/dev/null 2>&1
        test_pass
    else
        test_fail "Command should have failed: $cmd"
    end
end

# Run a test suite
function run_test_suite
    set -l suite_name $argv[1]
    print_color "$COLOR_BOLD$COLOR_BLUE" "\n▼ Running: $suite_name"
end
