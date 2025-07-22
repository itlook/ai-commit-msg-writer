#!/bin/bash

# AI Git Hooks Management Script

GLOBAL_CONFIG="$HOME/.ai-commit-global-config.yaml"
HOOKS_DIR="$HOME/.git-hooks"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    echo "AI Git Hooks Management"
    echo ""
    echo "Usage: ai-git-hooks [command] [options]"
    echo ""
    echo "Commands:"
    echo "  status              Show current hook status"
    echo "  enable              Enable hooks globally"
    echo "  disable             Disable hooks globally"
    echo "  config              Edit global configuration"
    echo "  exclude [repo]      Exclude a repository from hooks"
    echo "  include [repo]      Include a repository in hooks"
    echo "  test                Test hooks in current repository"
    echo "  reinstall           Reinstall global hooks"
    echo ""
    echo "File Filtering Commands:"
    echo "  show-filters        Show current file filtering configuration"
    echo "  test-filtering      Test file filtering on current repository"
    echo "  add-exclude [pattern]       Add custom exclusion pattern"
    echo "  remove-exclude [pattern]    Remove exclusion pattern"
    echo "  toggle-filtering    Enable/disable enhanced file filtering"
    echo ""
    echo "Examples:"
    echo "  ai-git-hooks status"
    echo "  ai-git-hooks exclude my-repo"
    echo "  ai-git-hooks show-filters"
    echo "  ai-git-hooks test-filtering"
    echo "  ai-git-hooks add-exclude '*.backup'"
}

status() {
    echo -e "${BLUE}AI Git Hooks Status${NC}"
    echo "=================================="

    if [ -f "$GLOBAL_CONFIG" ]; then
        local enabled
        enabled=$(cat $GLOBAL_CONFIG | yq eval '.enabled' 2>/dev/null)
        echo "Status: $([[ "$enabled" == "true" ]] && echo -e "${GREEN}Enabled${NC}" || echo -e "${RED}Disabled${NC}")"

        echo ""
        echo "Configuration:"
        echo "  Review enabled: $(cat "$GLOBAL_CONFIG" | yq eval '.review_enabled' 2>/dev/null)"
        echo "  Message generation: $(cat "$GLOBAL_CONFIG" | yq eval '.message_generation_enabled' 2>/dev/null)"
        echo "  Max subject length: $(cat "$GLOBAL_CONFIG" | yq eval '.max_subject_length' 2>/dev/null)"

        echo ""
        echo "Excluded repositories:"
        cat "$GLOBAL_CONFIG" | yq eval '.excluded_repositories[]' 2>/dev/null | sed 's/^/  - /' || echo "  None"
    else
        echo -e "${RED}Configuration file not found${NC}"
    fi

    echo ""
    echo "Hooks directory: $HOOKS_DIR"
    echo "Git hooks path: $(git config --global core.hooksPath)"
}

enable_hooks() {
    if [ -f "$GLOBAL_CONFIG" ]; then
        yq eval '.enabled = true' -i "$GLOBAL_CONFIG"
        echo -e "${GREEN}Hooks enabled globally${NC}"
    else
        echo -e "${RED}Configuration file not found${NC}"
        exit 1
    fi
}

disable_hooks() {
    if [ -f "$GLOBAL_CONFIG" ]; then
        yq eval '.enabled = false' -i "$GLOBAL_CONFIG"
        echo -e "${YELLOW}Hooks disabled globally${NC}"
    else
        echo -e "${RED}Configuration file not found${NC}"
        exit 1
    fi
}

edit_config() {
    if [ -f "$GLOBAL_CONFIG" ]; then
        "${EDITOR:-nano}" "$GLOBAL_CONFIG"
    else
        echo -e "${RED}Configuration file not found${NC}"
        exit 1
    fi
}

exclude_repo() {
    local repo_name=$1
    if [ -z "$repo_name" ]; then
        echo -e "${RED}Please specify a repository name${NC}"
        exit 1
    fi

    if [ -f "$GLOBAL_CONFIG" ]; then
        yq eval ".excluded_repositories += [\"$repo_name\"] | .excluded_repositories |= unique" -i "$GLOBAL_CONFIG"
        echo -e "${GREEN}Repository '$repo_name' excluded from hooks${NC}"
    else
        echo -e "${RED}Configuration file not found${NC}"
        exit 1
    fi
}

include_repo() {
    local repo_name=$1
    if [ -z "$repo_name" ]; then
        echo -e "${RED}Please specify a repository name${NC}"
        exit 1
    fi

    if [ -f "$GLOBAL_CONFIG" ]; then
        yq eval ".excluded_repositories -= [\"$repo_name\"]" -i "$GLOBAL_CONFIG"
        echo -e "${GREEN}Repository '$repo_name' included in hooks${NC}"
    else
        echo -e "${RED}Configuration file not found${NC}"
        exit 1
    fi
}

