#requires -Version 7.0
<#
.SYNOPSIS
    One-line installer — clones the config repo and runs bootstrap.

.DESCRIPTION
    Designed to be invoked via:
      irm https://raw.githubusercontent.com/MCKRUZ/claude-config/main/bootstrap/quick-install.ps1 | iex

    Clones the config mono-repo to $env:USERPROFILE/.claude-config (or the
    location you pass via -Dest), then runs bootstrap/install.ps1.
#>
[CmdletBinding()]
param(
    [string] $Dest      = (Join-Path $env:USERPROFILE '.claude-config'),
    [string] $RepoUrl   = 'https://github.com/MCKRUZ/claude-config',
    [string] $Branch    = 'main',
    [switch] $SkipSecrets,
    [switch] $Force
)

$ErrorActionPreference = 'Stop'

function Info { param($m) Write-Host "[quick-install] $m" -ForegroundColor Cyan }
function Ok   { param($m) Write-Host "[quick-install] $m" -ForegroundColor Green }
function Die  { param($m) Write-Host "[quick-install] $m" -ForegroundColor Red; exit 1 }

if ($RepoUrl -like '__REPO_URL*') {
    Die "RepoUrl placeholder was not replaced at build time. Pass -RepoUrl explicitly."
}

# 1. Ensure git is on PATH
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Die "git is not installed or not on PATH. Install Git for Windows first."
}

# 2. Ensure APM is on PATH (auto-install if absent)
if (-not (Get-Command apm -ErrorAction SilentlyContinue)) {
    Info "APM not found — installing..."
    Invoke-RestMethod https://aka.ms/apm-windows | Invoke-Expression
    if (-not (Get-Command apm -ErrorAction SilentlyContinue)) {
        Die "APM install reported success but apm is still not on PATH. Open a new shell and re-run."
    }
    Ok "APM installed"
}

# 3. Clone (or pull) the repo
if (Test-Path -LiteralPath $Dest) {
    Info "Updating existing clone at $Dest"
    Push-Location $Dest
    try { & git pull --ff-only } finally { Pop-Location }
} else {
    Info "Cloning $RepoUrl -> $Dest"
    & git clone -b $Branch $RepoUrl $Dest
    if ($LASTEXITCODE -ne 0) { Die "git clone failed (exit $LASTEXITCODE)" }
}

# 4. Run bootstrap
$bootstrap = Join-Path $Dest 'bootstrap/install.ps1'
if (-not (Test-Path -LiteralPath $bootstrap)) {
    Die "bootstrap/install.ps1 not found in cloned repo."
}

$args = @()
if ($SkipSecrets) { $args += '-SkipSecrets' }
if ($Force)       { $args += '-Force' }

Info "Running bootstrap..."
& pwsh -NoProfile -ExecutionPolicy Bypass -File $bootstrap @args
if ($LASTEXITCODE -ne 0) { Die "bootstrap failed (exit $LASTEXITCODE)" }

Ok "Done. Open Claude Code to verify."

