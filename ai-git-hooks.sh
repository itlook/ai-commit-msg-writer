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
    echo "  status          Show current hook status"
    echo "  enable          Enable hooks globally"
    echo "  disable         Disable hooks globally"
    echo "  config          Edit global configuration"
    echo "  exclude [repo]  Exclude a repository from hooks"
    echo "  include [repo]  Include a repository in hooks"
    echo "  test            Test hooks in current repository"
    echo "  reinstall       Reinstall global hooks"
    echo ""
    echo "Examples:"
    echo "  ai-git-hooks status"
    echo "  ai-git-hooks exclude my-repo"
    echo "  ai-git-hooks config"
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
}

reinstall_hooks() {
    echo -e "${BLUE}Reinstalling global hooks...${NC}"

    # This would need to re-run the setup script
    echo "Please run the setup script again to reinstall hooks"
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
    *)
        usage
        exit 1
        ;;
esac
