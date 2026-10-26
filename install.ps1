#Requires -Version 5.1
<#
.SYNOPSIS
  Installs this packaged Claude Code configuration onto the current Windows machine.

.DESCRIPTION
  Copies the portable config into ~/.claude and ~/.agents/skills, rewrites the
  original machine's username in path references, recreates the skill links in
  links.json, restores the MCP server registrations in mcpServers.json via
  `claude mcp add-json`, and replays the plugin marketplaces + installs via the
  `claude plugin` CLI.

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
    # Every packaged text file that mentions the old username, found at install time so the
    # list can never go stale. Package folder -> installed folder:
    $folderMap = @{ 'claude' = '.claude'; 'agents-skills' = '.agents\skills'; 'devsecrets' = '.devsecrets' }
    $textExtensions = @('.md', '.json', '.ps1', '.psm1', '.mjs', '.js', '.py', '.sh', '.txt', '.yaml', '.yml', '.toml', '.html')
    foreach ($folder in $folderMap.Keys) {
        $packageFolder = Join-Path $scriptRoot $folder
        Get-ChildItem -LiteralPath $packageFolder -Recurse -File -Force |
            Where-Object { $_.Extension -in $textExtensions } |
            Where-Object { (Get-Content -LiteralPath $_.FullName -Raw) -match [regex]::Escape($sourceUsername) } |
            ForEach-Object {
                $rel = $_.FullName.Substring($packageFolder.Length).TrimStart('\')
                $target = Join-Path (Join-Path $targetHome $folderMap[$folder]) $rel
                if (-not (Test-Path -LiteralPath $target)) { return }
                Write-Host "  $folder\$rel"
                if (-not $WhatIf) {
                    $content = Get-Content -LiteralPath $target -Raw
                    $rewritten = $content -replace [regex]::Escape($sourceUsername), $targetUsername
                    Set-Content -LiteralPath $target -Value $rewritten -NoNewline
                }
            }
    }
}

# --- 5. Recreate the skill links listed in links.json ----------------------------
Write-Host "`n[5/6] Recreating skill links (symlink needs Developer Mode or admin; falls back to a junction)" -ForegroundColor Cyan
$links = (Get-Content -LiteralPath (Join-Path $scriptRoot 'links.json') -Raw | ConvertFrom-Json).links
foreach ($entry in $links) {
    $name = $entry.link
    $linkPath = Join-Path $targetHome $entry.link
    $targetPath = Join-Path $targetHome $entry.target
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

    # Marketplaces that point at a local folder on the source machine. Each one either has a
    # GitHub home to add instead, or a clone that recreates the folder, or is machine-specific.
    $directoryMarketplaces = @{
        'claude-code-playground-mods' = @{
            Clone   = 'https://github.com/anthropics/claude-code-playground.git'
            CloneTo = '.claude\mods\claude-code-playground'
            Path    = '.claude\mods\claude-code-playground\claude-code\mods'
        }
        'wt-local'                    = @{ Skip = 'Windows Terminal Canary local path — reinstall manually if that app is on this machine' }
    }
    $skippedMarketplaces = @('builtin', 'synced')  # ship with Claude Code / claude.ai, nothing to add

    foreach ($mktName in $settings.extraKnownMarketplaces.PSObject.Properties.Name) {
        $src = $settings.extraKnownMarketplaces.$mktName.source
        $sourceArg = $null
        if ($src.source -eq 'github') {
            $sourceArg = $src.repo
        } elseif ($src.source -eq 'directory') {
            $plan = $directoryMarketplaces[$mktName]
            if (-not $plan) {
                Write-Host "  SKIP $mktName (local folder with no known GitHub home: $($src.path))" -ForegroundColor Yellow
                $skippedMarketplaces += $mktName
                continue
            }
            if ($plan.Skip) {
                Write-Host "  SKIP $mktName ($($plan.Skip))" -ForegroundColor Yellow
                $skippedMarketplaces += $mktName
                continue
            }
            if ($plan.Repo) {
                $sourceArg = $plan.Repo
            } else {
                $cloneTo = Join-Path $targetHome $plan.CloneTo
                if (-not (Test-Path -LiteralPath $cloneTo)) {
                    Write-Host "  clone: $($plan.Clone) -> $cloneTo"
                    if (-not $WhatIf) { & git clone --depth 1 $plan.Clone $cloneTo 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray } }
                }
                $sourceArg = Join-Path $targetHome $plan.Path
            }
        }
        if (-not $sourceArg) { continue }
        Write-Host "  marketplace: $mktName ($sourceArg)"
        if (-not $WhatIf) {
            & claude plugin marketplace add $sourceArg 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
        }
    }

    foreach ($pluginId in $settings.enabledPlugins.PSObject.Properties.Name) {
        if ($settings.enabledPlugins.$pluginId -ne $true) { continue }
        $mkt = ($pluginId -split '@')[-1]
        if ($mkt -in $skippedMarketplaces) {
            Write-Host "  SKIP $pluginId (marketplace '$mkt' not restored)" -ForegroundColor Yellow
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
Write-Host "  4. Clone + build the Nexus and jarvis-os projects if you want their hooks working"
Write-Host "  5. Fetch the MCP server binaries/clones this package doesn't carry (github-mcp-server,"
Write-Host "     blender-agent-studio, rea) — see PREREQUISITES.md"
Write-Host "  6. Run .\verify.ps1 to check the install"
