# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains a global Git prepare-commit-msg hook that automates commit message generation using Claude Code CLI. The hook generates well-formatted, conventional commit messages by analyzing staged changes and providing contextual commit messages for any Git repository.

## Key Files and Architecture

- `prepare-commit-msg`: The main Git hook script that generates commit messages
- `claude-git-hooks.sh`: Management script for hook administration - enable/disable, configuration, testing
- `claude-commit-global-config.yaml`: Default global configuration with sensible defaults and prompt template
- `install.sh`: Cross-platform installation script with dependency checking and error handling
- `README.md`: Project documentation and installation instructions

## Development Commands

Test the hook functionality:
```bash
./claude-git-hooks.sh test      # Test hook in current repository
./claude-git-hooks.sh status    # Show current configuration and status
```

Installation and setup:
```bash
./install.sh                   # Interactive installation
./install.sh -y               # Non-interactive installation
```

Management operations:
```bash
./claude-git-hooks.sh enable   # Enable hooks globally
./claude-git-hooks.sh disable  # Disable hooks globally
./claude-git-hooks.sh config   # Edit global configuration
./claude-git-hooks.sh exclude [repo]  # Exclude specific repository
./claude-git-hooks.sh include [repo]  # Include specific repository
```

## Hook Architecture

The `prepare-commit-msg` hook is a comprehensive bash script that:

1. **Configuration System**: Hierarchical configuration loading (global → local override)
   - Global: `~/.claude-commit-global-config.yaml`
   - Local: `.claude-commit-config.yaml` (per-repository)
   - Uses `yq` for YAML parsing and manipulation

2. **Repository Filtering**: Multi-level filtering system
   - Repository exclusion by name
   - File pattern exclusion (build artifacts, logs, etc.)
   - Skip patterns for existing commit messages (WIP, TEMP, etc.)

3. **Diff Analysis**: Intelligent change processing
   - Filters out ignored files before analysis
   - Provides only relevant diff content to Claude
   - Handles empty diffs gracefully

4. **Claude Integration**: Configurable prompt generation
   - Uses customizable prompt template from configuration
   - Supports variable substitution: `{repo_name}`, `{max_subject_length}`, `{max_body_length}`, `{diff}`
   - Enforces grouping by topic/theme rather than file-by-file changes
   - Includes repository context and formatting requirements

5. **Message Formatting**: Conventional commit compliance
   - Configurable subject line length (default: 50 chars)
   - Body line wrapping (default: 72 chars)
   - Extracts structured output from Claude responses

## Configuration Management

The hook supports comprehensive YAML configuration with hierarchical loading:

### Core Settings
- `enabled`: Global enable/disable flag
- `message_generation_enabled`: Toggle message generation
- `max_subject_length`: Subject line character limit (default: 50)
- `max_body_line_length`: Body line wrap length (default: 72)
- `prompt_template`: Customizable prompt template for Claude with variable substitution

### Filtering Configuration
- `excluded_repositories`: Array of repository names to skip
- `skip_patterns`: Regex patterns to skip message generation
- `file_ignore_patterns`: File patterns to exclude from diff analysis

### Management Commands
The `claude-git-hooks.sh` script provides:
- `status`: Show current configuration and hook status
- `enable/disable`: Toggle hooks globally
- `exclude/include [repo]`: Manage repository exclusions
- `config`: Edit global configuration
- `test`: Test hook functionality in current repository

## Hook Execution Flow

1. **Pre-flight checks**: Verify commit type, hook enabled, Claude CLI available
2. **Repository filtering**: Check if current repo is excluded
3. **Diff collection**: Get staged changes and filter out ignored files
4. **Message generation**: Load configurable prompt template, substitute variables, and call Claude CLI
5. **Output processing**: Extract commit message from Claude response
6. **File writing**: Write formatted message to Git's commit message file

## Installation Requirements

- Claude Code CLI installed and configured
- Git 2.0+ with global hooks directory configured
- `yq` for YAML configuration parsing
- Bash shell environment

## Important Implementation Details

### Configuration File Locations
- Global config: `~/.claude-commit-global-config.yaml`
- Local override: `.claude-commit-config.yaml` (per-repository)
- Global hooks directory: `~/.git-hooks/`
- Management script: `~/.local/bin/claude-git-hooks`

### Key Functions in prepare-commit-msg:
- `load_config()`: Merges global and local YAML configs using yq
- `filter_diff()`: Excludes ignored files based on patterns
- `generate_commit_message()`: Calls Claude CLI with template substitution
- `matches_skip_pattern()`: Checks commit message skip patterns

### Prompt Template Variables
The prompt template supports these substitutions:
- `{repo_name}`: Current repository name
- `{max_subject_length}`: Subject line character limit
- `{max_body_length}`: Body line wrap length
- `{diff}`: Filtered git diff content

### Error Handling
- Gracefully handles missing dependencies (yq, claude CLI)
- Skips execution during git rebase operations
- Filters empty diffs and respects exclusion patterns
- Provides detailed logging with color-coded output

## Security Considerations

The hook processes git diff output and sends it to Claude Code CLI. It filters out sensitive file patterns and respects git's ignore patterns. No credentials or sensitive data should be included in commit analysis.

## Code Quality Guidelines

When working on files in this repository:
- NEVER leave trailing spaces at the end of lines in any files
- Maintain consistent formatting throughout the codebase