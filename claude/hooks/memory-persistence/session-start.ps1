# SessionStart Hook - Inject previous context into new session
# Rewrote 2026-02-17: Previously only printed status messages.
# Now outputs actual content to stdout so Claude sees it at session start.

. "$PSScriptRoot\..\hook-profile.ps1" -HookId "session-start" -MinProfile "minimal"
if ($script:HookSkipped) { exit 0 }

$SessionsDir = "$env:USERPROFILE\.claude\sessions"
$LearnedDir = "$env:USERPROFILE\.claude\skills\learned"
$MaxLinesPerSkill = 30   # Truncate long skills to save tokens

$hasContent = $false

# --- 1. Inject learned skills ---
# These are NOT injected anywhere else - this is the only way Claude sees them.
if (Test-Path $LearnedDir) {
    $learnedFiles = Get-ChildItem -Path $LearnedDir -Filter "*.md" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending

    if ($learnedFiles.Count -gt 0) {
        Write-Output ""
        Write-Output "## [SESSION MEMORY] Learned Patterns & Skills"
        Write-Output ""

        foreach ($file in $learnedFiles) {
            try {
                $lines = Get-Content $file.FullName -ErrorAction SilentlyContinue
                if ($lines) {
                    $truncated = $lines.Count -gt $MaxLinesPerSkill
                    $preview = ($lines | Select-Object -First $MaxLinesPerSkill) -join "`n"

                    Write-Output "### $($file.BaseName)"
                    Write-Output "_Full path: $($file.FullName)_"
                    Write-Output $preview
                    if ($truncated) {
                        Write-Output ""
                        Write-Output "... [$($lines.Count - $MaxLinesPerSkill) more lines truncated - read full file for complete details]"
                    }
                    Write-Output ""
                }
            } catch {}
        }
        $hasContent = $true
    }
}

# --- 2. Inject most recent session content (if not an empty template) ---
if (Test-Path $SessionsDir) {
    $recentSessions = Get-ChildItem -Path $SessionsDir -Filter "*.tmp" -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-14) } |
        Sort-Object LastWriteTime -Descending

    if ($recentSessions.Count -gt 0) {
        # Find most recent session that has actual content (not just the empty template)
        foreach ($session in ($recentSessions | Select-Object -First 3)) {
            try {
                $content = Get-Content $session.FullName -Raw -ErrorAction SilentlyContinue
                # Strip HTML placeholder comments, headers, metadata, and structural lines;
                # if nothing substantive remains, the file is just the empty template.
                $substance = $content -replace '(?s)<!--.*?-->', ''
                $substance = ($substance -split "`n" | Where-Object {
                    $_.Trim() -and
                    $_ -notmatch '^\s*#' -and
                    $_ -notmatch '^\s*---\s*$' -and
                    $_ -notmatch '^\s*```' -and
                    $_ -notmatch '^\*\*(Date|Started|Last Updated):\*\*'
                }) -join "`n"
                $isEmpty = (-not $content) -or ($substance.Trim().Length -lt 40)

                if (-not $isEmpty) {
                    Write-Output "## [SESSION MEMORY] Last Session Notes: $($session.BaseName)"
                    $lines = $content -split "`n"
                    $preview = ($lines | Select-Object -First 60) -join "`n"
                    Write-Output $preview
                    Write-Output ""
                    break
                }
            } catch {}
        }

        # Always list available sessions for reference
        Write-Output "## [SESSION MEMORY] Available Sessions (query via mcp__agentmemory__memory_smart_search)"
        foreach ($s in ($recentSessions | Select-Object -First 7)) {
            Write-Output "- $($s.BaseName) — last active $($s.LastWriteTime.ToString('ddd yyyy-MM-dd HH:mm'))"
        }
        Write-Output ""
        $hasContent = $true
    }
}

# --- 3. Inject today's observation log (files changed this session day) ---
$Today  = Get-Date -Format "yyyy-MM-dd"
$ObsLog = Join-Path $SessionsDir "$Today-observations.log"
if (Test-Path $ObsLog) {
    try {
        $obsLines = Get-Content $ObsLog -ErrorAction SilentlyContinue
        if ($obsLines -and $obsLines.Count -gt 0) {
            # Cap to last 20 entries to avoid injecting hundreds of low-signal file paths
            $displayLines = $obsLines | Select-Object -Last 10
            $skipped = $obsLines.Count - $displayLines.Count
            Write-Output "## [SESSION MEMORY] Files Changed Today ($($obsLines.Count) operations)"
            if ($skipped -gt 0) {
                Write-Output "  ... ($skipped earlier operations omitted)"
            }
            $displayLines | ForEach-Object { Write-Output "  $_" }
            Write-Output ""
            $hasContent = $true
        }
    } catch {}
}

if (-not $hasContent) {
    Write-Output "[SessionStart] No prior context found."
}
