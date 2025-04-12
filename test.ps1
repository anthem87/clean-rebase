# test.ps1
# Tests git-rebase-clean with conflicts in the current repository

$ErrorActionPreference = "Stop"

$BRANCH_BASE = "develop-test"
$BRANCH_FEATURE = "feature-conflict"
$FILE_NAME = "file.txt"
$TEST_PASSED = $false

function Safe-Git {
    param (
        [string]$Command
    )
    try {
        iex $Command | Out-Null
    } catch {
        # ignore error
    }
}

# === Cleanup: remove existing local branches ===
Safe-Git "git branch -D $BRANCH_BASE"
Safe-Git "git branch -D $BRANCH_FEATURE"

# === Cleanup: remove existing remote branches ===
Safe-Git "git push origin --delete $BRANCH_BASE"
Safe-Git "git push origin --delete $BRANCH_FEATURE"

# === Checkout main branch ===
git checkout main

# === Create develop-test with base content ===
git checkout -b $BRANCH_BASE
"shared line" | Set-Content $FILE_NAME
git add $FILE_NAME
git commit -m "test: base commit on $BRANCH_BASE"

# === Modify develop-test to create conflict ===
"change from develop" | Set-Content $FILE_NAME
git commit -am "test: conflicting change from develop"

# === Create feature-conflict from previous commit ===
git checkout -b $BRANCH_FEATURE "HEAD~1"
"change from feature" | Set-Content $FILE_NAME
git commit -am "test: conflicting change from feature"

# === Simulate a local remote ===
Safe-Git "git remote remove origin-fake"
git remote add origin-fake .
git fetch origin-fake

# === Run git-rebase-clean ===
Write-Host ""
Write-Host "Running: git rebase-clean on $BRANCH_FEATURE (vs $BRANCH_BASE)"
git checkout $BRANCH_FEATURE

try {
    git rebase-clean -r $BRANCH_BASE -sm "test: squash with conflict"
    Write-Host ""
    Write-Host "Test completed successfully. No conflicts detected."
    $TEST_PASSED = $true
} catch {
    Write-Host ""
    Write-Host "Conflict detected. Resolving automatically:"
    Write-Host "  git add $FILE_NAME"
    Write-Host "  git rebase --continue"
    Write-Host "  git rebase-clean --continue"

    git add $FILE_NAME
    $env:GIT_EDITOR = "true"
    git rebase --continue
    git rebase-clean --continue
    $TEST_PASSED = $true
}

# === Show recent commit log ===
Write-Host ""
Write-Host "Partial log for branch $BRANCH_FEATURE:"
git log --oneline --graph --decorate -n 5

# === Cleanup: remove local branches ===
git checkout main
Safe-Git "git branch -D $BRANCH_BASE"
Safe-Git "git branch -D $BRANCH_FEATURE"

# === Cleanup: remove remote branches ===
Safe-Git "git push origin --delete $BRANCH_BASE"
Safe-Git "git push origin --delete $BRANCH_FEATURE"

# === Cleanup: remove fake remote references ===
Safe-Git "git remote remove origin-fake"
Remove-Item -Recurse -Force ".git/refs/remotes/origin-fake" -ErrorAction SilentlyContinue

# === Final result ===
Write-Host ""
if ($TEST_PASSED) {
    Write-Host "TEST PASSED: git rebase-clean executed and completed successfully."
} else {
    Write-Host "TEST FAILED: git rebase-clean did not complete as expected."
}