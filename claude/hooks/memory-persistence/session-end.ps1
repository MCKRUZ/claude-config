# Stop Hook - Create/update daily session file + Nexus sync
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

# ── Nexus Sync ────────────────────────────────────────────────────────────────
# Removed 2026-08-05. Nexus owns its own sync: the `nexus hook post-session` Stop
# hook syncs the active project (and re-syncs when a budget alert fires), and the
# SessionStart hook syncs before work begins. A portfolio-wide `nexus sync` here
# was a third redundant write to the encrypted DB on every stop.
