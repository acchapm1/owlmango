# Dotfiles Installation Test Suite

Comprehensive test suite for validating the dotfiles installation process across different Linux distributions.

## Overview

This test suite uses Docker containers to create isolated, reproducible test environments. Tests are written in Fish shell and validate various aspects of the installation process including:

- Basic installation functionality
- SSH hardlink configuration
- `--no-root` flag behavior
- File permissions and symlinks
- Configuration file creation

## Quick Start

Run all tests on all distributions:

```fish
./test/run_tests.fish
```

Run tests on a specific distribution:

```fish
./test/run_tests.fish --distro arch
```

Run a specific test file:

```fish
./test/run_tests.fish --test test_ssh_hardlinks.fish
```

Open an interactive shell in a test container:

```fish
./test/run_tests.fish --interactive --distro arch
```

## Test Files

### `test_basic_install.fish`

Tests the fundamental installation process:

- Install script execution
- Config directory creation
- Symlink creation for various configs (fish, mango, wayle, uwsm)
- Backup directory creation

### `test_ssh_hardlinks.fish`

Tests SSH configuration using hardlinks instead of symlinks:

- SSH directory and file creation
- Hardlink verification (same inode check)
- File permissions (600 for config, 700 for directory)
- Bidirectional editing (changes propagate both ways)
- `.gitignore` patterns
- `config.local` creation

### `test_no_root_flag.fish`

Tests the `--no-root` flag functionality:

- Skips root user configuration
- Skips greetd configuration
- Skips faillock configuration
- Still creates user configurations

## Test Framework

The test framework is implemented in `helpers.fish` and provides:

### Assertion Functions

- `assert_equal <actual> <expected>` - Compare two values
- `assert_file_exists <path>` - Check file exists
- `assert_file_not_exists <path>` - Check file does not exist
- `assert_dir_exists <path>` - Check directory exists
- `assert_symlink <path>` - Check path is a symlink
- `assert_not_symlink <path>` - Check path is NOT a symlink
- `assert_hardlink <file1> <file2>` - Check files are hardlinked (same inode)
- `assert_contains <file> <pattern>` - Check file contains pattern
- `assert_not_contains <file> <pattern>` - Check file does not contain pattern
- `assert_success <command>` - Check command succeeds
- `assert_fails <command>` - Check command fails

### Test Management Functions

- `test_start <name>` - Begin a test
- `test_pass` - Mark test as passed
- `test_fail <reason>` - Mark test as failed
- `test_skip <reason>` - Mark test as skipped
- `test_summary` - Print test results and return exit code
- `run_test_suite <name>` - Print test suite header

### Output

Tests produce colorized output:

- 🟢 Green for passed tests
- 🔴 Red for failed tests
- 🟡 Yellow for skipped tests
- 🔵 Blue for test suite headers

## Docker Images

### `Dockerfile.arch`

Production Dockerfile for Arch Linux testing with all dependencies pre-installed:

- All CLI packages from `config/packages/arch/cli/packages.txt`
- CI essentials: fish, git, sudo, base-devel, nodejs
- Test user `testuser` with passwordless sudo access (wheel group)
- Used by CI workflow and can be used locally

### `Dockerfile.minimal`

Minimal environment for testing remote bootstrap:

- Only sudo, curl, and ca-certificates installed
- No git or fish (tests that remote script can install them)
- Used for testing the remote bootstrap script

All production images:

- Copy dotfiles repository to `/home/testuser/dotfiles`
- Remove package files to skip package installation in tests
- Pre-install all dependencies for faster test execution

## Test Runner Options

```
Usage: run_tests.fish [OPTIONS]

Options:
  --distro DISTRO   Test on specific distro (arch)
  --test TEST       Run specific test file
  --no-build        Skip Docker image rebuild
  --interactive     Run container interactively
  --help            Show this help message
```

### Examples

```fish
# Run all tests on all distros
./test/run_tests.fish

# Test only Arch Linux
./test/run_tests.fish --distro arch

# Run specific test on Arch
./test/run_tests.fish --distro arch --test test_ssh_hardlinks.fish

# Skip Docker rebuild (faster iteration)
./test/run_tests.fish --no-build

# Debug in interactive shell
./test/run_tests.fish --interactive --distro arch
```

## Writing New Tests

1. Create a new file `test/test_<feature>.fish`
2. Source the helpers: `source (dirname (status -f))/helpers.fish`
3. Add a test suite header: `run_test_suite "Feature Tests"`
4. Write tests using the test framework:

```fish
#!/usr/bin/fish
source (dirname (status -f))/helpers.fish

run_test_suite "My Feature Tests"

# Test 1
test_start "Description of what is being tested"
assert_file_exists "/path/to/file"

# Test 2
test_start "Another test"
if some_condition
    test_pass
else
    test_fail "Reason for failure"
end

test_summary
```

5. Make the test executable: `chmod +x test/test_<feature>.fish`
6. Run your test: `./test/run_tests.fish --test test_<feature>.fish`

## CI Integration

The test suite is designed to be CI-friendly:

- Exit code 0 if all tests pass
- Exit code 1 if any test fails
- Docker provides consistent environment
- No sudo required (use `--no-root` flag)
- Fast execution (typically < 2 minutes)

Example GitHub Actions workflow:

```yaml
name: Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install fish
        run: sudo apt-get install -y fish
      - name: Run tests
        run: fish ./test/run_tests.fish
```

## Troubleshooting

### Docker build fails

- Ensure Docker is installed and running
- Check internet connection (packages need to download)
- Try rebuilding without cache: `docker build --no-cache ...`

### Tests fail unexpectedly

- Run with `--interactive` to debug in container
- Check test output for specific assertion failures
- Verify Docker image is up to date (remove `--no-build`)

### Permission errors

- Tests should use `--no-root` to avoid sudo requirements
- SSH directory permissions should be 700, config 600
- Check that testuser has proper sudo access in Dockerfile

## Development Workflow

1. Make changes to installation scripts or configs
2. Run tests: `./test/run_tests.fish`
3. If tests fail, debug with: `./test/run_tests.fish --interactive --distro arch`
4. Fix issues and re-run tests
5. Commit changes when all tests pass

## Architecture

```
test/
├── Dockerfile.arch           # Arch Linux test environment
├── Dockerfile.minimal        # Minimal bootstrap test environment
├── helpers.fish              # Test framework (assertions, utilities)
├── test_basic_install.fish   # Basic installation tests
├── test_no_root_flag.fish    # --no-root flag tests
├── test_ssh_hardlinks.fish   # SSH hardlink tests
├── run_tests.fish            # Main test runner
└── README.md                 # This file
```

## Future Enhancements

Potential additions to the test suite:

- `test_fingerprint_flag.fish` - Test `--fingerprint` flag
- `test_gaming_flag.fish` - Test `--gaming` flag
- `test_backup_restore.fish` - Test backup and restore functionality
- `test_idempotence.fish` - Test running install multiple times
- `test_upgrade.fish` - Test upgrading from previous version
- Performance benchmarks
- Integration tests (full desktop session)
