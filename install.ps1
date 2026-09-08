#Requires -Version 5.1
<#
.SYNOPSIS
  Installs this packaged Claude Code configuration onto the current Windows machine.

.DESCRIPTION
  Copies the portable config into ~/.claude and ~/.agents/skills, rewrites the
  original machine's username in path references, recreates the skill symlinks,
  restores the 13 MCP server registrations via `claude mcp add-json`, and
  replays the plugin marketplaces + installs via the `claude plugin` CLI.

  Never touches secrets. See SECRETS-CHECKLIST.md for what to re-add manually.
  Never deletes anything — existing files at any destination are renamed aside
  with a timestamp suffix before being replaced.

.PARAMETER SkipPlugins
  Skip marketplace/plugin restoration (useful for a fast dry run of file copy + path rewrite).

.PARAMETER SkipMcp
  Skip MCP server registration.

.PARAMETER WhatIf
  Show what would happen without writing anything.
#>
param(
    [switch]$SkipPlugins,
    [switch]$SkipMcp,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

$sourceUsername = 'kruz7'
$targetUsername = $env:USERNAME
$targetHome = $env:USERPROFILE

Write-Host "=== Claude Code config installer ===" -ForegroundColor Cyan
Write-Host "Package : $scriptRoot"
Write-Host "Target  : $targetHome  (user: $targetUsername)"
if ($WhatIf) { Write-Host "Mode    : DRY RUN (-WhatIf) — nothing will be written" -ForegroundColor Yellow }
Write-Host ""

function Backup-IfExists {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) {
        $backup = "$Path.pre-migration-$stamp"
        Write-Host "  backing up existing -> $(Split-Path -Leaf $backup)" -ForegroundColor DarkYellow
        if (-not $WhatIf) { Rename-Item -LiteralPath $Path -NewName (Split-Path -Leaf $backup) }
    }
}

function Copy-TreeMerged {
    param([string]$From, [string]$To)
    if (-not (Test-Path -LiteralPath $From)) { return }
    Get-ChildItem -LiteralPath $From -Force | ForEach-Object {
        $dest = Join-Path $To $_.Name
        Backup-IfExists -Path $dest
        Write-Host "  $($_.Name)"
        if (-not $WhatIf) {
            New-Item -ItemType Directory -Force -Path $To | Out-Null
            Copy-Item -LiteralPath $_.FullName -Destination $dest -Recurse -Force
        }
    }
}

# --- 1. Copy ~/.claude content -------------------------------------------------
Write-Host "[1/6] Installing ~/.claude content" -ForegroundColor Cyan
Copy-TreeMerged -From (Join-Path $scriptRoot 'claude') -To (Join-Path $targetHome '.claude')

# --- 2. Copy ~/.agents/skills ---------------------------------------------------
Write-Host "`n[2/6] Installing ~/.agents/skills content" -ForegroundColor Cyan
Copy-TreeMerged -From (Join-Path $scriptRoot 'agents-skills') -To (Join-Path $targetHome '.agents\skills')

# --- 3. Copy DevSecrets vault tooling (no secret values) ------------------------
Write-Host "`n[3/6] Installing DevSecrets vault tooling" -ForegroundColor Cyan
Copy-TreeMerged -From (Join-Path $scriptRoot 'devsecrets') -To (Join-Path $targetHome '.devsecrets')

