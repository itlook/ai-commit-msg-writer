# AI Commit Message Writer

**Transform your git commits from bland to brilliant!** 🚀

Stop writing "fixed stuff" and "updated code" commit messages. This tool generates **meaningful, professional commit messages** that explain both *what* changed and *why* - making your git history a joy to read and your team more productive.

## Why You Need This

**The Problem:** Bad commit messages waste everyone's time
- `git log` becomes useless noise
- Code reviews take longer without context
- Team members struggle to understand changes
- Inconsistent styling across the team

**The Solution:** AI analyzes your diff + your reason = perfect commit messages
- **Contextual**: Understands what actually changed in your code
- **Meaningful**: Explains the "why" behind changes when you provide context
- **Consistent**: Enforces conventional commit format across your entire team
- **Professional**: Makes your git history look like it was written by senior developers

**One simple install. Works everywhere. Your whole team will love you.**

## ✨ What Makes This Special

- **Instant Setup**: One command installs globally for all your repositories
- **Smart Analysis**: Combines git diff with your reasoning for perfect context
- **Team Unity**: Consistent commit style across your entire organization
- **Flexible**: Easy bypass options when you need manual control
- **Configurable**: Customize prompts and rules to match your team's needs

## 🚀 Get Started in 30 Seconds

**Requirements:** Git 2.0+, [Claude Code CLI](https://docs.anthropic.com/claude/docs/claude-code), and `yq`

**Install everywhere with one command:**
```bash
./install.sh
```
That's it! Works immediately in all your repositories.

## 📖 How It Works

**1. Normal workflow:**
```bash
git add .
git commit
```

**2. Interactive context prompt appears:**
```
------------------------------------------------------
   AI Commit Messages with Reason. Not Just the What
    https://github.com/itlook/ai-commit-msg-writer/
------------------------------------------------------

Reason For This Change:
Because WHY is more important than WHAT
```
Type your reasoning (or press Enter to skip) - this helps AI understand the "why" behind your changes.

**3. AI analyzes:**
- Your git diff (what changed)
- Your reasoning (why you changed it)
- Project context (README.md)
- Repository patterns and conventions

**4. Perfect commit message generated automatically!**

**Alternative: Skip the prompt by providing context upfront:**
```bash
WHY="fixing critical login bug for mobile users" git commit
```

**Need manual control? Easy bypass options:**
```bash
git commit -m "your own message"    # Skip AI with -m flag
NOAI=1 git commit                  # Skip AI with environment variable
git commit --no-verify             # Skip all hooks
```

## ⚙️ Configuration

**Global config:** `~/.ai-commit-global-config.yaml`
**Per-repo override:** `.ai-commit-config.yaml`

### Key Settings
```yaml
enabled: true                          # Enable/disable globally
message_generation_enabled: true       # Toggle AI generation
excluded_repositories: ["temp-repo"]   # Skip specific repos
file_ignore_patterns: ["*.log"]        # Ignore file types
max_subject_length: 50                 # Subject line limit
max_body_line_length: 72               # Body line wrap
use_why_variable: true                 # Enable WHY context
prompt_for_why: true                   # Interactive WHY prompts
skip_patterns: ["^WIP", "^TEMP"]       # Skip if message matches
```

### Advanced: Custom AI Prompts
Customize how AI generates messages by editing `prompt_template` in your config. The template supports variables like `{repo_name}`, `{diff}`, `{why_context}`, `{author_name}`, etc.

## 🛠️ Management Commands

```bash
ai-git-hooks status        # Check configuration and status
ai-git-hooks test          # Test hook in current repository
ai-git-hooks config        # Edit global configuration
ai-git-hooks enable        # Enable hooks globally
ai-git-hooks disable       # Disable hooks globally
ai-git-hooks exclude repo  # Exclude specific repository
ai-git-hooks include repo  # Include specific repository
```

## 🔧 Troubleshooting

**Hook not running?**
```bash
which claude                        # Verify AI CLI is installed
git config --global core.hooksPath  # Check hooks path is set
ai-git-hooks status                 # Check configuration
```

**Common bypass methods:**
```bash
git commit -m "message"    # Use your own message
NOAI=1 git commit         # Skip AI completely
git commit --no-verify    # Skip all git hooks
```

**Configuration issues:**
- Global config: `~/.ai-commit-global-config.yaml`
- Local override: `.ai-commit-config.yaml` (in repo root)
- Edit with: `ai-git-hooks config`

## 🎯 Pro Tips

- **Provide context:** `WHY="fixing critical security bug" git commit`
- **Team setup:** Share your customized config file across the team
- **Repository-specific rules:** Use local `.ai-commit-config.yaml` for special repos
- **Skip patterns:** Configure regex patterns to skip WIP/TEMP commits automatically

## 📋 Manual Installation

If you prefer to install manually instead of using `./install.sh`:

```bash
# 1. Setup hooks directory
mkdir -p ~/.git-hooks
cp prepare-commit-msg ~/.git-hooks/
chmod +x ~/.git-hooks/prepare-commit-msg

# 2. Configure Git to use hooks directory globally
git config --global core.hooksPath ~/.git-hooks

# 3. Copy global configuration file
cp ai-commit-global-config.yaml ~/.ai-commit-global-config.yaml

# 4. Copy management script (optional)
cp ai-git-hooks.sh ~/.local/bin/ai-git-hooks
chmod +x ~/.local/bin/ai-git-hooks
```

**Verify installation:**
```bash
git config --global core.hooksPath  # Should show: ~/.git-hooks
which ai-git-hooks                  # Should show: ~/.local/bin/ai-git-hooks
```

## License

MIT License - see LICENSE file.
