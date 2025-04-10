#!/usr/bin/env bash

set -e

GIT_TOOLS_DIR="$HOME/.git-tools"
SCRIPT_PATH="$GIT_TOOLS_DIR/git-rebase-clean"

echo "=== Installazione di git-rebase-clean (versione Bash) ==="

# 1. Crea ~/.git-tools se non esiste
if [ ! -d "$GIT_TOOLS_DIR" ]; then
    mkdir -p "$GIT_TOOLS_DIR"
    echo "Creata cartella: $GIT_TOOLS_DIR"
else
    echo "Cartella già esistente: $GIT_TOOLS_DIR"
fi

# 2. Contenuto dello script Bash
bashScript='#!/usr/bin/env bash
# Script: git-rebase-clean
# Usage:
#   git rebase-clean            -> Esegue tutta la procedura
#   git rebase-clean --continue -> Riprende dopo un rebase interrotto
set -e

STATE_FILE="$HOME/.git-tools/.rebase-clean-state"

function continue_after_rebase {
  if [ ! -f "$STATE_FILE" ]; then
    echo "No rebase-clean state found to continue."
    exit 1
  fi

  currentBranch=$(cat "$STATE_FILE")
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

# Se --continue è passato, riprende
if [[ "$1" == "--continue" ]]; then
  continue_after_rebase
fi

# Esecuzione completa
currentBranch=$(git rev-parse --abbrev-ref HEAD)
echo "Current branch: $currentBranch"

git checkout -b temp-rebase-clean
echo "Created temporary branch: temp-rebase-clean"

base=$(git merge-base origin/develop HEAD)
echo "Base with develop: $base"

git reset --soft "$base"
git commit -m "feat: complete work (squash)"
echo "Single commit created."

git fetch origin
echo "Fetch from origin done."

echo "Starting rebase on origin/develop..."
if ! git rebase origin/develop; then
  echo ""
  echo "Conflict during rebase!"
  echo "Resolve conflicts, then:"
  echo "  git add <files>"
  echo "  git rebase --continue"
  echo "  git rebase-clean --continue"
  echo ""
  echo "Saving state to continue rebase after resolution."

  echo "$currentBranch" > "$STATE_FILE"
  exit 1
fi

# No conflicts, procedi
git checkout "$currentBranch"
git reset --hard temp-rebase-clean
echo "Branch $currentBranch updated with clean commit."

git push --force-with-lease origin "$currentBranch"
echo "Forced push executed."

git branch -D temp-rebase-clean
echo "Temporary branch removed."

rm -f "$STATE_FILE"
echo "Operation completed successfully."
'

# 3. Salva lo script in ~/.git-tools
echo "$bashScript" > "$SCRIPT_PATH"
echo "Script salvato in: $SCRIPT_PATH"

# 4. Rende eseguibile
chmod +x "$SCRIPT_PATH"
echo "Reso eseguibile."

if ! grep -Fxq 'export PATH="$HOME/.git-tools:$PATH"' "$HOME/.bashrc"; then
    echo 'export PATH="$HOME/.git-tools:$PATH"' >> "$HOME/.bashrc"
    echo "$GIT_TOOLS_DIR aggiunto al PATH in ~/.bashrc."

    # Se lo script è stato eseguito in sourcing, fai source ~/.bashrc
    if [[ "$0" == "bash" || "$0" == "-bash" ]]; then
        echo "Eseguo source ~/.bashrc per aggiornare il PATH..."
        source "$HOME/.bashrc"
    else
        echo "⚠️  Esegui 'source ~/.bashrc' o riapri il terminale per rendere effettivo."
    fi
else
    echo "$GIT_TOOLS_DIR risulta già nel PATH in ~/.bashrc."
fi

echo ""
echo "Installazione completata!"
echo "Ora puoi eseguire: git rebase-clean"
