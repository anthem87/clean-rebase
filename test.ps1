# test.ps1
# Tests git-rebase-clean with -sml and no conflicts

$ErrorActionPreference = "Stop"

$BRANCH_BASE = "develop-test"
$BRANCH_FEATURE = "feature-no-conflict"
$FILE_NAME = "file.txt"
$TEST_PASSED = $false

function Safe-Git {
    param ([string]$Command)
    try {
        iex $Command | Out-Null
    } catch {}
}

# === Cleanup: remove existing local branches ===
Safe-Git "git branch -D $BRANCH_BASE"
Safe-Git "git branch -D $BRANCH_FEATURE"

# === Cleanup: remove existing remote branches ===
Safe-Git "git push origin --delete $BRANCH_BASE"
Safe-Git "git push origin --delete $BRANCH_FEATURE"

# === Checkout main branch ===
git checkout main

# === Create develop-test with unrelated file ===
git checkout -b $BRANCH_BASE
"base content" | Set-Content "base.txt"
git add "base.txt"
git commit -m "test: base commit on $BRANCH_BASE"

# === Create feature-no-conflict from develop-test ===
git checkout -b $BRANCH_FEATURE
"feature commit 1" | Set-Content $FILE_NAME
git add $FILE_NAME
git commit -m "test: feature commit 1"

"feature commit 2" | Set-Content $FILE_NAME
git commit -am "test: feature commit 2"

# === Simulate a local remote ===
Safe-Git "git remote remove origin-fake"
git remote add origin-fake .
git fetch origin-fake

# === Set fake editor for -sml message ===
$previousEditor = $env:GIT_EDITOR
$env:GIT_EDITOR = 'powershell -Command ""echo test: squash success > $args[0]""'

# === Run git-rebase-clean ===
Write-Host ""
Write-Host "Running: git rebase-clean -r $BRANCH_BASE -sml"
git checkout $BRANCH_FEATURE

try {
    git rebase-clean -r $BRANCH_BASE -sml

    $commitMessage = git log -1 --pretty=%B
    if ($commitMessage -like "*squash success*") {
        Write-Host "`nFinal commit message contains expected squash text:"
        Write-Host $commitMessage
        $TEST_PASSED = $true
    } else {
        throw "Unexpected final commit message: '$commitMessage'"
    }
} catch {
    Write-Host "`nTest failed with exception: $_"
    $TEST_PASSED = $false
}

# === Restore editor ===
$env:GIT_EDITOR = $previousEditor

# === Show recent commit log ===
Write-Host ""
Write-Host "Partial log for branch ${BRANCH_FEATURE}:"
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