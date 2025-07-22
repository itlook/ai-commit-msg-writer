#!/bin/bash

# Simplified File Filtering Test Suite

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test configuration
TEST_DIR="$(mktemp -d)"
TEST_CONFIG="$TEST_DIR/test-config.yaml"
HOOKS_DIR="$TEST_DIR/hooks"
HOOK_SCRIPT="$HOOKS_DIR/prepare-commit-msg"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
log_info() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

# Setup test environment
setup_test_env() {
    log_info "Setting up test environment in $TEST_DIR"

    # Create test directories
    mkdir -p "$HOOKS_DIR"
    mkdir -p "$TEST_DIR/test-repo"

    # Copy the hook script
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cp "$script_dir/../prepare-commit-msg" "$HOOK_SCRIPT"
    chmod +x "$HOOK_SCRIPT"

    # Create test configuration
    cp "$script_dir/../ai-commit-global-config.yaml" "$TEST_CONFIG"

    # Create test git repository
    cd "$TEST_DIR/test-repo"
    git init > /dev/null 2>&1
    git config user.name "Test User"
    git config user.email "test@example.com"
}

# Source the filtering functions from the hook script
source_filtering_functions() {
    # Extract just the filtering functions from the hook script
    local temp_functions="$TEST_DIR/filtering_functions.sh"

    # Extract specific functions needed for testing
    {
        echo "# Extracted filtering functions for testing"
        echo ""

        # Extract get_file_size function
        sed -n '/^# Get file size utility$/,/^}/p' "$HOOK_SCRIPT"
        echo ""

        # Extract is_file_excluded function
        sed -n '/^# Check if file matches any excluded pattern$/,/^}/p' "$HOOK_SCRIPT"
        echo ""

        # Extract is_binary_by_content function
        sed -n '/^# Check if file is binary by content$/,/^}/p' "$HOOK_SCRIPT"
        echo ""

        # Extract should_exclude_file function
        sed -n '/^# Main function to check if file should be excluded$/,/^}/p' "$HOOK_SCRIPT"
        echo ""

        # Extract filter_diff_enhanced function
        sed -n '/^# Enhanced diff filtering with comprehensive file exclusion$/,/^}/p' "$HOOK_SCRIPT"

    } > "$temp_functions"

    # Source the functions
    source "$temp_functions"
}

# Test function wrapper
run_test() {
    local test_name="$1"
    local test_function="$2"

    ((TESTS_RUN++))
    log_info "Running test: $test_name"

    if $test_function; then
        log_success "$test_name"
    else
        log_error "$test_name"
    fi

    echo ""
}

# Test excluded file patterns
test_excluded_patterns() {
    local config=$(cat "$TEST_CONFIG" | yq eval -o=json 2>/dev/null)

    # Test files that should be excluded
    local test_files=(
        "package-lock.json"
        "yarn.lock"
        "style.min.css"
        "app.bundle.js"
        "image.png"
        "document.pdf"
        "compiled.pyc"
        "Main.class"
        "CHANGELOG.md"
    )

    for file in "${test_files[@]}"; do
        if ! is_file_excluded "$file" "$config"; then
            echo "Failed to exclude: $file"
            return 1
        fi
    done

    # Test files that should NOT be excluded
    local include_files=(
        "main.js"
        "style.css"
        "README.md"
        "package.json"
        "src/component.tsx"
    )

    for file in "${include_files[@]}"; do
        if is_file_excluded "$file" "$config"; then
            echo "False positive - excluded: $file"
            return 1
        fi
    done

    return 0
}


# Test binary content detection
test_binary_detection() {
    local config=$(cat "$TEST_CONFIG" | yq eval -o=json 2>/dev/null)

    # Create a binary test file
    echo -e "\x00\x01\x02binary content" > test_binary.bin

    if ! is_binary_by_content "test_binary.bin" "$config"; then
        echo "Failed to detect binary file by content"
        rm -f test_binary.bin
        return 1
    fi

    # Create a text file
    echo "This is text content" > test_text.txt

    if is_binary_by_content "test_text.txt" "$config"; then
        echo "False positive: text file detected as binary"
        rm -f test_binary.bin test_text.txt
        return 1
    fi

    # Clean up
    rm -f test_binary.bin test_text.txt
    return 0
}

