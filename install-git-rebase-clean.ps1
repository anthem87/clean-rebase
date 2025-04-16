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
# Usage (tabular style):
#
#   git rebase-clean                          Squash and rebase current branch onto origin/develop
#   git rebase-clean -r branch                Specify the base branch (e.g. origin/develop)
#   git rebase-clean -sm "msg"                Set a custom squash commit message
#   git rebase-clean -r branch -sm "msg"      Customize both base branch and message
#   git rebase-clean --continue               Resume after conflict resolution
#   git rebase-clean --abort                  Abort and restore original state
#   git rebase-clean --dry-run                Simulate all actions without modifying anything
#   git rebase-clean -h / --help              Show this help message
#

set -e

STATE_FILE=$(git rev-parse --git-path .rebase-clean-state)
baseBranch=""
squashMsg="feat: complete work (squash)"
is_continue=false
is_abort=false
dryRun=false

function print_help {
  cat <<EOF

USAGE:
  git rebase-clean                          Squash and rebase current branch onto origin/develop
  git rebase-clean -r branch                Specify the base branch (e.g. origin/develop)
  git rebase-clean -sm "msg"                Set a custom squash commit message
  git rebase-clean -r branch -sm "msg"      Customize both base branch and message
  git rebase-clean --continue               Resume after conflict resolution
  git rebase-clean --abort                  Abort and restore original state
  git rebase-clean --dry-run                Simulate actions without modifying anything
  git rebase-clean -h / --help              Show this help message

EOF
  exit 0
}

function abort_rebase_clean {
  # We must have a state file to know how to revert
  if [ ! -f "$STATE_FILE" ]; then
    echo "No rebase-clean state found to abort."
    exit 1
  fi

  # Read lines from state file:
  #   line 1 = original branch name
  #   line 2 = original HEAD commit
  mapfile -t lines < "$STATE_FILE"
  local originalBranch="${lines[0]}"
  local originalHead="${lines[1]}"

  echo "Aborting git rebase-clean..."

  # If there's a rebase in progress, abort it
  if [ -d "$(git rev-parse --git-dir)/rebase-merge" ] || [ -d "$(git rev-parse --git-dir)/rebase-apply" ]; then
    echo "A rebase is in progress. Running 'git rebase --abort'..."
    git rebase --abort || true
  fi

  # Switch back to original branch
  git checkout "$originalBranch" 2>/dev/null || {
    echo "Error: could not check out original branch '$originalBranch'."
    exit 1
  }

  # Reset to the original HEAD commit
  echo "Restoring '$originalBranch' to commit $originalHead"
  git reset --hard "$originalHead"

  # Clean up temp branch if it still exists
  if git rev-parse --verify --quiet temp-rebase-clean >/dev/null; then
    git branch -D temp-rebase-clean
  fi

  # Remove state file
  rm -f "$STATE_FILE"

  echo "All changes reverted. Rebase-clean aborted."
  exit 0
}

function continue_after_rebase {
  if [ ! -f "$STATE_FILE" ]; then
    echo "No rebase-clean state found to continue."
    exit 1
  fi

  # Read original branch from line 1 (we only need it for the final reset/push).
  # We do not necessarily need the original HEAD if we're continuing.
  mapfile -t lines < "$STATE_FILE"
  local currentBranch="${lines[0]}"
  # line 2 is the original HEAD, but not needed here

  # Safety check before continuing
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Working directory is dirty. Please commit or stash your changes first."
    exit 1
  fi

  # If a rebase is still in progress, continue it
  if [ -d "$(git rev-parse --git-dir)/rebase-merge" ] || [ -d "$(git rev-parse --git-dir)/rebase-apply" ]; then
    echo "Git rebase is in progress... attempting to continue"
    if ! git rebase --continue; then
      echo "Git rebase could not continue. Please resolve all conflicts manually, stage changes, then retry."
      exit 1
    fi
  fi

  if $dryRun; then
    echo "[dry-run] would restore branch: $currentBranch from temp-rebase-clean"
    echo "[dry-run] would push --force-with-lease to origin/$currentBranch"
    echo "[dry-run] would delete temp-rebase-clean"
    echo "[dry-run] would remove $STATE_FILE"
    exit 0
  fi

  # We're good: remove the state file
  rm -f "$STATE_FILE"

  echo "Continuing rebase-clean on original branch: $currentBranch"
  git checkout "$currentBranch"
  git reset --hard temp-rebase-clean
  echo "Branch '$currentBranch' updated with clean commit."

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
    --abort)
      is_abort=true
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
      echo "Use 'git rebase-clean -h' to see valid options."
      exit 1
      ;;
  esac
done

# Decide the user’s intent
if $is_continue; then
  continue_after_rebase
fi

if $is_abort; then
  abort_rebase_clean
fi

# If a rebase is already in progress, bail out
if [ -d "$(git rev-parse --git-dir)/rebase-merge" ] || [ -d "$(git rev-parse --git-dir)/rebase-apply" ]; then
  echo "A rebase is currently in progress. Finish it or run 'git rebase-clean --continue' or 'git rebase-clean --abort'."
  exit 1
fi

# Check for dirty working directory
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working directory is dirty. Please commit or stash your changes first!"
  exit 1
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

currentBranch=$(git rev-parse --abbrev-ref HEAD)
originalHead=$(git rev-parse HEAD)  # We'll need this if user aborts

echo "Using base branch: $baseBranch"
echo "Current branch: $currentBranch"

# Write state file now: line 1 = current branch, line 2 = original HEAD
echo "$currentBranch" > "$STATE_FILE"
echo "$originalHead" >> "$STATE_FILE"

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
  echo "[dry-run] would remove $STATE_FILE"
  exit 0
fi

# Soft reset to squash
git reset --soft "$base"

# Check if there's anything to commit
if git diff --cached --quiet; then
  echo "Nothing to commit from merge base to HEAD. Aborting."
  git checkout "$currentBranch"
  git branch -D temp-rebase-clean
  rm -f "$STATE_FILE"
  exit 1
fi

git commit -m "$squashMsg"
echo "Single commit created: \"$squashMsg\""

git fetch origin
echo "Fetched origin."

# Apply the clean commit to current branch
git checkout "$currentBranch"
git reset --hard temp-rebase-clean
echo "Branch '$currentBranch' updated with squashed commit."

echo "Starting rebase of '$currentBranch' onto '$baseBranch'..."
if ! git rebase "$baseBranch"; then
  echo ""
  echo "Conflict during rebase!"
  echo "Resolve conflicts, then stage changed files and run either:"
  echo "  git rebase-clean --continue"
  echo "or"
  echo "  git rebase-clean --abort"
  echo ""
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