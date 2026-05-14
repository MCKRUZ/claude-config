# Stop Hook - Write structured session stats to .tmp file
# Rewrote 2026-02-17: Previously only printed a Write-Host message asking Claude
# to extract patterns (unreliable at session end). Now writes mechanical stats
# (message count, tool inventory) directly to the .tmp file so future sessions
# have a useful record without needing Claude's involvement.

. "$PSScriptRoot\..\hook-profile.ps1" -HookId "evaluate-session" -MinProfile "standard"
if ($script:HookSkipped) { exit 0 }

$ScriptDir            = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigFile           = Join-Path $ScriptDir "config.json"
$SessionsDir          = "$env:USERPROFILE\.claude\sessions"
$LearnedSkillsPath    = "$env:USERPROFILE\.claude\skills\learned"
$MinSessionLength     = 10

if (Test-Path $ConfigFile) {
    try {
        $config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
        if ($config.min_session_length) { $MinSessionLength = $config.min_session_length }
        if ($config.learned_skills_path) {
            $LearnedSkillsPath = $config.learned_skills_path -replace '~', $env:USERPROFILE
        }
    } catch {}
}

if (-not (Test-Path $LearnedSkillsPath)) {
    New-Item -ItemType Directory -Path $LearnedSkillsPath -Force | Out-Null
}

$transcriptPath = $env:CLAUDE_TRANSCRIPT_PATH
if (-not $transcriptPath -or -not (Test-Path $transcriptPath)) { exit 0 }

# --- Parse transcript ---
$messageCount = 0
$toolCounts   = @{}
$content      = ""

try {
    $content      = Get-Content $transcriptPath -Raw
    $messageCount = ([regex]::Matches($content, '"type":"user"')).Count

    # Count tool calls by name
    $knownTools = @("Read","Write","Edit","MultiEdit","Bash","Grep","Glob","Task","WebFetch","WebSearch","NotebookEdit")
    foreach ($tool in $knownTools) {
        # Match "name":"ToolName" patterns in the transcript JSON
        $pattern = '"name"\s*:\s*"' + [regex]::Escape($tool) + '"'
        $count   = ([regex]::Matches($content, $pattern)).Count
        if ($count -gt 0) { $toolCounts[$tool] = $count }
    }
} catch {}

# Skip very short sessions
if ($messageCount -lt $MinSessionLength) {
    Write-Host "[ContinuousLearning] Session too short ($messageCount messages), skipping stats write" -ForegroundColor Gray
    exit 0
}

# --- Write stats to today's .tmp session file ---
$Today       = Get-Date -Format "yyyy-MM-dd"
$SessionFile = Join-Path $SessionsDir "$Today-session.tmp"
$CurrentTime = Get-Date -Format "HH:mm"

$toolSummary = ($toolCounts.GetEnumerator() |
    Sort-Object Value -Descending |
    ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ", "

$statsBlock = @"

---
## Session Stats [$CurrentTime]
- Messages: $messageCount
- Tools used: $toolSummary

"@

# Append stats block to the session file
Add-Content -Path $SessionFile -Value $statsBlock -ErrorAction SilentlyContinue

Write-Host "[ContinuousLearning] Session stats written to $SessionFile ($messageCount messages, tools: $toolSummary)" -ForegroundColor Cyan