# Test main exclusion logic
test_should_exclude_file() {
    local config=$(cat "$TEST_CONFIG" | yq eval -o=json 2>/dev/null)

    # Test files that should be excluded
    local exclude_files=(
        "package-lock.json"
        "style.min.css"
    )

    for file in "${exclude_files[@]}"; do
        if ! should_exclude_file "$file" "$config"; then
            echo "Failed to exclude $file"
            return 1
        fi
    done

    # Test files that should be included
    local include_files=(
        "main.js"
        "README.md"
        "config.json"
    )

    for file in "${include_files[@]}"; do
        if should_exclude_file "$file" "$config"; then
            echo "False positive - excluded: $file"
            return 1
        fi
    done

    return 0
}

# Test diff filtering
test_diff_filtering() {
    # Create test files
    echo "console.log('test');" > main.js
    echo "# Test" > README.md
    echo '{"lockfileVersion": 2}' > package-lock.json
    echo -e "\x00binary" > test.png

    # Stage files
    git add .
    local test_diff=$(git diff --cached --no-color)

    # Load config
    local config=$(cat "$TEST_CONFIG" | yq eval -o=json 2>/dev/null)

    # Filter the diff
    local filtered_diff=$(filter_diff_enhanced "$test_diff" "$config")

    # Check inclusions and exclusions
    if ! echo "$filtered_diff" | grep -q "main.js"; then
        echo "main.js was incorrectly excluded"
        return 1
    fi

    if echo "$filtered_diff" | grep -q "package-lock.json"; then
        echo "package-lock.json was incorrectly included"
        return 1
    fi

    # Clean up
    git reset > /dev/null 2>&1
    rm -f main.js README.md package-lock.json test.png

    return 0
}

# Test configuration toggle
test_filtering_toggle() {
    local config=$(cat "$TEST_CONFIG" | yq eval -o=json 2>/dev/null)

    # Disable filtering
    local disabled_config=$(echo "$config" | yq eval '.file_filtering.enabled = false' -)

    # Test that files are not excluded when filtering is disabled
    if should_exclude_file "package-lock.json" "$disabled_config"; then
        echo "File excluded when filtering disabled"
        return 1
    fi

    # Re-enable filtering
    local enabled_config=$(echo "$disabled_config" | yq eval '.file_filtering.enabled = true' -)

    # Test that files are excluded when filtering is enabled
    if ! should_exclude_file "package-lock.json" "$enabled_config"; then
        echo "File not excluded when filtering enabled"
        return 1
    fi

    return 0
}

# Cleanup function
cleanup() {
    log_info "Cleaning up test environment"
    cd /
    rm -rf "$TEST_DIR"
}

# Main test execution
main() {
    echo -e "${BLUE}Simplified File Filtering Test Suite${NC}"
    echo "====================================="
    echo ""

    # Setup
    setup_test_env
    source_filtering_functions

    # Run tests
    run_test "Excluded File Patterns" test_excluded_patterns
    run_test "Binary Content Detection" test_binary_detection
    run_test "Main Exclusion Logic" test_should_exclude_file
    run_test "Diff Filtering" test_diff_filtering
    run_test "Configuration Toggle" test_filtering_toggle

    # Summary
    echo ""
    echo -e "${BLUE}Test Results${NC}"
    echo "============"
    echo "Tests run: $TESTS_RUN"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "\n${GREEN}All tests passed! ✓${NC}"
        cleanup
        exit 0
    else
        echo -e "\n${RED}Some tests failed! ✗${NC}"
        cleanup
        exit 1
    fi
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Run the tests
main "$@"