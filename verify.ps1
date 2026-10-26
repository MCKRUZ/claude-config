#Requires -Version 5.1
<#
.SYNOPSIS
  Post-install health check for the packaged Claude Code config.
  Read-only — reports problems, fixes nothing.
#>

$ErrorActionPreference = 'Continue'
$targetHome = $env:USERPROFILE
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ok = { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
$bad = { param($m) Write-Host "  [!!] $m" -ForegroundColor Red }
$warn = { param($m) Write-Host "  [??] $m" -ForegroundColor Yellow }

Write-Host "=== Verifying Claude Code config install ===" -ForegroundColor Cyan

Write-Host "`n-- Core files --"
foreach ($f in @('.claude\CLAUDE.md', '.claude\settings.json', '.claude\rules\agents.md')) {
    $p = Join-Path $targetHome $f
    if (Test-Path -LiteralPath $p) { & $ok $f } else { & $bad "$f missing" }
}

Write-Host "`n-- No leftover source-machine paths --"
$filesToCheck = Get-ChildItem -LiteralPath (Join-Path $targetHome '.claude') -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in '.json', '.md', '.ps1', '.mjs', '.js', '.py', '.sh' }
$leftover = @()
foreach ($f in $filesToCheck) {
    try {
        $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Stop
        if ($text -match 'kruz7') { $leftover += $f.FullName }
    } catch {}
}
if ($leftover.Count -eq 0) {
    & $ok "no 'kruz7' references remain under ~/.claude"
} else {
    & $bad "$($leftover.Count) file(s) still reference the source machine's username:"
    $leftover | ForEach-Object { Write-Host "       $_" -ForegroundColor Red }
}

Write-Host "`n-- Skill links --"
$links = (Get-Content -LiteralPath (Join-Path $scriptRoot 'links.json') -Raw | ConvertFrom-Json).links
foreach ($entry in $links) {
    $name = $entry.link
    $p = Join-Path $targetHome $entry.link
    $item = Get-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue
    if ($item -and ($item.LinkType -in @('SymbolicLink', 'Junction'))) {
        & $ok "$name ($($item.LinkType))"
    } elseif (Test-Path -LiteralPath $p) {
        & $warn "$name exists but is not a link — check it resolves correctly"
    } else {
        & $bad "$name missing — Developer Mode/admin may be needed, see install.ps1 output"
    }
}

Write-Host "`n-- MCP servers --"
try {
    $mcpList = & claude mcp list 2>&1
    $expected = (Get-Content -LiteralPath (Join-Path $scriptRoot 'mcpServers.json') -Raw | ConvertFrom-Json).PSObject.Properties.Name
    foreach ($name in $expected) {
        if ($mcpList -match [regex]::Escape($name)) { & $ok $name } else { & $bad "$name not registered" }
    }
} catch {
    & $bad "could not run 'claude mcp list' — is claude on PATH?"
}

Write-Host "`n-- Plugins --"
try {
    $settings = Get-Content -LiteralPath (Join-Path $targetHome '.claude\settings.json') -Raw | ConvertFrom-Json
    $installed = & claude plugin list 2>&1
    foreach ($pluginId in $settings.enabledPlugins.PSObject.Properties.Name) {
        if ($settings.enabledPlugins.$pluginId -ne $true) { continue }
        if ($installed -match [regex]::Escape(($pluginId -split '@')[0])) { & $ok $pluginId } else { & $warn "$pluginId not found in 'claude plugin list'" }
    }
} catch {
    & $bad "could not check plugins"
}

Write-Host "`n-- Vault secrets still needed (names only) --"
$devsecrets = Join-Path $targetHome '.devsecrets\DevSecrets.psm1'
if (Test-Path -LiteralPath $devsecrets) {
    Import-Module $devsecrets -Force
    $have = @()
    try { $have = Get-DevSecretNames } catch {}
    $needed = @('GITHUB_PERSONAL_ACCESS_TOKEN', 'YOUTUBE_API_KEY', 'APIFY_TOKEN', 'LANGFUSE_SECRET_KEY')
    foreach ($n in $needed) {
        if ($have -contains $n) { & $ok $n } else { & $warn "$n not set — see SECRETS-CHECKLIST.md" }
    }
} else {
    & $bad "DevSecrets vault tooling not found at $devsecrets"
}

Write-Host "`n-- External dependencies (informational, not auto-fixable) --"
$nexus = Join-Path $targetHome 'OneDrive\Documents\Code Repos\MCKRUZ\Nexus\packages\cli\dist\index.js'
if (Test-Path -LiteralPath $nexus) { & $ok "Nexus project found" } else { & $warn "Nexus project not found — 3 hooks (UserPromptSubmit, SessionStart sync, SessionEnd) will no-op" }
$jarvis = Join-Path $targetHome 'OneDrive\Documents\Code Repos\MCKRUZ\jarvis-os'
if (Test-Path -LiteralPath $jarvis) { & $ok "jarvis-os project found" } else { & $warn "jarvis-os project not found — the HUD hooks and statusline rate-limit tap will no-op" }
$externals = @(
    @{ Name = 'github-mcp-server.exe'; Path = '.claude\mcp-servers\github-mcp-server\github-mcp-server.exe' },
    @{ Name = 'blender-agent-studio';  Path = '.claude\mcp-servers\blender-agent-studio\plugins\blender-agent-studio\mcp\server.ts' }
)
foreach ($x in $externals) {
    if (Test-Path -LiteralPath (Join-Path $targetHome $x.Path)) { & $ok "$($x.Name) found" } else { & $warn "$($x.Name) not found — see PREREQUISITES.md" }
}

Write-Host "`n=== Verification complete ===" -ForegroundColor Cyan
