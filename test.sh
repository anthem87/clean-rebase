#!/usr/bin/env bash

# test.sh
# Tests git-rebase-clean with conflicts in the current repository

set -e

BRANCH_BASE="develop-test"
BRANCH_FEATURE="feature-conflict"
FILE_NAME="file.txt"

# === Cleanup: remove existing local branches ===
git branch -D "$BRANCH_BASE" 2>/dev/null || true
git branch -D "$BRANCH_FEATURE" 2>/dev/null || true

# === Cleanup: remove existing remote branches ===
git push origin --delete "$BRANCH_BASE" 2>/dev/null || true
git push origin --delete "$BRANCH_FEATURE" 2>/dev/null || true

# === Checkout main branch ===
git checkout main

# === Create develop-test with base content ===
git checkout -b "$BRANCH_BASE"
echo "shared line" > "$FILE_NAME"
git add "$FILE_NAME"
git commit -m "test: base commit on $BRANCH_BASE"

# === Modify develop-test to create conflict ===
echo "change from develop" > "$FILE_NAME"
git commit -am "test: conflicting change from develop"

# === Create feature-conflict from previous commit ===
git checkout -b "$BRANCH_FEATURE" HEAD~1
echo "change from feature" > "$FILE_NAME"
git commit -am "test: conflicting change from feature"

# === Simulate a local remote ===
git remote remove origin-fake 2>/dev/null || true
git remote add origin-fake .
git fetch origin-fake

# === Run git-rebase-clean ===
echo ""
echo "Running: git rebase-clean on $BRANCH_FEATURE (vs $BRANCH_BASE)"
git checkout "$BRANCH_FEATURE"

if git rebase-clean -r "$BRANCH_BASE" -sm "test: squash with conflict"; then
    echo ""
    echo "Test completed successfully. No conflicts detected."
    TEST_PASSED=true
else
    echo ""
    echo "Conflict detected. Resolving automatically:"
    echo "  git add $FILE_NAME"
    echo "  git rebase --continue"
    echo "  git rebase-clean --continue"

    git add "$FILE_NAME"
    GIT_EDITOR=true git rebase --continue
    git rebase-clean --continue
    TEST_PASSED=true
fi

# === Show recent commit log ===
echo ""
echo "Partial log for branch $BRANCH_FEATURE:"
git log --oneline --graph --decorate -n 5

# === Cleanup: remove local branches ===
git checkout main
git branch -D "$BRANCH_BASE" 2>/dev/null || true
git branch -D "$BRANCH_FEATURE" 2>/dev/null || true

# === Cleanup: remove remote branches ===
git push origin --delete "$BRANCH_BASE" 2>/dev/null || true
git push origin --delete "$BRANCH_FEATURE" 2>/dev/null || true

# === Cleanup: remove fake remote references ===
git remote remove origin-fake 2>/dev/null || true
rm -rf .git/refs/remotes/origin-fake

# === Final result ===
echo ""
if [ "$TEST_PASSED" = true ]; then
    echo "TEST PASSED: git rebase-clean executed and completed successfully."
else
    echo "TEST FAILED: git rebase-clean did not complete as expected."
fi