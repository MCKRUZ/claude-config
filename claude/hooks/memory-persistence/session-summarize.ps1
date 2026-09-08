# SessionEnd Hook - Summarize the session transcript into today's .tmp
#
# Fires on /clear, logout, and clean exit (NOT on a killed console window —
# use `claude --resume` for that case). Closes the gap where the daily
# session .tmp stays an empty template because the PreCompact fill prompt
# only fires on compaction, never on /clear or exit.
#
# Two modes:
#   Hook mode (default): reads SessionEnd JSON from stdin, guards, then
#     detaches a hidden worker process and returns immediately so the
#     session close is never blocked.
#   Worker mode (-Worker): parses the transcript JSONL, extracts the real
#     conversation (user prompts + assistant text, no tool noise), asks
#     headless `claude -p` for a structured summary, and APPENDS it to
#     today's session .tmp (append = safe for multiple sessions per day).

param(
    [switch]$Worker,
    [string]$TranscriptPath,
    [string]$SessionId,
    [string]$Reason
)

# Recursion guard: the worker's own `claude -p` child session fires
# SessionEnd too — it must not spawn another summarizer.
if ($env:CLAUDE_SESSION_SUMMARIZER -eq '1') { exit 0 }

. "$PSScriptRoot\..\hook-profile.ps1" -HookId "session-summarize" -MinProfile "minimal"
if ($script:HookSkipped) { exit 0 }

$LogFile = "$env:USERPROFILE\.claude\sessions\summarize.log"

function Write-Log([string]$msg) {
    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "[$stamp] $msg"
}

# Count messages the user actually typed (string content; tool results
# arrive as arrays and meta/caveat lines are flagged isMeta).
function Get-RealUserMessageCount([string]$path) {
    $count = 0
    foreach ($line in [System.IO.File]::ReadLines($path)) {
        try { $j = $line | ConvertFrom-Json -ErrorAction Stop } catch { continue }
        if ($j.type -ne 'user') { continue }
        if ($j.isMeta -eq $true) { continue }
        if ($j.message.content -is [string]) { $count++ }
    }
    return $count
}

