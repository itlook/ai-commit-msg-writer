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
