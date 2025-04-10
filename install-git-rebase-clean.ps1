# install-git-rebase-clean.ps1
# Installa git-rebase-clean (Bash) in ~/.git-tools (PowerShell compatibile anche con Windows PowerShell 5.1)

$gitToolsPath = "$HOME\.git-tools"
$scriptPath   = Join-Path $gitToolsPath "git-rebase-clean"

Write-Host "=== Installazione di git-rebase-clean ==="

# 1. Crea ~/.git-tools se non esiste
if (!(Test-Path $gitToolsPath)) {
    New-Item -ItemType Directory -Path $gitToolsPath | Out-Null
    Write-Host "Creata cartella: $gitToolsPath"
}

# 2. Contenuto dello script bash aggiornato con supporto -h/--help
$bashScript = @'
#!/usr/bin/env bash
# Script: git-rebase-clean
# Usage:
#   git rebase-clean                         -> usa origin/develop e messaggio di default
#   git rebase-clean -r my-branch            -> rebase da un branch specifico
#   git rebase-clean -sm "nuovo messaggio"   -> messaggio di commit personalizzato
#   git rebase-clean -r branch -sm "msg"     -> personalizza entrambi
#   git rebase-clean --continue              -> riprende dopo conflitti
#   git rebase-clean -h / --help             -> mostra questo help

set -e

STATE_FILE="$HOME/.git-tools/.rebase-clean-state"
baseBranch="origin/develop"
squashMsg="feat: complete work (squash)"

function print_help {
  echo ""
  echo "USO:"
  echo "  git rebase-clean                  Esegue squash e rebase da origin/develop"
  echo "  git rebase-clean -r branch        Specifica il branch da cui fare rebase"
  echo "  git rebase-clean -sm \"msg\"       Specifica il messaggio del commit squash"
  echo "  git rebase-clean -r branch -sm \"msg\""
  echo "                                    Personalizza branch e messaggio"
  echo "  git rebase-clean --continue       Riprende dopo conflitti"
  echo "  git rebase-clean -h / --help      Mostra questo help"
  echo ""
  exit 0
}

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

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --continue)
      continue_after_rebase
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
      echo "Argomento sconosciuto: $1"
      print_help
      ;;
  esac
done

# Full run
currentBranch=$(git rev-parse --abbrev-ref HEAD)
echo "Current branch: $currentBranch"

git checkout -b temp-rebase-clean
echo "Created temporary branch: temp-rebase-clean"

base=$(git merge-base "$baseBranch" HEAD)
echo "Base with $baseBranch: $base"

git reset --soft "$base"
git commit -m "$squashMsg"
echo "Single commit created with message: \"$squashMsg\""

git fetch origin
echo "Fetch from origin done."

echo "Starting rebase on $baseBranch..."
if ! git rebase "$baseBranch"; then
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

# No conflicts, continue
git checkout "$currentBranch"
git reset --hard temp-rebase-clean
echo "Branch $currentBranch updated with clean commit."

git push --force-with-lease origin "$currentBranch"
echo "Forced push executed."

git branch -D temp-rebase-clean
echo "Temporary branch removed."

rm -f "$STATE_FILE"
echo "Operation completed successfully."
'@

Write-Host "Sto scrivendo il file in UTF-8 (senza BOM)..."

# 3. Scrivi il file usando .NET UTF8Encoding(false) per NIENTE BOM
$utf8NoBOM = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($scriptPath, $bashScript, $utf8NoBOM)

Write-Host "Script salvato in: $scriptPath"

# 4. Aggiunge ~/.git-tools al PATH utente se non presente
$currentPath = [Environment]::GetEnvironmentVariable("PATH","User")
if (-not ($currentPath -split ";" | Where-Object { $_ -eq $gitToolsPath })) {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$gitToolsPath", "User")
    Write-Host "$gitToolsPath aggiunto al PATH utente."
    Write-Host "Riavvia il terminale per renderlo effettivo."
} else {
    Write-Host "$gitToolsPath è già nel PATH utente."
}

Write-Host ""
Write-Host "Installazione completata!"
Write-Host "Ora puoi eseguire: git rebase-clean"
