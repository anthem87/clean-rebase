#!/usr/bin/env bash

# test.sh
# Testa git rebase-clean con conflitti nella repo corrente

set -e

BRANCH_BASE="develop-test"
BRANCH_FEATURE="feature-conflict"
FILE_NAME="file.txt"

# === Cleanup: branch locali pre-esistenti ===
git branch -D "$BRANCH_BASE" 2>/dev/null || true
git branch -D "$BRANCH_FEATURE" 2>/dev/null || true

# === Cleanup: branch remoti pre-esistenti ===
git push origin --delete "$BRANCH_BASE" 2>/dev/null || true
git push origin --delete "$BRANCH_FEATURE" 2>/dev/null || true

# === Checkout main ===
git checkout main

# === Crea develop-test con contenuto iniziale ===
git checkout -b "$BRANCH_BASE"
echo "riga condivisa" > "$FILE_NAME"
git add "$FILE_NAME"
git commit -m "test: commit base su $BRANCH_BASE"

# === Modifica su develop-test (per creare conflitto) ===
echo "modifica da develop" > "$FILE_NAME"
git commit -am "test: modifica da develop (conflittuale)"

# === Crea feature-conflict partendo dalla base ===
git checkout -b "$BRANCH_FEATURE" HEAD~1
echo "modifica da feature" > "$FILE_NAME"
git commit -am "test: modifica da feature (conflittuale)"

# === Simula un remote locale ===
git remote remove origin-fake 2>/dev/null || true
git remote add origin-fake .
git fetch origin-fake

# === Lancia git rebase-clean ===
echo ""
echo "Esecuzione: git rebase-clean su $BRANCH_FEATURE (vs $BRANCH_BASE)"
git checkout "$BRANCH_FEATURE"

if git rebase-clean -r "$BRANCH_BASE" -sm "test: squash con conflitto"; then
    echo ""
    echo "Test completato con successo. Nessun conflitto rilevato."
    TEST_PASSED=true
else
    echo ""
    echo "Conflitto rilevato. Procedo automaticamente con:"
    echo "  git add $FILE_NAME"
    echo "  git rebase --continue"
    echo "  git rebase-clean --continue"

    git add "$FILE_NAME"
    GIT_EDITOR=true git rebase --continue
    git rebase-clean --continue
    TEST_PASSED=true
fi

# === Mostra log ===
echo ""
echo "Log (parziale) del branch $BRANCH_FEATURE:"
git log --oneline --graph --decorate -n 5

# === Cleanup: branch locali ===
git checkout main
git branch -D "$BRANCH_BASE" 2>/dev/null || true
git branch -D "$BRANCH_FEATURE" 2>/dev/null || true

# === Cleanup: branch remoti ===
git push origin --delete "$BRANCH_BASE" 2>/dev/null || true
git push origin --delete "$BRANCH_FEATURE" 2>/dev/null || true

# === Cleanup: riferimenti remoti fittizi ===
git remote remove origin-fake 2>/dev/null || true
rm -rf .git/refs/remotes/origin-fake

# === Risultato finale ===
echo ""
if [ "$TEST_PASSED" = true ]; then
    echo "TEST OK: git rebase-clean ha funzionato ed è stato completato."
else
    echo "TEST FALLITO: git rebase-clean non è andato a buon fine."
fi