# --- 4. Rewrite the old username in known files ---------------------------------
Write-Host "`n[4/6] Rewriting '$sourceUsername' -> '$targetUsername' in path references" -ForegroundColor Cyan
if ($sourceUsername -eq $targetUsername) {
    Write-Host "  usernames match — nothing to rewrite" -ForegroundColor DarkGray
} else {
    $filesToRewrite = @(
        'claude\CLAUDE.md',
        'claude\commands\refresh.md',
        'claude\context-governor\pin-baseline.ps1',
        'claude\docs\agents\issue-tracker.md',
        'claude\hooks\auto-format.sh',
        'claude\hooks\communication-style-inject.mjs',
        'claude\hooks\skill-switchboard\rules.json',
        'claude\hooks\toggle-ollama-delegate.ps1',
        'claude\mcp-servers\launch.js',
        'claude\rules\mcp-servers.md',
        'claude\rules\security.md',
        'claude\scripts\cleanup-orphaned-claude.ps1',
        'claude\scripts\SKILL_SYNC_README.md',
        'claude\scripts\sync-skill-from-repo.ps1',
        'claude\scripts\sync-skill-to-repo.ps1',
        'claude\settings.json',
        'claude\settings.local.json',
        'claude\skills\communication-style\INJECT.md',
        'claude\skills\communication-style\SKILL.md',
        'claude\skills-archive\claude-code-mastery\.claude\settings.local.json',
        '.devsecrets\devsecrets.js',
        '.devsecrets\DevSecrets.psm1',
        '.devsecrets\README.md'
    )
    foreach ($rel in $filesToRewrite) {
        $target = if ($rel.StartsWith('.devsecrets')) {
            Join-Path $targetHome $rel
        } else {
            Join-Path $targetHome $rel.Replace('claude\', '.claude\')
        }
        if (Test-Path -LiteralPath $target) {
            Write-Host "  $rel"
            if (-not $WhatIf) {
                $content = Get-Content -LiteralPath $target -Raw
                $rewritten = $content -replace [regex]::Escape($sourceUsername), $targetUsername
                if ($rewritten -ne $content) {
                    Set-Content -LiteralPath $target -Value $rewritten -NoNewline
                }
            }
        }
    }
}

# --- 5. Recreate the 3 skill symlinks -------------------------------------------
Write-Host "`n[5/6] Recreating skill symlinks (requires Developer Mode or admin)" -ForegroundColor Cyan
$symlinks = @('excalidraw-diagram-generator', 'find-skills', 'shannon')
foreach ($name in $symlinks) {
    $linkPath = Join-Path $targetHome ".claude\skills\$name"
    $targetPath = Join-Path $targetHome ".agents\skills\$name"
    Backup-IfExists -Path $linkPath
    if (-not $WhatIf) {
        try {
            New-Item -ItemType SymbolicLink -Path $linkPath -Target $targetPath -ErrorAction Stop | Out-Null
            Write-Host "  $name -> OK (symlink)"
        } catch {
            try {
                New-Item -ItemType Junction -Path $linkPath -Target $targetPath -ErrorAction Stop | Out-Null
                Write-Host "  $name -> OK (junction fallback)"
            } catch {
                Write-Host "  $name -> FAILED: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "    Enable Developer Mode (Settings > Privacy & Security > For developers) or run as admin, then re-run with -SkipPlugins -SkipMcp to retry just the symlinks." -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  $name -> would link to $targetPath"
    }
}

# --- 6. Restore MCP servers ------------------------------------------------------
# Read + rewrite entirely in memory — never writes a temp file into ~/.claude.
if (-not $SkipMcp) {
    Write-Host "`n[6/6] Restoring MCP server registrations" -ForegroundColor Cyan
    $content = Get-Content -LiteralPath (Join-Path $scriptRoot 'mcpServers.json') -Raw
    if ($sourceUsername -ne $targetUsername) {
        $content = $content -replace [regex]::Escape($sourceUsername), $targetUsername
    }
    $servers = $content | ConvertFrom-Json
    foreach ($name in $servers.PSObject.Properties.Name) {
        $json = $servers.$name | ConvertTo-Json -Depth 10 -Compress
        Write-Host "  $name"
        if (-not $WhatIf) {
            & claude mcp add-json $name $json -s user 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
        }
    }
} else {
    Write-Host "`n[6/6] Skipping MCP server restoration (-SkipMcp)" -ForegroundColor DarkGray
}

# --- 7. Restore plugin marketplaces + installs -----------------------------------
if (-not $SkipPlugins) {
    Write-Host "`n[extra] Restoring plugin marketplaces + installs" -ForegroundColor Cyan
    # Read from the source package, not the copied target file — keeps this step
    # independent of step 1 actually having run (relevant under -WhatIf, or -SkipMcp
    # combined with a partial retry).
    $settings = Get-Content -LiteralPath (Join-Path $scriptRoot 'claude\settings.json') -Raw | ConvertFrom-Json

    foreach ($mktName in $settings.extraKnownMarketplaces.PSObject.Properties.Name) {
        $src = $settings.extraKnownMarketplaces.$mktName.source
        $sourceArg = switch ($src.source) {
            'github'    { $src.repo }
            'directory' { $src.path }
            default     { $null }
        }
        if (-not $sourceArg) { continue }
        if ($mktName -eq 'wt-local') {
            Write-Host "  SKIP wt-local (Windows Terminal Canary local path — reinstall manually if that app is on this machine: $sourceArg)" -ForegroundColor Yellow
            continue
        }
        Write-Host "  marketplace: $mktName ($sourceArg)"
        if (-not $WhatIf) {
            & claude plugin marketplace add $sourceArg 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
        }
    }

    foreach ($pluginId in $settings.enabledPlugins.PSObject.Properties.Name) {
        if ($settings.enabledPlugins.$pluginId -ne $true) { continue }
        if ($pluginId -like '*@wt-local') {
            Write-Host "  SKIP $pluginId (depends on wt-local marketplace)" -ForegroundColor Yellow
            continue
        }
        Write-Host "  install: $pluginId"
        if (-not $WhatIf) {
            & claude plugin install $pluginId -y 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
        }
    }
} else {
    Write-Host "`n[extra] Skipping plugin restoration (-SkipPlugins)" -ForegroundColor DarkGray
}

# --- Done -------------------------------------------------------------------------
Write-Host "`n=== Install pass complete ===" -ForegroundColor Green
Write-Host "Next steps (see README.md for detail):"
Write-Host "  1. Run: claude login"
Write-Host "  2. Re-add secrets per SECRETS-CHECKLIST.md (values only, never files)"
Write-Host "  3. Install PREREQUISITES.md software you don't already have"
Write-Host "  4. Clone + build the Nexus project if you want its 3 hooks working"
Write-Host "  5. Download github-mcp-server.exe (see PREREQUISITES.md) for the github MCP server"
Write-Host "  6. Run .\verify.ps1 to check the install"
