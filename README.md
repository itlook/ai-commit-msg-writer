# Claude Git Hooks

Global Git hook that auto-generates conventional commit messages using Claude Code CLI.

## Features

- Automatic commit message generation with Claude Code CLI
- Conventional commit format (feat, fix, docs, etc.)
- Global installation for all repositories
- Configurable filtering and exclusions
- Per-repository overrides

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/claude/docs/claude-code)
- Git 2.0+
- `yq` (YAML processor)

## Quick Install

```bash
./install.sh
```

Or install manually:

```bash
# 1. Setup hooks directory
mkdir -p ~/.git-hooks
cp prepare-commit-msg ~/.git-hooks/
chmod +x ~/.git-hooks/prepare-commit-msg

# 2. Configure Git
git config --global core.hooksPath ~/.git-hooks

# 3. Copy global config (optional)
cp claude-commit-global-config.yaml ~/.claude-commit-global-config.yaml
```

## Configuration

**Global**: `~/.claude-commit-global-config.yaml`
**Per-repo**: `.claude-commit-config.yaml`

Key settings:
- `enabled`: Enable/disable globally
- `excluded_repositories`: Skip specific repos
- `file_ignore_patterns`: Exclude file types
- `max_subject_length`: Subject line limit (50)
- `max_body_line_length`: Body wrap (72)
- `prompt_template`: Customize the LLM prompt for message generation

## Usage

```bash
git add .
git commit  # Hook auto-generates commit message
```

## Management

```bash
claude-git-hooks status     # Check status
claude-git-hooks test       # Test in current repo
claude-git-hooks config     # Edit configuration
claude-git-hooks disable    # Disable globally
```

## Customizing Commit Message Generation

You can customize the prompt used to generate commit messages by editing the `prompt_template` in your configuration file:

```yaml
# ~/.claude-commit-global-config.yaml
prompt_template: |
  Generate a conventional commit message for the git repository "{repo_name}".

  Subject line requirements:
  - Maximum {max_subject_length} characters
  - Format: type(scope): description
  - Use conventional commit types: feat, fix, docs, style, refactor, test, chore

  Body requirements:
  - Wrap lines at {max_body_length} characters
  - Explain the what and why of changes
  - Group related changes by topic/theme, not by file

  Here's the diff:
  {diff}

  Generate only the commit message without any additional text.
```

The template supports these variables:
- `{repo_name}`: Current repository name
- `{max_subject_length}`: Subject line character limit
- `{max_body_length}`: Body line wrap length
- `{diff}`: The git diff content

## Troubleshooting

**Hook not running?**
```bash
which claude                              # Check Claude CLI
git config --global core.hooksPath       # Verify hooks path
```

**Skip for one commit:**
```bash
git commit --no-verify
```

**Disable temporarily:**
```yaml
# In ~/.claude-commit-global-config.yaml
enabled: false
```

## License

MIT License - see LICENSE file.
