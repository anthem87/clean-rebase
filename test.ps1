# test.ps1
# Testa git rebase-clean con conflitti nella repo corrente
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# === Config ===
$RepoPath = Get-Location
$BranchBase = "develop-test"
$BranchFeature = "feature-conflict"
$FileName = "file.txt"

# === Vai nella repo ===
Set-Location $RepoPath

# === Cleanup: branch locali pre-esistenti ===
git branch -D $BranchBase -f > $null 2>&1
git branch -D $BranchFeature -f > $null 2>&1

# === Cleanup: branch remoti pre-esistenti ===
git push origin --delete $BranchBase -f > $null 2>&1
git push origin --delete $BranchFeature -f > $null 2>&1

# === Checkout main ===
git checkout main

# === Crea develop-test con contenuto iniziale ===
git checkout -b $BranchBase
"riga condivisa" | Out-File -Encoding utf8 $FileName
git add $FileName
git commit -m "test: commit base su $BranchBase"

# === Modifica su develop-test (per creare conflitto) ===
"modifica da develop" | Out-File -Encoding utf8 $FileName
git commit -am "test: modifica da develop (conflittuale)"

# === Crea feature-conflict partendo dalla base ===
git checkout -b $BranchFeature HEAD~1
"modifica da feature" | Out-File -Encoding utf8 $FileName
git commit -am "test: modifica da feature (conflittuale)"

# === Simula un remote locale ===
git remote remove origin-fake -f > $null 2>&1
git remote add origin-fake .
git fetch origin-fake

# === Lancia git rebase-clean ===
Write-Host ""
Write-Host "Esecuzione: git rebase-clean su $BranchFeature (vs $BranchBase)"
git checkout $BranchFeature

$rebaseOutput = git rebase-clean -r $BranchBase -sm "test: squash con conflitto" 2>&1

# === Mostra log ===
Write-Host ""
Write-Host "Log (parziale) del branch ${BranchFeature}:"
git log --oneline --graph --decorate -n 5

# === Gestione conflitto ===
if ($rebaseOutput -match "Conflict during rebase!") {
    Write-Host ""
    Write-Host "Conflitto rilevato. Procedo automaticamente con:"
    Write-Host "  git add $FileName"
    Write-Host "  git rebase --continue"
    Write-Host "  git rebase-clean --continue"

    git add $FileName

    # Evita apertura editor (es. vim) durante rebase
    $env:GIT_EDITOR = "true"
    git rebase --continue
    git rebase-clean --continue
    Remove-Item Env:\GIT_EDITOR

    $testPassed = $true
} else {
    Write-Host ""
    Write-Host "Test completato con successo. Nessun conflitto rilevato."
    $testPassed = $true
}

# === Cleanup: branch locali ===
git checkout main
git branch -D $BranchBase > $null 2>&1
git branch -D $BranchFeature > $null 2>&1

# === Cleanup: branch remoti ===
git push origin --delete $BranchBase -f > $null 2>&1
git push origin --delete $BranchFeature -f > $null 2>&1

# === Cleanup: riferimenti remoti fittizi ===
git remote remove origin-fake > $null 2>&1
if (Test-Path ".git\refs\remotes\origin-fake") {
    Remove-Item -Recurse -Force ".git\refs\remotes\origin-fake"
}

# === Risultato finale ===
Write-Host ""
if ($testPassed) {
	Write-Host "TEST OK: git rebase-clean ha funzionato ed è stato completato."
} else {
    Write-Host "TEST FALLITO: git rebase-clean non è andato a buon fine."
}