test_hooks() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}Not in a git repository${NC}"
        exit 1
    fi

    local repo_name
    repo_name=$(basename "$(git rev-parse --show-toplevel)")

    echo -e "${BLUE}Testing hooks in repository: $repo_name${NC}"

    # Test if hooks would run
    if [ -f "$HOOKS_DIR/prepare-commit-msg" ]; then
        echo -e "${GREEN}✓ prepare-commit-msg hook found${NC}"
    else
        echo -e "${RED}✗ prepare-commit-msg hook missing${NC}"
    fi

    if [ -f "$HOOKS_DIR/pre-commit" ]; then
        echo -e "${GREEN}✓ pre-commit hook found${NC}"
    else
        echo -e "${RED}✗ pre-commit hook missing${NC}"
    fi

    # Check if repo is excluded
    if [ -f "$GLOBAL_CONFIG" ]; then
        local excluded
        excluded=$(cat "$GLOBAL_CONFIG" | yq eval ".excluded_repositories | contains([\"$repo_name\"])" 2>/dev/null)
        if [ "$excluded" = "true" ]; then
            echo -e "${YELLOW}⚠ Repository is excluded from hooks${NC}"
        else
            echo -e "${GREEN}✓ Repository is included in hooks${NC}"
        fi
    fi

    # Test WHY functionality
    test_why_functionality
}

test_why_functionality() {
    echo ""
    echo -e "${BLUE}Testing WHY variable support...${NC}"

    # Check if WHY is enabled in config
    if [ -f "$GLOBAL_CONFIG" ]; then
        local use_why_variable
        local prompt_for_why
        use_why_variable=$(cat "$GLOBAL_CONFIG" | yq eval '.use_why_variable // true' 2>/dev/null)
        prompt_for_why=$(cat "$GLOBAL_CONFIG" | yq eval '.prompt_for_why // true' 2>/dev/null)

        echo "WHY variable enabled: $use_why_variable"
        echo "Interactive prompt enabled: $prompt_for_why"

        # Test WHY variable detection
        if [ "$use_why_variable" = "true" ]; then
            echo -e "${GREEN}✓ WHY functionality is enabled${NC}"

            # Test with WHY environment variable set
            echo -e "${BLUE}Testing WHY variable set...${NC}"
            if [ -n "$WHY" ]; then
                echo -e "${GREEN}✓ WHY variable is currently set: '$WHY'${NC}"
            else
                echo -e "${YELLOW}⚠ WHY variable not set (this is normal)${NC}"
            fi

            # Test prompt template has WHY placeholder
            local has_why_placeholder
            has_why_placeholder=$(cat "$GLOBAL_CONFIG" | yq eval '.prompt_template | contains("{why_context}")' 2>/dev/null)
            if [ "$has_why_placeholder" = "true" ]; then
                echo -e "${GREEN}✓ Prompt template contains {why_context} placeholder${NC}"
            else
                echo -e "${RED}✗ Prompt template missing {why_context} placeholder${NC}"
            fi
        else
            echo -e "${YELLOW}⚠ WHY functionality is disabled${NC}"
        fi
    else
        echo -e "${RED}✗ Configuration file not found${NC}"
    fi
}

reinstall_hooks() {
    echo -e "${BLUE}Reinstalling global hooks...${NC}"

    # This would need to re-run the setup script
    echo "Please run the setup script again to reinstall hooks"
}

# File filtering management functions

show_filters() {
    echo -e "${BLUE}Current File Filtering Configuration${NC}"
    echo "===================================="

    if [ -f "$GLOBAL_CONFIG" ]; then
        local filtering_enabled
        filtering_enabled=$(cat "$GLOBAL_CONFIG" | yq eval '.file_filtering.enabled // true' 2>/dev/null)
        echo "Enhanced filtering: $([[ "$filtering_enabled" == "true" ]] && echo -e "${GREEN}Enabled${NC}" || echo -e "${RED}Disabled${NC}")"

        echo ""
        echo "Excluded files:"
        cat "$GLOBAL_CONFIG" | yq eval '.excluded_files[]' 2>/dev/null | sed 's/^/  - /' || echo "  None"

        echo ""
        echo "Binary content detection: $(cat "$GLOBAL_CONFIG" | yq eval '.file_filtering.detect_binary_content // true' 2>/dev/null)"
    else
        echo -e "${RED}Configuration file not found${NC}"
        exit 1
    fi
}

