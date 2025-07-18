#!/bin/bash

# AI Git Hooks Installation Script
# Compatible with macOS, Ubuntu, CentOS, and other Unix-like systems

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Installation settings
HOOKS_DIR="$HOME/.git-hooks"
GLOBAL_CONFIG="$HOME/.ai-commit-global-config.yaml"
MANAGEMENT_SCRIPT="$HOME/.local/bin/ai-git-hooks"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Command line options
ASSUME_YES=false
CHANGES_MADE=()
FAILED_OPERATIONS=()

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes)
            ASSUME_YES=true
            shift
            ;;
        -h|--help)
            echo "AI Git Hooks Installation Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -y, --yes    Install without asking for confirmation"
            echo "  -h, --help   Show this help message"
            echo ""
            echo "This script will:"
            echo "  1. Verify required dependencies (yq, git, ai cli)"
            echo "  2. Set up global git hooks directory"
            echo "  3. Install the prepare-commit-msg hook"
            echo "  4. Install global configuration file"
            echo "  5. Install management script"
            echo "  6. Configure git to use global hooks"
            echo ""
            echo "Prerequisites:"
            echo "  - yq (YAML processor) must be installed"
            echo "  - git must be installed"
            echo "  - AI CLI must be installed and configured"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Helper functions
log_info() {
    echo -e "${BLUE}[Install]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[Install]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[Install]${NC} $1"
}

log_error() {
    echo -e "${RED}[Install]${NC} $1"
}

ask_permission() {
    if [ "$ASSUME_YES" = true ]; then
        return 0
    fi

    while true; do
        read -p "$1 (y/N): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            "" ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

track_change() {
    CHANGES_MADE+=("$1")
}

track_failure() {
    FAILED_OPERATIONS+=("$1")
}

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/redhat-release ]]; then
        echo "redhat"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ -f /etc/arch-release ]]; then
        echo "arch"
    else
        echo "unknown"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check required dependencies
check_dependencies() {
    local os
    os=$(detect_os)

    log_info "Detected OS: $os"
    log_info "Checking required dependencies..."

    local missing_deps=()

    # Check if yq is installed
    if ! command_exists yq; then
        log_error "yq (YAML processor) is not installed"
        missing_deps+=("yq")
    else
        log_success "yq is available"
    fi

    # Check if git is installed
    if ! command_exists git; then
        log_error "Git is not installed"
        missing_deps+=("git")
    else
        log_success "Git is available"
    fi

    # Check if AI CLI is available
    if ! command_exists claude; then
        log_error "AI CLI is not installed"
        missing_deps+=("claude")
    else
        log_success "AI CLI is available"
    fi

    # If any dependencies are missing, show installation instructions and exit
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo ""
        log_error "Missing required dependencies: ${missing_deps[*]}"
        echo ""
        log_info "Please install the missing dependencies:"

        for dep in "${missing_deps[@]}"; do
            case $dep in
                "yq")
                    echo "  • yq: https://github.com/mikefarah/yq#install"
                    case $os in
                        "macos")
                            echo "    macOS: brew install yq"
                            ;;
                        "debian")
                            echo "    Ubuntu/Debian: snap install yq or download from GitHub"
                            ;;
                        "redhat")
                            echo "    CentOS/RHEL/Fedora: dnf install yq or download from GitHub"
                            ;;
                    esac
                    ;;
                "git")
                    echo "  • git: https://git-scm.com/downloads"
                    case $os in
                        "macos")
                            echo "    macOS: brew install git"
                            ;;
                        "debian")
                            echo "    Ubuntu/Debian: apt install git"
                            ;;
                        "redhat")
                            echo "    CentOS/RHEL/Fedora: dnf install git"
                            ;;
                    esac
                    ;;
                "claude")
                    echo "  • claude: https://claude.ai/code"
                    echo "    All systems: Follow installation instructions at the link above"
                    ;;
            esac
        done

        echo ""
        log_error "Installation cannot continue without these dependencies."
        exit 1
    fi

    log_success "All required dependencies are available"
}

# Create hooks directory
setup_hooks_directory() {
    if ask_permission "Create global git hooks directory at $HOOKS_DIR?"; then
        if [ ! -d "$HOOKS_DIR" ]; then
            log_info "Creating hooks directory: $HOOKS_DIR"
            mkdir -p "$HOOKS_DIR" && track_change "Created hooks directory: $HOOKS_DIR" || track_failure "Failed to create hooks directory"
        else
            log_success "Hooks directory already exists: $HOOKS_DIR"
        fi
    else
        log_error "Hooks directory is required for installation"
        exit 1
    fi
}

# Install the prepare-commit-msg hook
install_hook() {
    local hook_file="$HOOKS_DIR/prepare-commit-msg"

    if ask_permission "Install prepare-commit-msg hook to $hook_file?"; then
        if [ -f "$SCRIPT_DIR/prepare-commit-msg" ]; then
            log_info "Installing prepare-commit-msg hook..."
            cp "$SCRIPT_DIR/prepare-commit-msg" "$hook_file" && \
            chmod +x "$hook_file" && \
            track_change "Installed prepare-commit-msg hook" || track_failure "Failed to install prepare-commit-msg hook"
        else
            log_error "prepare-commit-msg file not found in $SCRIPT_DIR"
            track_failure "prepare-commit-msg source file not found"
        fi
    else
        log_warning "Skipping hook installation"
        track_failure "User declined to install hook"
    fi
}

