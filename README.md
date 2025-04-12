# 🧼 git-rebase-clean

A lightweight CLI tool to **squash all your commits**, **rebase onto `origin/develop`** (or any branch), and **force-push safely** with `--force-with-lease`.

---

## 🚀 Features

- Squash multiple commits into one with a custom message
- Rebase onto any branch (defaults to `origin/develop`)
- Automatically force-push safely using `--force-with-lease`
- Recover seamlessly after rebase conflicts with `--continue`
- Cross-platform: works on Bash, WSL, macOS, and PowerShell on Windows

---

## 📦 Installation

### Bash / WSL / Linux / macOS

```bash
source <(curl -fsSL https://raw.githubusercontent.com/anthem87/clean-rebase/main/install-git-rebase-clean.sh)
```

### Bash / WSL / Linux / macOS

```bash
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
iex "& { $(irm https://raw.githubusercontent.com/anthem87/clean-rebase/main/install-git-rebase-clean.ps1) }"
$env:Path = "$HOME\.git-tools;$env:Path"
```

# 🛠 Usage

```bash
git rebase-clean                    # squash & rebase onto origin/develop
git rebase-clean -r my-branch       # rebase onto a custom branch
git rebase-clean -sm "new message"  # custom commit message
git rebase-clean --continue         # resume after resolving conflicts
git rebase-clean -h / --help        # usage instructions
```

If a conflict occurs during rebase:

# Resolve the conflict manually

```bash
git add <resolved-files>
git rebase --continue
```

# Then resume the script
```bash
git rebase-clean --continue
```