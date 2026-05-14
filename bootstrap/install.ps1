#requires -Version 7.0
<#
.SYNOPSIS
    Bootstrap script — restore a claude-pack mono-repo onto this machine.

.DESCRIPTION
    Runs INSIDE the produced mono-repo. Verifies APM, prompts for secrets,
    rewrites paths for the current user, copies hooks + settings, then runs
    `apm install` at user scope and again for each project listed in projects/.

.PARAMETER ClaudeHome
    Override target ~/.claude location. Defaults to $env:USERPROFILE/.claude.

.PARAMETER SkipSecrets
    Skip the secrets prompt. Use when secrets are already configured on the box
    (e.g. via Windows Credential Manager or pre-set env vars).

.PARAMETER Force
    Overwrite an existing settings.json without prompting.
#>
[CmdletBinding()]
param(
    [string] $ClaudeHome  = (Join-Path $env:USERPROFILE '.claude'),
    [switch] $SkipSecrets,
    [switch] $Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RepoRoot = Split-Path -Parent $PSScriptRoot
function Info { param($m) Write-Host "[bootstrap] $m" -ForegroundColor Cyan }
function Ok   { param($m) Write-Host "[bootstrap] $m" -ForegroundColor Green }
function Warn { param($m) Write-Host "[bootstrap] $m" -ForegroundColor Yellow }
function Die  { param($m) Write-Host "[bootstrap] $m" -ForegroundColor Red; exit 1 }

# ---------- 1. verify APM ----------
Info "Checking for APM..."
$apm = Get-Command apm -ErrorAction SilentlyContinue
if (-not $apm) {
    Warn "APM not found. Install with:"
    Warn "  irm https://aka.ms/apm-windows | iex"
    Die  "Re-run this script after APM is on PATH."
}
Ok "APM found: $($apm.Source)"

# ---------- 2. secrets ----------
$secretsEnv = @{}
if (-not $SkipSecrets) {
    $secretsFile = Join-Path $RepoRoot 'settings\secrets.example.env'
    if (Test-Path -LiteralPath $secretsFile) {
        Info "Reading required secrets from $secretsFile"
        $names = Get-Content -LiteralPath $secretsFile `
            | Where-Object { $_ -and ($_ -notmatch '^\s*#') } `
            | ForEach-Object { ($_ -split '=', 2)[0].Trim() } `
            | Where-Object { $_ }

        foreach ($n in $names) {
            $existing = [System.Environment]::GetEnvironmentVariable($n, 'User')
            if ($existing -and -not $Force) {
                Info "  ${n}: already set (User scope) — keeping existing value"
                $secretsEnv[$n] = $existing
                continue
            }
            $secure = Read-Host -AsSecureString -Prompt "Enter value for $n"
            $plain  = [System.Net.NetworkCredential]::new('', $secure).Password
            if ($plain) {
                [System.Environment]::SetEnvironmentVariable($n, $plain, 'User')
                $secretsEnv[$n] = $plain
                Ok "  ${n}: stored in User env"
            } else {
                Warn "  ${n}: empty — skipped"
            }
        }
    }
} else {
    Info "Skipping secrets prompt (-SkipSecrets)"
}

# ---------- 3. render settings.json ----------
$settingsTemplate = Join-Path $RepoRoot 'settings\settings.template.json'
if (Test-Path -LiteralPath $settingsTemplate) {
    if (-not (Test-Path -LiteralPath $ClaudeHome)) {
        New-Item -ItemType Directory -Path $ClaudeHome -Force | Out-Null
    }
    $settingsTarget = Join-Path $ClaudeHome 'settings.json'

    if ((Test-Path -LiteralPath $settingsTarget) -and -not $Force) {
        $backup = "$settingsTarget.bak-$(Get-Date -Format yyyyMMddHHmmss)"
        Copy-Item -LiteralPath $settingsTarget -Destination $backup
        Warn "Existing settings.json backed up to $backup"
    }

    $text = Get-Content -LiteralPath $settingsTemplate -Raw

    # Resolve placeholders
    $text = $text -replace '\$\{CLAUDE_USER_HOME\}', ($ClaudeHome -replace '\\','/')
    $text = $text -replace '\$\{USER_HOME\}',       ($env:USERPROFILE -replace '\\','/')
    foreach ($k in $secretsEnv.Keys) {
        $needle = '${' + $k + '}'
        $text   = $text.Replace($needle, $secretsEnv[$k])
    }

    Set-Content -LiteralPath $settingsTarget -Value $text -Encoding UTF8
    Ok "Wrote $settingsTarget"
}

# ---------- 4. copy rules + hooks ----------
foreach ($subdir in @('rules', 'hooks')) {
    $src = Join-Path $RepoRoot $subdir
    if (-not (Test-Path -LiteralPath $src)) { continue }
    $dst = Join-Path $ClaudeHome $subdir
    if (-not (Test-Path -LiteralPath $dst)) {
        New-Item -ItemType Directory -Path $dst -Force | Out-Null
    }
    Get-ChildItem -LiteralPath $src -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($src.Length).TrimStart('\','/')
        $targetFile = Join-Path $dst $rel
        $targetDir  = Split-Path -Parent $targetFile
        if (-not (Test-Path -LiteralPath $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        # Hook/rule files may reference ${CLAUDE_USER_HOME} — resolve them.
        $content = Get-Content -LiteralPath $_.FullName -Raw
        $content = $content -replace '\$\{CLAUDE_USER_HOME\}', ($ClaudeHome -replace '\\','/')
        $content = $content -replace '\$\{USER_HOME\}',       ($env:USERPROFILE -replace '\\','/')
        Set-Content -LiteralPath $targetFile -Value $content -Encoding UTF8
    }
    Ok "Restored $subdir -> $dst"
}

# ---------- 5. apm install (user scope) ----------
Info "Running apm install at user scope..."
$env:CLAUDE_CONFIG_DIR = $ClaudeHome
Push-Location $RepoRoot
try {
    & apm install --target claude
    if ($LASTEXITCODE -ne 0) { Die "apm install failed (exit $LASTEXITCODE)" }
} finally {
    Pop-Location
}
Ok "apm install (user scope) complete"

# ---------- 6. per-project apm install ----------
$projectsDir = Join-Path $RepoRoot 'projects'
if (Test-Path -LiteralPath $projectsDir) {
    $projectsIndex = Join-Path $projectsDir 'index.json'
    if (Test-Path -LiteralPath $projectsIndex) {
        $idx = Get-Content -LiteralPath $projectsIndex -Raw | ConvertFrom-Json
        foreach ($p in $idx) {
            if (-not (Test-Path -LiteralPath $p.path)) {
                Warn "Project target not found locally, skipping: $($p.path)"
                continue
            }
            Info "Installing project deps at $($p.path)..."
            # Copy the apm.yml into the project so `apm install` finds it
            $projApmYml = Join-Path $projectsDir "$($p.name)/apm.yml"
            if (Test-Path -LiteralPath $projApmYml) {
                Copy-Item -LiteralPath $projApmYml -Destination (Join-Path $p.path 'apm.yml') -Force
            }
            Push-Location $p.path
            try {
                & apm install --target claude
                if ($LASTEXITCODE -ne 0) { Warn "apm install failed for $($p.path)" }
            } finally {
                Pop-Location
            }
        }
    }
}

# ---------- 7. audit ----------
Info "Running apm audit..."
Push-Location $RepoRoot
try { & apm audit } finally { Pop-Location }

Ok "Bootstrap complete. Open Claude Code to verify."