# Install global configuration
install_config() {
    if ask_permission "Install global configuration to $GLOBAL_CONFIG?"; then
        if [ -f "$SCRIPT_DIR/ai-commit-global-config.yaml" ]; then
            if [ -f "$GLOBAL_CONFIG" ]; then
                if ask_permission "Configuration file already exists. Backup and replace?"; then
                    log_info "Backing up existing configuration..."
                    cp "$GLOBAL_CONFIG" "$GLOBAL_CONFIG.backup.$(date +%Y%m%d_%H%M%S)" && \
                    track_change "Backed up existing configuration"
                fi
            fi
            log_info "Installing global configuration..."
            cp "$SCRIPT_DIR/ai-commit-global-config.yaml" "$GLOBAL_CONFIG" && \
            track_change "Installed global configuration" || track_failure "Failed to install global configuration"
        else
            log_error "ai-commit-global-config.yaml file not found in $SCRIPT_DIR"
            track_failure "Configuration source file not found"
        fi
    else
        log_warning "Skipping configuration installation"
        track_failure "User declined to install configuration"
    fi
}

# Install management script
install_management_script() {
    local bin_dir="$HOME/.local/bin"

    if ask_permission "Install management script to $MANAGEMENT_SCRIPT?"; then
        if [ -f "$SCRIPT_DIR/ai-git-hooks.sh" ]; then
            log_info "Creating bin directory if needed..."
            mkdir -p "$bin_dir"

            log_info "Installing management script..."
            cp "$SCRIPT_DIR/ai-git-hooks.sh" "$MANAGEMENT_SCRIPT" && \
            chmod +x "$MANAGEMENT_SCRIPT" && \
            track_change "Installed management script to $MANAGEMENT_SCRIPT" || track_failure "Failed to install management script"

            # Check if ~/.local/bin is in PATH
            if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                log_warning "$HOME/.local/bin is not in your PATH"
                log_info "Add this line to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
                echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
                track_change "Note: Added PATH instruction for ~/.local/bin"
            fi
        else
            log_error "ai-git-hooks.sh file not found in $SCRIPT_DIR"
            track_failure "Management script source file not found"
        fi
    else
        log_warning "Skipping management script installation"
        track_failure "User declined to install management script"
    fi
}

# Configure git to use global hooks
configure_git() {
    if ask_permission "Configure git to use global hooks directory?"; then
        log_info "Configuring git to use global hooks..."
        git config --global core.hooksPath "$HOOKS_DIR" && \
        track_change "Configured git to use global hooks directory" || track_failure "Failed to configure git global hooks"
    else
        log_warning "Skipping git configuration"
        track_failure "User declined to configure git"
    fi
}

# Print installation summary
print_summary() {
    echo ""
    echo "========================================"
    echo -e "${BLUE}Installation Summary${NC}"
    echo "========================================"

    if [ ${#CHANGES_MADE[@]} -gt 0 ]; then
        echo -e "${GREEN}✓ Successfully completed:${NC}"
        for change in "${CHANGES_MADE[@]}"; do
            echo "  • $change"
        done
        echo ""
    fi

    if [ ${#FAILED_OPERATIONS[@]} -gt 0 ]; then
        echo -e "${RED}✗ Failed or skipped operations:${NC}"
        for failure in "${FAILED_OPERATIONS[@]}"; do
            echo "  • $failure"
        done
        echo ""
    fi

    # Determine overall status
    local critical_failures=0
    for failure in "${FAILED_OPERATIONS[@]}"; do
        if [[ "$failure" == *"yq"* ]] || [[ "$failure" == *"hook"* ]] || [[ "$failure" == *"git"* ]]; then
            ((critical_failures++))
        fi
    done

    if [ $critical_failures -eq 0 ] && [ ${#CHANGES_MADE[@]} -gt 0 ]; then
        echo -e "${GREEN}🎉 Installation completed successfully!${NC}"
        echo ""
        echo "Quick start:"
        echo "  1. Navigate to any git repository"
        echo "  2. Make some changes and stage them: git add ."
        echo "  3. Commit: git commit"
        echo "  4. The hook will automatically generate a commit message"
        echo ""
        echo "Management commands:"
        echo "  ai-git-hooks status    # Check hook status"
        echo "  ai-git-hooks config    # Edit configuration"
        echo "  ai-git-hooks test      # Test in current repo"
        echo "  ai-git-hooks --help    # See all commands"
    else
        echo -e "${YELLOW}⚠️  Installation completed with issues${NC}"
        echo ""
        echo "Some components may not work properly. Please review the failed operations above."
        if ! command_exists yq; then
            echo "• Install yq manually: https://github.com/mikefarah/yq"
        fi
        if ! command_exists claude; then
            echo "• Install Claude CLI: https://claude.ai/code"
        fi
    fi

    echo ""
    echo "For more information, see the README.md file."
}

# Main installation flow
main() {
    echo -e "${BLUE}AI Git Hooks Installation${NC}"
    echo "=================================="
    echo ""

    if [ "$ASSUME_YES" = true ]; then
        log_info "Running in non-interactive mode (-y flag)"
    fi

    # Check if we're in the right directory
    if [ ! -f "$SCRIPT_DIR/prepare-commit-msg" ]; then
        log_error "Installation files not found. Please run this script from the ai-git-hooks directory."
        exit 1
    fi

    log_info "Starting installation process..."
    echo ""

    check_dependencies
    setup_hooks_directory
    install_hook
    install_config
    install_management_script
    configure_git

    print_summary
}

# Run main function
main "$@"