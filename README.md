# git-rebase-clean

**Smart rebase tool that preserves commit history while simplifying conflict resolution**

## What It Does

`git-rebase-clean` temporarily squashes your commits into one, performs the rebase (with simpler conflict resolution), then automatically restores your original commit history.

Instead of resolving conflicts commit-by-commit, you resolve them once with the full context, then get your detailed history back.

## Installation

### Linux / macOS / WSL

```bash
# Install latest version (v2.0.0)
source <(curl -fsSL https://raw.githubusercontent.com/anthem87/clean-rebase/v2.0.0/install-git-rebase-clean.sh)
```

## Usage

### Basic Commands

```bash
# Rebase current branch onto origin/develop (default)
git rebase-clean

# Use a different base branch
git rebase-clean --base origin/main

# Custom squash message
git rebase-clean --squash-message "Feature complete"

# Auto-push after successful rebase
git rebase-clean --push

# Show help
git rebase-clean --help
```

### Handling Conflicts

```bash
# If conflicts occur during rebase:
# 1. Resolve the conflicts
# 2. Stage the resolved files
git add <resolved-files>

# 3. Continue the rebase
git rebase --continue

# 4. Continue rebase-clean to restore history
git rebase-clean --continue
```

### Other Operations

```bash
# Check status of ongoing operation
git rebase-clean --status

# Abort and restore original state
git rebase-clean --abort

# Clean up old cached files (older than 7 days)
git rebase-clean --gc 7

# Verbose output for debugging
git rebase-clean --verbose
```

## How It Works

1. **Save** - Records your current branch state and all commit metadata
2. **Squash** - Combines all commits into a single temporary commit
3. **Rebase** - Performs standard Git rebase (conflicts resolved once)
4. **Analyze** - Detects file renames and transformations
5. **Restore** - Re-applies original commits with saved diffs
6. **Clean** - Removes temporary branches and state

## Features

- **Checkpoints**: Every operation step is tracked and resumable
- **Idempotent**: Safe to re-run if interrupted
- **State preservation**: Original branch can always be restored with `--abort`
- **Smart transformations**: Handles file renames and deletions during rebase
- **Cross-platform**: Works on Linux, macOS, Windows (WSL/Git Bash)

## Options

| Option | Description |
|--------|-------------|
| `-r, --base BRANCH` | Base branch for rebase (default: `origin/develop`) |
| `-sm, --squash-message MSG` | Custom message for squashed commit |
| `--push` | Automatically push after successful rebase |
| `--push-interactive` | Ask before pushing (default) |
| `--continue` | Resume after resolving conflicts |
| `--abort` | Abort operation and restore original state |
| `--status` | Show current operation status |
| `--gc [DAYS]` | Remove cache files older than DAYS |
| `-v, --verbose` | Enable verbose output |
| `-h, --help` | Show help message |

## State Files

The tool maintains state in `.git/rebase-clean-state/`:
- `state` - Current operation state
- `history` - Saved commit metadata  
- `checkpoints` - Completed operation steps
- `cache/` - Saved diffs for each commit
- `transforms/` - Detected file transformations

## Testing

Run the test suite:

```bash
./git-rebase-clean-test.sh

# Run specific test category
./git-rebase-clean-test.sh -c basic

# Verbose output
./git-rebase-clean-test.sh -v

# Keep test artifacts for debugging
./git-rebase-clean-test.sh -k
```

## Requirements

- Unix-like environment (Linux, macOS, WSL, Git Bash)
- Bash 3.2+
- Git 2.0+
- Standard Unix tools (sed, awk, grep, sort, comm)

## Windows Users

Use one of these options:
- **WSL/WSL2** (recommended): Full compatibility
- **Git Bash**: Should work for most features
- **Native PowerShell**: Not supported