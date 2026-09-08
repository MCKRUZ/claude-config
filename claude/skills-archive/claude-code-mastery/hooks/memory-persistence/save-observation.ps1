# PostToolUse Hook - Capture file change observations
# Fires after Write|Edit tool calls. Reads tool info from stdin (JSON)
# and appends the file path + timestamp to the daily observation log.
# This gives future sessions a record of what was changed and when,
# without requiring Claude to take any action per-tool.

. "$PSScriptRoot\..\hook-profile.ps1" -HookId "save-observation" -MinProfile "standard"
if ($script:HookSkipped) { exit 0 }

$SessionsDir = "$env:USERPROFILE\.claude\sessions"
$Today = Get-Date -Format "yyyy-MM-dd"
$ObsLog = Join-Path $SessionsDir "$Today-observations.log"

# Ensure sessions dir exists
if (-not (Test-Path $SessionsDir)) {
    New-Item -ItemType Directory -Path $SessionsDir -Force | Out-Null
}

try {
    # Claude Code passes tool call JSON via stdin
    $stdinContent = [Console]::In.ReadToEnd()

    if ($stdinContent -and $stdinContent.Trim().Length -gt 0) {
        $toolCall = $stdinContent | ConvertFrom-Json -ErrorAction SilentlyContinue

        if ($toolCall) {
            $toolName   = $toolCall.tool_name ?? $toolCall.name ?? "Unknown"
            $toolInput  = $toolCall.tool_input ?? $toolCall.input

            # Extract file path — Write uses file_path, Edit uses file_path
            $filePath = $toolInput.file_path ?? $toolInput.path ?? ""

            if ($filePath) {
                $timestamp = Get-Date -Format "HH:mm:ss"
                $logEntry  = "[$timestamp] $toolName : $filePath"
                Add-Content -Path $ObsLog -Value $logEntry -ErrorAction SilentlyContinue
            }
        }
    }
} catch {
    # Silently fail — never disrupt Claude's workflow
}
