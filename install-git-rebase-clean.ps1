# install-git-rebase-clean.ps1
# Installs git-rebase-clean (Bash) into ~/.git-tools (compatible with Windows PowerShell 5.1+)

$gitToolsPath = "$HOME\.git-tools"
$scriptPath   = Join-Path $gitToolsPath "git-rebase-clean"

Write-Host "=== Installing git-rebase-clean ==="

# 1. Create ~/.git-tools if it doesn't exist
if (!(Test-Path $gitToolsPath)) {
    New-Item -ItemType Directory -Path $gitToolsPath | Out-Null
    Write-Host "Created folder: $gitToolsPath"
}

# 2. Define bash script content inline
$bashScript = @'
#!/usr/bin/env bash

# Script: git-rebase-clean
# Usage:
#   git rebase-clean                         → squash current branch and rebase it onto origin/develop
#   git rebase-clean -r my-branch            → rebase onto a specific base branch
#   git rebase-clean -sm "custom message"    → use a custom commit message
#   git rebase-clean -r branch -sm "msg"     → customize both base branch and message
#   git rebase-clean --continue              → resumes after conflict resolution
#   git rebase-clean --dry-run               → simulate all actions without changing anything
#   git rebase-clean -h / --help             → shows help message

set -e

STATE_FILE=$(git rev-parse --git-path .rebase-clean-state)
baseBranch=""
squashMsg="feat: complete work (squash)"
is_continue=false
dryRun=false

function print_help {
  cat <<EOF

USAGE:
  git rebase-clean                          Squash and rebase current branch onto origin/develop
  git rebase-clean -r branch                Specify the base branch (e.g. origin/develop)
  git rebase-clean -sm "msg"               Set a custom squash commit message
  git rebase-clean -r branch -sm "msg"     Customize both base branch and message
  git rebase-clean --continue              Resume after conflict resolution
  git rebase-clean --dry-run               Simulate actions without modifying anything
  git rebase-clean -h / --help             Show this help message

EOF
  exit 0
}

function continue_after_rebase {
  if [ ! -f "$STATE_FILE" ]; then
    echo "No rebase-clean state found to continue."
    exit 1
  fi

  currentBranch=$(cat "$STATE_FILE")

  if $dryRun; then
    echo "[dry-run] would restore $currentBranch from temp-rebase-clean"
    echo "[dry-run] would push --force-with-lease to origin/$currentBranch"
    echo "[dry-run] would delete temp-rebase-clean"
    echo "[dry-run] would remove $STATE_FILE"
    exit 0
  fi

  rm -f "$STATE_FILE"

  echo "Continuing rebase-clean on original branch: $currentBranch"
  git checkout "$currentBranch"
  git reset --hard temp-rebase-clean
  echo "Branch $currentBranch updated with clean commit."

  git push --force-with-lease origin "$currentBranch"
  echo "Forced push executed."

  git branch -D temp-rebase-clean
  echo "Temporary branch removed."

  echo "Operation completed successfully."
  exit 0
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --continue)
      is_continue=true
      shift
      ;;
    --dry-run)
      dryRun=true
      shift
      ;;
    -r)
      baseBranch="$2"
      shift 2
      ;;
    -sm)
      squashMsg="$2"
      shift 2
      ;;
    -h|--help)
      print_help
      ;;
    *)
      echo "Unknown argument: $1"
      print_help
      ;;
  esac
done

if $is_continue; then
  continue_after_rebase
fi

# Auto-detect baseBranch if not set
if [ -z "$baseBranch" ]; then
  echo "No base branch specified, defaulting to origin/develop"
  baseBranch="origin/develop"
fi

# Validate baseBranch
if ! git show-ref --verify --quiet "refs/remotes/$baseBranch" && \
   ! git show-ref --verify --quiet "refs/heads/$baseBranch"; then
  echo "Error: base branch '$baseBranch' not found."
  echo "Please specify a valid branch with: -r <branch-name>"
  exit 1
fi

echo "Using base branch: $baseBranch"

currentBranch=$(git rev-parse --abbrev-ref HEAD)
echo "Current branch: $currentBranch"

# Cleanup temp branch if exists
if git rev-parse --verify --quiet temp-rebase-clean >/dev/null; then
  if $dryRun; then
    echo "[dry-run] would delete existing temp-rebase-clean branch"
  else
    git branch -D temp-rebase-clean
  fi
fi

# Create temp branch
if $dryRun; then
  echo "[dry-run] would create temp branch from $currentBranch"
else
  git checkout -b temp-rebase-clean
fi

# Get merge base
base=$(git merge-base "$baseBranch" HEAD)
echo "Merge base with $baseBranch: $base"

if $dryRun; then
  echo "[dry-run] would reset --soft to $base"
  echo "[dry-run] would commit staged changes as: \"$squashMsg\""
  echo "[dry-run] would checkout $currentBranch"
  echo "[dry-run] would reset --hard to temp-rebase-clean"
  echo "[dry-run] would rebase $currentBranch onto $baseBranch"
  echo "[dry-run] would push --force-with-lease to origin/$currentBranch"
  echo "[dry-run] would delete temp-rebase-clean"
  exit 0
fi

# Soft reset to squash
git reset --soft "$base"

# Check if anything to commit
if git diff --cached --quiet; then
  echo "Nothing to commit. Aborting."
  git checkout "$currentBranch"
  git branch -D temp-rebase-clean
  exit 1
fi

git commit -m "$squashMsg"
echo "Single commit created: \"$squashMsg\""

git fetch origin
echo "Fetched origin."

# Apply the clean commit to current branch
git checkout "$currentBranch"
git reset --hard temp-rebase-clean
echo "Branch $currentBranch updated with squashed commit."

echo "Starting rebase of $currentBranch onto $baseBranch..."
if ! git rebase "$baseBranch"; then
  echo ""
  echo "Conflict during rebase!"
  echo "Resolve manually, then run:"
  echo "  git add <files>"
  echo "  git rebase --continue"
  echo "  git rebase-clean --continue"
  echo ""
  echo "$currentBranch" > "$STATE_FILE"
  exit 1
fi

git push --force-with-lease origin "$currentBranch"
echo "Forced push complete."

git branch -D temp-rebase-clean
rm -f "$STATE_FILE"

echo "Operation completed successfully."
'@

Write-Host "Writing the bash script in UTF-8 (no BOM)..."
$utf8NoBOM = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($scriptPath, $bashScript, $utf8NoBOM)

Write-Host "Script saved to: $scriptPath"

# 3. Add ~/.git-tools to PATH if not already there
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if (-not ($currentPath -split ";" | Where-Object { $_ -eq $gitToolsPath })) {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$gitToolsPath", "User")
    Write-Host "$gitToolsPath added to the user PATH."
    Write-Host "Restart your terminal to make it effective."
} else {
    Write-Host "$gitToolsPath is already in the user PATH."
}

Write-Host ""
Write-Host "Installation complete!"
Write-Host "You can now run: git rebase-clean"
