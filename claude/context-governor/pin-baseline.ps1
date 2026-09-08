# Pin Baseline — records the measurement environment for Context Governor Phase 0
# and detects drift in context-mode (which auto-updates and changes how much it
# suppresses context growth — a context-mode version change invalidates the
# baseline, spec §6).
#
# Baseline decision (2026-06-07): EVERYTHING stays on. The governor will run in
# the full normal environment, so the baseline is measured there too (ecological
# validity). The governor only ever REPLACES suggest-compact, and that hook is a
# passive suggestion the user ignores — the logger reconstructs its would-fire
# points (naive.would_fire), so nothing is disabled.
#
# Usage:
#   pwsh ~/.claude/context-governor/pin-baseline.ps1          # write/refresh the marker
#   pwsh ~/.claude/context-governor/pin-baseline.ps1 -Check   # report drift, do not overwrite

param([switch]$Check)

$ErrorActionPreference = "Stop"

$settingsPath = "C:/Users/kruz7/.claude/settings.json"
$govDir       = "C:/Users/kruz7/.claude/context-governor"
$markerPath   = Join-Path $govDir "data/measurement-config.json"

function Get-ContextModeVersion {
    $cacheDir = "C:/Users/kruz7/.claude/plugins/cache/context-mode/context-mode"
    if (Test-Path $cacheDir) {
        $v = Get-ChildItem $cacheDir -Directory -ErrorAction SilentlyContinue |
            Sort-Object { [version]($_.Name) } -ErrorAction SilentlyContinue |
            Select-Object -Last 1
        if ($v) { return $v.Name }
    }
    return "unknown"
}

function Get-ClaudeCodeVersion {
    try { return (claude --version 2>$null | Select-Object -First 1) } catch { return "unknown" }
}

$currentCtxMode = Get-ContextModeVersion
$disabledMatch = [regex]::Match((Get-Content $settingsPath -Raw), '"CLAUDE_DISABLED_HOOKS"\s*:\s*"([^"]*)"')
$disabledHooks = if ($disabledMatch.Success) { $disabledMatch.Groups[1].Value } else { "" }

# --- Drift check against an existing marker ---
if (Test-Path $markerPath) {
    $prev = Get-Content $markerPath -Raw | ConvertFrom-Json
    if ($prev.context_mode_version -and $prev.context_mode_version -ne $currentCtxMode) {
        Write-Host "DRIFT: context-mode $($prev.context_mode_version) -> $currentCtxMode since baseline pinned $($prev.pinned_at)." -ForegroundColor Red
        Write-Host "       The baseline is invalidated (spec §6). Annotate the gauge log and re-pin." -ForegroundColor Red
    } else {
        Write-Host "No context-mode drift (pinned $($prev.context_mode_version), current $currentCtxMode)." -ForegroundColor Green
    }
    if ($Check) { exit 0 }
}

if ($Check) {
    Write-Host "No baseline marker yet at $markerPath. Run without -Check to pin." -ForegroundColor Yellow
    exit 0
}

# --- Write / refresh the marker ---
$marker = [ordered]@{
    config               = "all-hooks-on"
    disabled_hooks       = $disabledHooks   # pre-existing baseline (e.g. ollama-delegate), unrelated to the governor
    kept_on              = @("memory-persistence", "native-compaction", "context-mode", "agentmemory", "nexus", "switchboard", "save-observation", "suggest-compact")
    governor_replaces    = @("suggest-compact")
    context_mode_version = $currentCtxMode
    claude_code_version  = Get-ClaudeCodeVersion
    pinned_at            = (Get-Date -Format "o")
    note                 = "Everything on (ecological validity). A context-mode version change invalidates the baseline — re-run -Check periodically; auto-updates are on."
}
New-Item -ItemType Directory -Path (Split-Path $markerPath) -Force | Out-Null
$marker | ConvertTo-Json -Depth 5 | Set-Content -Path $markerPath -Encoding utf8

Write-Host "Baseline pinned." -ForegroundColor Green
Write-Host "  context-mode version : $currentCtxMode"
Write-Host "  disabled hooks       : `"$disabledHooks`" (pre-existing, not governor-related)"
Write-Host "  marker               : $markerPath"
