#!/usr/bin/env bash

# test.sh
# Tests git-rebase-clean with -sml and no conflicts (Linux/macOS/WSL compatible)

set -euo pipefail

BRANCH_BASE="develop-test"
BRANCH_FEATURE="feature-no-conflict"
FILE_NAME="file.txt"
TEST_PASSED=false

# Simulate safe git command
safe_git() {
  git "$@" 2>/dev/null || true
}

# === Cleanup: remove existing local branches ===
safe_git branch -D "$BRANCH_BASE"
safe_git branch -D "$BRANCH_FEATURE"

# === Cleanup: remove existing remote branches ===
safe_git push origin --delete "$BRANCH_BASE"
safe_git push origin --delete "$BRANCH_FEATURE"

# === Checkout main branch ===
git checkout main

# === Create develop-test with unrelated file ===
git checkout -b "$BRANCH_BASE"
echo "base content" > base.txt
git add base.txt
git commit -m "test: base commit on $BRANCH_BASE"

# === Create feature-no-conflict from develop-test ===
git checkout -b "$BRANCH_FEATURE"
echo "feature commit 1" > "$FILE_NAME"
git add "$FILE_NAME"
git commit -m "test: feature commit 1"

echo "feature commit 2" > "$FILE_NAME"
git commit -am "test: feature commit 2"

# === Simulate a local remote ===
safe_git remote remove origin-fake
git remote add origin-fake .
git fetch origin-fake

# === Set fake editor for -sml ===
export GIT_EDITOR='sh -c "echo test: squash success > $1" --'

# === Run git-rebase-clean ===
echo ""
echo "Running: git rebase-clean -r $BRANCH_BASE -sml"
git checkout "$BRANCH_FEATURE"

if git rebase-clean -r "$BRANCH_BASE" -sml; then
  COMMIT_MESSAGE=$(git log -1 --pretty=%B)

  if [[ "$COMMIT_MESSAGE" == *squash success* ]]; then
    echo -e "\n✅ Final commit message contains expected squash text:"
    echo "$COMMIT_MESSAGE"
    TEST_PASSED=true
  else
    echo -e "\n❌ Unexpected final commit message:"
    echo "$COMMIT_MESSAGE"
    TEST_PASSED=false
  fi
else
  echo -e "\n❌ git rebase-clean failed unexpectedly."
  TEST_PASSED=false
fi

# === Show recent commit log ===
echo -e "\nPartial log for branch $BRANCH_FEATURE:"
git log --oneline --graph --decorate -n 5

# === Cleanup: remove local branches ===
git checkout main
safe_git branch -D "$BRANCH_BASE"
safe_git branch -D "$BRANCH_FEATURE"

# === Cleanup: remove remote branches ===
safe_git push origin --delete "$BRANCH_BASE"
safe_git push origin --delete "$BRANCH_FEATURE"

# === Cleanup: remove fake remote references ===
safe_git remote remove origin-fake
rm -rf ".git/refs/remotes/origin-fake"

# === Final result ===
echo ""
if [ "$TEST_PASSED" = true ]; then
  echo "TEST PASSED: git rebase-clean executed and completed successfully."
else
  echo "TEST FAILED: git rebase-clean did not complete as expected."
fi
