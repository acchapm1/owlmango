#!/usr/bin/fish
# Main test runner for dotfiles installation tests

set -l SCRIPT_DIR (dirname (status -f))
set -l REPO_ROOT (cd $SCRIPT_DIR/..; and pwd)

# Colors
set -g COLOR_RESET \e\[0m
set -g COLOR_RED \e\[31m
set -g COLOR_GREEN \e\[32m
set -g COLOR_YELLOW \e\[33m
set -g COLOR_BLUE \e\[34m
set -g COLOR_BOLD \e\[1m

function print_color
    set -l color $argv[1]
    set -l message $argv[2..]
    echo -e "$color$message$COLOR_RESET"
end

function print_header
    echo ""
    print_color "$COLOR_BOLD$COLOR_BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$COLOR_BOLD$COLOR_BLUE" "$argv"
    print_color "$COLOR_BOLD$COLOR_BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
end

function show_usage
    echo "Usage: run_tests.fish [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --distro DISTRO   Test on specific distro (arch)"
    echo "  --test TEST       Run specific test file"
    echo "  --no-build        Skip Docker image rebuild"
    echo "  --interactive     Run container interactively"
    echo "  --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  run_tests.fish                           # Run all tests on all distros"
    echo "  run_tests.fish --distro arch             # Run all tests on Arch only"
    echo "  run_tests.fish --test test_ssh_hardlinks.fish  # Run specific test"
    echo "  run_tests.fish --interactive --distro arch     # Open interactive shell"
end

# Parse arguments
set -l distro "all"
set -l test_file "all"
set -l no_build 0
set -l interactive 0

for i in (seq (count $argv))
    switch $argv[$i]
        case --distro
            set distro $argv[(math $i + 1)]
        case --test
            set test_file $argv[(math $i + 1)]
        case --no-build
            set no_build 1
        case --interactive
            set interactive 1
        case --help -h
            show_usage
            exit 0
    end
end

# Validate distro
if test "$distro" != "all" -a "$distro" != "arch"
    print_color $COLOR_RED "Error: Invalid distro '$distro'. Must be 'arch' or 'all'"
    exit 1
end

# Build list of distros to test
set -l distros
if test "$distro" = "all"
    set distros arch
else
    set distros $distro
end

# Build list of tests to run
set -l test_files
if test "$test_file" = "all"
    set test_files (ls $SCRIPT_DIR/test_*.fish)
else
    if test -e "$SCRIPT_DIR/$test_file"
        set test_files "$SCRIPT_DIR/$test_file"
    else if test -e "$test_file"
        set test_files "$test_file"
    else
        print_color $COLOR_RED "Error: Test file not found: $test_file"
        exit 1
    end
end

print_header "Dotfiles Installation Test Suite"
echo "Repository: $REPO_ROOT"
echo "Distros: $distros"
echo "Tests: "(count $test_files)" test file(s)"

# Track overall results
set -l total_suites 0
set -l passed_suites 0
set -l failed_suites 0

# Run tests for each distro
for distro_name in $distros
    set -l image_name "dotfiles-test-$distro_name"
    
    print_header "Testing on $distro_name"
    
    # Build Docker image
    if test $no_build -eq 0
        print_color $COLOR_BLUE "Building Docker image: $image_name"
        if docker build -f "$SCRIPT_DIR/Dockerfile.$distro_name" -t $image_name "$REPO_ROOT" >/dev/null 2>&1
            print_color $COLOR_GREEN "✓ Image built successfully"
        else
            print_color $COLOR_RED "✗ Failed to build Docker image"
            set failed_suites (math $failed_suites + 1)
            continue
        end
    else
        print_color $COLOR_YELLOW "Skipping image build (--no-build)"
    end
    
    # Interactive mode
    if test $interactive -eq 1
        print_color $COLOR_BLUE "Starting interactive shell..."
        docker run --rm -it $image_name /usr/bin/fish
        exit 0
    end
    
    # Run each test file
    for test in $test_files
        set -l test_name (basename $test)
        set total_suites (math $total_suites + 1)
        
        print_color $COLOR_BLUE "\nRunning: $test_name on $distro_name"
        
        # Run test in container
        if docker run --rm $image_name fish /home/testuser/dotfiles/test/$test_name
            set passed_suites (math $passed_suites + 1)
            print_color $COLOR_GREEN "✓ Test suite passed: $test_name"
        else
            set failed_suites (math $failed_suites + 1)
            print_color $COLOR_RED "✗ Test suite failed: $test_name"
        end
    end
end

# Print final summary
print_header "Final Results"
echo "Total test suites: $total_suites"
print_color $COLOR_GREEN "Passed: $passed_suites"
if test $failed_suites -gt 0
    print_color $COLOR_RED "Failed: $failed_suites"
else
    echo "Failed: $failed_suites"
end

# Exit with appropriate code
if test $failed_suites -gt 0
    print_color $COLOR_RED "\n✗ TESTS FAILED"
    exit 1
else
    print_color $COLOR_GREEN "\n✓ ALL TESTS PASSED"
    exit 0
end
