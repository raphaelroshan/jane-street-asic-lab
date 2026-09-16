$ErrorActionPreference = "Stop"

if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
    throw "WSL2 is required. Install it from an Administrator PowerShell with: wsl --install"
}

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$WslRepo = (& wsl.exe wslpath -a $RepoRoot).Trim()

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($WslRepo)) {
    throw "Could not translate the repository path into a WSL path."
}

if ($WslRepo.Contains("'")) {
    throw "Repository paths containing a single quote are not supported by this launcher."
}

Write-Host "Preparing Ubuntu/WSL dependencies..."
& wsl.exe bash -lc "sudo apt-get update && sudo apt-get install -y curl make python3 python3-venv && cd '$WslRepo' && ./scripts/setup.sh && make doctor && make test"

if ($LASTEXITCODE -ne 0) {
    throw "WSL setup or tests failed with exit code $LASTEXITCODE."
}

Write-Host "Setup and tests passed inside WSL2."