test_filtering() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}Not in a git repository${NC}"
        exit 1
    fi

    echo -e "${BLUE}Testing File Filtering${NC}"
    echo "======================"

    # Get staged files
    local staged_files
    staged_files=$(git diff --cached --name-only 2>/dev/null)

    if [ -z "$staged_files" ]; then
        echo -e "${YELLOW}No staged files found. Staging all modified files for testing...${NC}"
        git add . 2>/dev/null || true
        staged_files=$(git diff --cached --name-only 2>/dev/null)
    fi

    if [ -z "$staged_files" ]; then
        echo -e "${YELLOW}No files to test filtering on${NC}"
        return
    fi

    echo "Analyzing staged files..."
    echo ""

    # Source the filtering functions from prepare-commit-msg
    local hook_script="$HOOKS_DIR/prepare-commit-msg"
    if [ -f "$hook_script" ]; then
        # Load configuration
        local config
        config=$(cat "$GLOBAL_CONFIG" | yq eval -o=json 2>/dev/null)

        # Test each staged file
        while IFS= read -r file; do
            if [ -f "$file" ]; then
                # Simple pattern matching (mimics the hook logic)
                local should_exclude=false

                # Check lock files
                case "$file" in
                    package-lock.json|yarn.lock|Cargo.lock|composer.lock|poetry.lock|go.sum|Pipfile.lock|pubspec.lock|mix.lock|Gemfile.lock|pnpm-lock.yaml)
                        should_exclude=true
                        echo -e "  ${RED}✗${NC} $file (lock file)"
                        ;;
                    *.min.js|*.min.css|*.bundle.js|*.chunk.js|*.pyc|*.class|*.o|*.exe|*.dll|*.so|*.dylib)
                        should_exclude=true
                        echo -e "  ${RED}✗${NC} $file (generated/compiled)"
                        ;;
                    *.png|*.jpg|*.jpeg|*.gif|*.bmp|*.ico|*.pdf|*.zip|*.tar.gz|*.rar|*.7z|*.mp3|*.mp4|*.avi|*.mov|*.doc|*.docx|*.xls|*.xlsx|*.ppt|*.pptx)
                        should_exclude=true
                        echo -e "  ${RED}✗${NC} $file (binary)"
                        ;;
                    *.log|*.tmp|*.temp|CHANGELOG.md|CHANGELOG.txt)
                        should_exclude=true
                        echo -e "  ${RED}✗${NC} $file (meta/log)"
                        ;;
                    *)
                        echo -e "  ${GREEN}✓${NC} $file (included)"
                        ;;
                esac
            else
                echo -e "  ${YELLOW}?${NC} $file (file not found)"
            fi
        done <<< "$staged_files"

        echo ""
        echo "Legend: ✓ = included in analysis, ✗ = excluded from analysis"
    else
        echo -e "${RED}Hook script not found${NC}"
        exit 1
    fi
}

add_exclude() {
    local pattern="$1"

    if [ -z "$pattern" ]; then
        echo -e "${RED}Please specify a pattern to exclude${NC}"
        echo "Usage: ai-git-hooks add-exclude [pattern]"
        echo "Example: ai-git-hooks add-exclude '*.backup'"
        exit 1
    fi

    if [ -f "$GLOBAL_CONFIG" ]; then
        yq eval ".excluded_files += [\"$pattern\"] | .excluded_files |= unique" -i "$GLOBAL_CONFIG"
        echo -e "${GREEN}Added exclusion pattern: $pattern${NC}"
    else
        echo -e "${RED}Configuration file not found${NC}"
        exit 1
    fi
}

remove_exclude() {
    local pattern="$1"

    if [ -z "$pattern" ]; then
        echo -e "${RED}Please specify a pattern to remove${NC}"
        echo "Usage: ai-git-hooks remove-exclude [pattern]"
        echo "Example: ai-git-hooks remove-exclude '*.backup'"
        exit 1
    fi

    if [ -f "$GLOBAL_CONFIG" ]; then
        yq eval "del(.excluded_files[] | select(. == \"$pattern\"))" -i "$GLOBAL_CONFIG"
        echo -e "${GREEN}Removed exclusion pattern: $pattern${NC}"
    else
        echo -e "${RED}Configuration file not found${NC}"
        exit 1
    fi
}

toggle_filtering() {
    if [ -f "$GLOBAL_CONFIG" ]; then
        local current_state
        current_state=$(cat "$GLOBAL_CONFIG" | yq eval '.file_filtering.enabled // true' 2>/dev/null)

        if [[ "$current_state" == "true" ]]; then
            yq eval '.file_filtering.enabled = false' -i "$GLOBAL_CONFIG"
            echo -e "${YELLOW}Enhanced file filtering disabled${NC}"
        else
            yq eval '.file_filtering.enabled = true' -i "$GLOBAL_CONFIG"
            echo -e "${GREEN}Enhanced file filtering enabled${NC}"
        fi
    else
        echo -e "${RED}Configuration file not found${NC}"
        exit 1
    fi
}

case "$1" in
    status)
        status
        ;;
    enable)
        enable_hooks
        ;;
    disable)
        disable_hooks
        ;;
    config)
        edit_config
        ;;
    exclude)
        exclude_repo "$2"
        ;;
    include)
        include_repo "$2"
        ;;
    test)
        test_hooks
        ;;
    reinstall)
        reinstall_hooks
        ;;
    show-filters)
        show_filters
        ;;
    test-filtering)
        test_filtering
        ;;
    add-exclude)
        add_exclude "$2"
        ;;
    remove-exclude)
        remove_exclude "$2"
        ;;
    toggle-filtering)
        toggle_filtering
        ;;
    *)
        usage
        exit 1
        ;;
esac
