# Discord Notification Hook — Post webhook on session Stop
#
# Stop event: sends a Discord message when Claude Code finishes working.
# Requires DISCORD_WEBHOOK_URL environment variable.

. "$PSScriptRoot\..\hook-profile.ps1" -HookId "discord-notify" -MinProfile "standard"
if ($script:HookSkipped) { exit 0 }

$webhookUrl = $env:DISCORD_WEBHOOK_URL
if (-not $webhookUrl) {
    exit 0
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$cwd = (Get-Location).Path
$project = Split-Path $cwd -Leaf

$payload = @{
    content = "Claude Code finished working on **$project** at $timestamp"
} | ConvertTo-Json -Compress

try {
    Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType "application/json" -TimeoutSec 5 | Out-Null
} catch {
    # Webhook failed — don't block the session
}

exit 0
