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

# 2. Load the bash script content from external file
$bashScript = Get-Content -Raw -Path "$PSScriptRoot\git-rebase-clean"

Write-Host "Writing the bash script in UTF-8 (no BOM)..."

# 3. Write the file using .NET UTF8Encoding(false) for NO BOM
$utf8NoBOM = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($scriptPath, $bashScript, $utf8NoBOM)

Write-Host "Script saved to: $scriptPath"

# 4. Add ~/.git-tools to user's PATH if not already there
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
