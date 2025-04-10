# 🧼 git-rebase-clean

This script automates **squashing** and **rebasing** onto `origin/develop`, producing a single clean commit and force-pushing it safely.

---

## 📦 Installation (Bash / WSL / Linux / macOS)

Installs the `git-rebase-clean` script in `~/.git-tools` and makes it globally available in your terminal:

```bash
source <(curl -fsSL https://raw.githubusercontent.com/anthem87/clean-rebase/main/install-git-rebase-clean.sh)
```

After installation, you can use:

```bash
git rebase-clean
```

## 📦 Installation (Windows)

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
iex "& { $(irm https://raw.githubusercontent.com/anthem87/clean-rebase/main/install-git-rebase-clean.ps1) }"
$env:Path = "$HOME\.git-tools;$env:Path"
```

If you encounter conflicts:

```bash
git add <resolved-files>
git rebase --continue
git rebase-clean --continue
```