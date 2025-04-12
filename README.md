# 🧼 git-rebase-clean

A lightweight CLI tool to **squash your current branch into a single commit**, **rebase a base branch (like `origin/develop`) onto it**, and **force-push safely** with `--force-with-lease`.

---

## 🚀 Features

- Squash all local commits into one (with optional custom message)
- Rebase a base branch (e.g. `origin/develop`) **onto your current branch**
- Safely force-push with `--force-with-lease`
- Resume after rebase conflicts with `--continue`
- Dry-run support: simulate everything without modifying your repo
- Cross-platform: works on Bash, WSL, macOS, and PowerShell on Windows

---

## 📦 Installation

### Bash / WSL / Linux / macOS

```bash
source <(curl -fsSL https://raw.githubusercontent.com/anthem87/clean-rebase/main/install-git-rebase-clean.sh)
```

### PowerShell / Windows

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
iex "& { $(irm https://raw.githubusercontent.com/anthem87/clean-rebase/main/install-git-rebase-clean.ps1) }"
$env:Path = "$HOME\.git-tools;$env:Path"
```

---

## 🛠 Usage

```bash
git rebase-clean                          # squash & rebase origin/develop onto current branch
git rebase-clean -r origin/main           # use a custom base branch
git rebase-clean -sm "your message"       # squash with custom message
git rebase-clean -r origin/main -sm "..." # combine both options
git rebase-clean --dry-run                # simulate all actions without modifying anything
git rebase-clean --continue               # resume after conflict resolution
git rebase-clean -h / --help              # show usage
```

---

## 🧩 Conflict handling

If a conflict occurs during the rebase:

1. Resolve the conflict manually:

```bash
git add <resolved-files>
git rebase --continue
```

2. Then tell the tool to finish the flow:

```bash
git rebase-clean --continue
```

---

## ✅ Example

```bash
git checkout feature/login
git rebase-clean -r origin/develop -sm "feat: login page complete"
```

This will:
- squash all commits on `feature/login`
- rebase the latest `origin/develop` **on top of it**
- push the updated history back with `--force-with-lease`