# ── Worker mode ───────────────────────────────────────────────────────────────
if ($Worker) {
    $env:CLAUDE_SESSION_SUMMARIZER = '1'
    # Native-command pipes default to the console codepage, which mangles
    # UTF-8 output from claude (em dashes become mojibake in the .tmp)
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    try {
        if (-not (Test-Path $TranscriptPath)) {
            Write-Log "WORKER abort: transcript missing: $TranscriptPath"
            exit 0
        }

        # Extract conversation text, skipping thinking/tool blocks
        $parts = [System.Collections.Generic.List[string]]::new()
        foreach ($line in [System.IO.File]::ReadLines($TranscriptPath)) {
            try { $j = $line | ConvertFrom-Json -ErrorAction Stop } catch { continue }
            if ($j.isMeta -eq $true) { continue }

            if ($j.type -eq 'user') {
                $c = $j.message.content
                $text = if ($c -is [string]) { $c }
                        else { ($c | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join "`n" }
                if ($text) {
                    if ($text.Length -gt 2000) { $text = $text.Substring(0, 2000) + " [...]" }
                    $parts.Add("USER: $text")
                }
            }
            elseif ($j.type -eq 'assistant') {
                $text = ($j.message.content | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join "`n"
                if ($text) {
                    if ($text.Length -gt 2000) { $text = $text.Substring(0, 2000) + " [...]" }
                    $parts.Add("ASSISTANT: $text")
                }
            }
        }

        $convo = $parts -join "`n`n"
        if ($convo.Length -lt 200) {
            Write-Log "WORKER skip: conversation too small ($($convo.Length) chars) session=$SessionId"
            exit 0
        }
        # Keep the opening (the Request) and the tail (latest state/next steps)
        if ($convo.Length -gt 60000) {
            $convo = $convo.Substring(0, 6000) + "`n`n[... middle of session truncated ...]`n`n" + $convo.Substring($convo.Length - 50000)
        }

        $prompt = @"
Below is the conversation from a Claude Code session that just ended (tool calls and outputs omitted). Write a session-handoff summary so the next session knows exactly where things stand.

Output ONLY GitHub-flavored markdown in EXACTLY this structure — six bolded labels, each followed by 1-4 terse bullet points (use "- None" if nothing applies). No preamble, no code fences, no extra sections.

**Request:**
**Investigated:**
**Learned:**
**Completed:**
**Next Steps:**
**Context to Load Next Session:**

For "Context to Load Next Session", list concrete file paths or commands only.
"@

        $claude = (Get-Command claude -ErrorAction SilentlyContinue).Source
        if (-not $claude) { $claude = "$env:USERPROFILE\.local\bin\claude.exe" }

        Write-Log "WORKER start: session=$SessionId reason=$Reason convo=$($convo.Length) chars"
        $summary = $convo | & $claude -p $prompt --model claude-haiku-4-5-20251001 2>$null
        if (-not $summary -or ($summary -join '').Trim().Length -lt 50) {
            Write-Log "WORKER haiku call failed/empty, retrying with default model"
            $summary = $convo | & $claude -p $prompt 2>$null
        }
        $summaryText = ($summary -join "`n").Trim()
        if ($summaryText.Length -lt 50) {
            Write-Log "WORKER abort: summarization returned nothing usable session=$SessionId"
            exit 0
        }

        # Append to today's session .tmp (created by session-end.ps1's Stop
        # hook in normal flow; create a minimal header if it's missing)
        $SessionsDir = "$env:USERPROFILE\.claude\sessions"
        $Today       = Get-Date -Format "yyyy-MM-dd"
        $SessionFile = Join-Path $SessionsDir "$Today-session.tmp"
        if (-not (Test-Path $SessionsDir)) { New-Item -ItemType Directory -Path $SessionsDir -Force | Out-Null }
        if (-not (Test-Path $SessionFile)) {
            Set-Content -Path $SessionFile -Value "# Session: $Today`n**Date:** $Today`n"
        }

        $endTime = Get-Date -Format "HH:mm"
        $block = "`n---`n`n## Session Summary — ended $endTime (reason: $Reason)`n`n$summaryText`n"
        Add-Content -Path $SessionFile -Value $block -Encoding utf8

        Write-Log "WORKER done: appended $($summaryText.Length) chars to $SessionFile session=$SessionId"
    } catch {
        Write-Log "WORKER error: $_ session=$SessionId"
    }
    exit 0
}

# ── Hook mode ─────────────────────────────────────────────────────────────────
try {
    $inputJson = [Console]::In.ReadToEnd()
    $data = $inputJson | ConvertFrom-Json -ErrorAction Stop
} catch {
    exit 0
}

$transcript = $data.transcript_path
$sessionId  = $data.session_id
$reason     = if ($data.reason) { $data.reason } else { "unknown" }

if (-not $transcript -or -not (Test-Path $transcript)) { exit 0 }

# One summary per session, even if SessionEnd somehow fires twice
$marker = Join-Path $env:TEMP "claude-summarize-$sessionId.done"
if (Test-Path $marker) { exit 0 }

# Skip trivial sessions (opened and closed without real work)
if ((Get-RealUserMessageCount $transcript) -lt 2) {
    Write-Log "HOOK skip: <2 user messages session=$sessionId reason=$reason"
    exit 0
}

New-Item -ItemType File -Path $marker -Force | Out-Null
Write-Log "HOOK dispatch: session=$sessionId reason=$reason transcript=$transcript"

Start-Process pwsh -WindowStyle Hidden -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass',
    '-File', $PSCommandPath,
    '-Worker',
    '-TranscriptPath', $transcript,
    '-SessionId', $sessionId,
    '-Reason', $reason
) | Out-Null

exit 0
