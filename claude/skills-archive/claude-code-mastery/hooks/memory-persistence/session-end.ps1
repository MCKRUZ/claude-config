# Stop Hook - Create/update daily session file + optional Nexus sync
# Updated 2026-03-23: Added Nexus sync so notes/decisions propagate to CLAUDE.md
# Updated 2026-02-17: Improved template structure to match Claude-Mem's
# request/investigated/learned/completed/next_steps format so that when
# the PreCompact prompt hook triggers Claude to write session context,
# there is a meaningful structure to fill in.

. "$PSScriptRoot\..\hook-profile.ps1" -HookId "session-end" -MinProfile "minimal"
if ($script:HookSkipped) { exit 0 }

$SessionsDir = "$env:USERPROFILE\.claude\sessions"
$Today       = Get-Date -Format "yyyy-MM-dd"
$SessionFile = Join-Path $SessionsDir "$Today-session.tmp"

if (-not (Test-Path $SessionsDir)) {
    New-Item -ItemType Directory -Path $SessionsDir -Force | Out-Null
}

$CurrentTime = Get-Date -Format "HH:mm"

if (Test-Path $SessionFile) {
    # Update timestamp only — preserve any content Claude wrote during the session
    $content = Get-Content $SessionFile -Raw
    $content = $content -replace '\*\*Last Updated:\*\*.*', "**Last Updated:** $CurrentTime"
    Set-Content -Path $SessionFile -Value $content
    Write-Host "[SessionEnd] Updated session file: $SessionFile" -ForegroundColor Cyan 6>$null
} else {
    # Create new session file with structured template
    $template = @"
# Session: $Today
**Date:** $Today
**Started:** $CurrentTime
**Last Updated:** $CurrentTime

---

## Request
<!-- What was the user working on this session? -->


## Investigated
<!-- What files, systems, or topics were explored? -->


## Learned
<!-- Key insights, patterns, or decisions made this session -->


## Completed
<!-- What was finished? -->


## Next Steps
<!-- What should continue next session? -->


## Context to Load Next Session
``````
<!-- Key file paths or commands relevant to ongoing work -->
``````

"@
    Set-Content -Path $SessionFile -Value $template
    Write-Host "[SessionEnd] Created session file: $SessionFile" -ForegroundColor Cyan 6>$null
}

# ── Nexus Sync (optional) ──────────────────────────────────────────────────────
# Set NEXUS_CLI_PATH env var to your Nexus CLI dist/index.js to enable.
# Example: $env:NEXUS_CLI_PATH = "C:/path/to/Nexus/packages/cli/dist/index.js"
$NexusCli = $env:NEXUS_CLI_PATH
if ($NexusCli -and (Test-Path $NexusCli)) {
    try {
        & node $NexusCli sync 2>&1 | Out-Null
        Write-Host "[SessionEnd] Nexus sync complete" -ForegroundColor Green 6>$null
    } catch {
        Write-Host "[SessionEnd] Nexus sync failed: $_" -ForegroundColor Yellow 6>$null
    }
}
