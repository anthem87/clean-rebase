#!/usr/bin/env bash

# install-git-rebase-clean.sh
# Installs git-rebase-clean script into ~/.git-tools for Unix-based systems

set -euo pipefail

GIT_TOOLS_DIR="$HOME/.git-tools"
SCRIPT_PATH="$GIT_TOOLS_DIR/git-rebase-clean"

echo "=== Installing git-rebase-clean ==="

mkdir -p "$GIT_TOOLS_DIR"

cat > "$SCRIPT_PATH" <<'EOF'
#!/usr/bin/env bash

set -e

STATE_FILE=$(git rev-parse --git-path .rebase-clean-state)
baseBranch=""
squashMsg="feat: complete work (squash)"
is_continue=false
is_abort=false
dryRun=false
use_sml=false

function print_help {
  cat <<USAGE

USAGE:
  git rebase-clean                          Squash and rebase current branch onto origin/develop
  git rebase-clean -r branch                Specify the base branch (e.g. origin/develop)
  git rebase-clean -sm "msg"                Set a custom squash commit message
  git rebase-clean -r branch -sm "msg"      Customize both base branch and message
  git rebase-clean -sml                     Edit squash commit message from list of existing commits
  git rebase-clean --continue               Resume after conflict resolution
  git rebase-clean --abort                  Abort and restore original state
  git rebase-clean --dry-run                Simulate actions without modifying anything
  git rebase-clean -h / --help              Show this help message

USAGE
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --continue) is_continue=true; shift ;;
    --abort) is_abort=true; shift ;;
    --dry-run) dryRun=true; shift ;;
    -r) baseBranch="$2"; shift 2 ;;
    -sm) squashMsg="$2"; shift 2 ;;
    -sml) use_sml=true; shift ;;
    -h|--help) print_help ;;
    *) echo "Unknown argument: $1"; echo "Use 'git rebase-clean -h' to see valid options."; exit 1 ;;
  esac
done

if $is_continue; then
  echo "[git-rebase-clean] Continuing rebase..."
  git rebase --continue || {
    echo "Rebase continue failed. Fix conflicts and run again."
    exit 1
  }

  currentBranch=$(cat "$STATE_FILE" | head -n1)
  git push --force-with-lease origin "$currentBranch"

  git branch -D temp-rebase-clean 2>/dev/null
  rm -f "$STATE_FILE"

  echo "Rebase completed and branch pushed."
  exit 0
fi

if $is_abort; then
  echo "[git-rebase-clean] Aborting rebase..."
  git rebase --abort || {
    echo "Failed to abort rebase. You might need to resolve it manually."
    exit 1
  }

  currentBranch=$(cat "$STATE_FILE" | head -n1)
  originalHead=$(cat "$STATE_FILE" | tail -n1)

  git checkout "$currentBranch"
  git reset --hard "$originalHead"

  git branch -D temp-rebase-clean 2>/dev/null
  rm -f "$STATE_FILE"

  echo "Rebase aborted and branch restored."
  exit 0
fi

if [ -d "$(git rev-parse --git-dir)/rebase-merge" ] || [ -d "$(git rev-parse --git-dir)/rebase-apply" ]; then
  echo "A rebase is currently in progress. Finish it or run 'git rebase-clean --continue' or '--abort'."
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working directory is dirty. Please commit or stash your changes first!"
  exit 1
fi

if [ -z "$baseBranch" ]; then
  echo "No base branch specified, defaulting to origin/develop"
  baseBranch="origin/develop"
fi

if ! git show-ref --verify --quiet "refs/remotes/$baseBranch" && ! git show-ref --verify --quiet "refs/heads/$baseBranch"; then
  echo "Error: base branch '$baseBranch' not found."
  echo "Please specify a valid branch with: -r <branch-name>"
  exit 1
fi

currentBranch=$(git rev-parse --abbrev-ref HEAD)
originalHead=$(git rev-parse HEAD)

echo "$currentBranch" > "$STATE_FILE"
echo "$originalHead" >> "$STATE_FILE"

if git rev-parse --verify --quiet temp-rebase-clean >/dev/null; then
  git branch -D temp-rebase-clean
fi

git checkout -b temp-rebase-clean

base=$(git merge-base "$baseBranch" HEAD)
echo "Merge base with $baseBranch: $base"

if $use_sml; then
  tempMsgFile=$(mktemp)
  git log "$base"..HEAD --pretty=format:"- %s" > "$tempMsgFile"

  if [ ! -s "$tempMsgFile" ]; then
    echo "No commits to squash. Aborting."
    git checkout "$currentBranch"
    git branch -D temp-rebase-clean
    rm -f "$STATE_FILE"
    exit 1
  fi

  echo "Opening editor (${EDITOR:-vi}) to edit squash commit message..."
  ${EDITOR:-vi} "$tempMsgFile" || {
    echo "Could not open editor. Falling back to default commit message."
    squashMsg="feat: complete work (squash)"
    rm -f "$tempMsgFile"
  }

  if [ -s "$tempMsgFile" ]; then
    squashMsg="$(cat "$tempMsgFile")"
    rm -f "$tempMsgFile"
  else
    echo "Empty message. Using default commit message."
    squashMsg="feat: complete work (squash)"
  fi
fi

git reset --soft "$base"

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
git checkout "$currentBranch"
git reset --hard temp-rebase-clean

if ! git rebase "$baseBranch"; then
  echo ""
  echo "Conflict during rebase!"
  echo "Resolve conflicts, then run:"
  echo "  git rebase-clean --continue"
  echo "or"
  echo "  git rebase-clean --abort"
  echo ""
  exit 1
fi

git push --force-with-lease origin "$currentBranch"
git branch -D temp-rebase-clean
rm -f "$STATE_FILE"

echo "Operation completed successfully."
EOF

chmod +x "$SCRIPT_PATH"

if [[ ":$PATH:" != *":$GIT_TOOLS_DIR:"* ]]; then
  echo 'export PATH="$HOME/.git-tools:$PATH"' >> "$HOME/.bashrc"
  echo "$GIT_TOOLS_DIR added to PATH. Restart your shell to activate it."
else
  echo "$GIT_TOOLS_DIR is already in PATH."
fi

echo ""
echo "Installation complete!"
echo "You can now run: git rebase-clean"