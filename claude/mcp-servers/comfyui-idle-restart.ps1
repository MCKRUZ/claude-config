# Restarts the local ComfyUI server (Easy-Install, port 8188) if it has sat idle for over
# IdleHours with no queued or running jobs. Built 2026-09-01 after ComfyUI's own server process
# accumulated ~15GB of RAM over ~2.5 days of continuous uptime with no jobs running, which caused
# unrelated background renders on this machine to get killed under memory pressure.
#
# Safety: NEVER restarts while anything is in queue_running or queue_pending, no matter how long
# the server has been idle overall — "idle" is judged from the last completed job (or process
# start time if no job has ever run), not from uptime alone.
#
# Intended to run on a schedule (Windows Task Scheduler), not interactively.

param(
    [int]$IdleHours = 3,
    # Restart on footprint as well as idleness. Added 2026-09-02: the idle rule alone could
    # never catch the case that actually bit us, because the growth happens DURING a render
    # session and the (correct) never-restart-mid-job guard blanks it. Measured that night:
    # ComfyUI sat at 1.0 GB straight after a restart and 16.9 GB once a voice render had run,
    # with system free RAM falling from 16.9 GB to under 2 GB. /free with unload_models
    # reclaimed none of it; only a process restart did.
    # 12 GB is deliberately above a legitimately-loaded big model (~10 GB) so a working
    # server mid-session is not cycled out from under itself.
    [int]$MaxRamGB = 12,
    [string]$ComfyUrl = "http://127.0.0.1:8188",
    [string]$ComfyWorkspace = "E:\ComfyUI-Easy-Install\ComfyUI",
    [string]$LogPath = "$env:USERPROFILE\.claude\mcp-servers\comfyui-idle-restart.log"
)

function Write-Log($msg) {
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
    Add-Content -Path $LogPath -Value $line
    Write-Output $line
}

try {
    $queue = Invoke-RestMethod -Uri "$ComfyUrl/queue" -TimeoutSec 10 -ErrorAction Stop
} catch {
    Write-Log "ComfyUI not reachable at $ComfyUrl ($($_.Exception.Message)) -- nothing to do, not our job to relaunch a fully-down server unattended."
    exit 0
}

if ($queue.queue_running.Count -gt 0 -or $queue.queue_pending.Count -gt 0) {
    Write-Log "Busy (running=$($queue.queue_running.Count) pending=$($queue.queue_pending.Count)) -- skipping, never restart mid-job."
    exit 0
}

# Find the most recent job's completion time from /history. Cap max_items generously since we
# only need the newest entry, not full history.
$lastJobTime = $null
try {
    $history = Invoke-RestMethod -Uri "$ComfyUrl/history?max_items=200" -TimeoutSec 15 -ErrorAction Stop
    foreach ($entry in $history.PSObject.Properties) {
        foreach ($msg in $entry.Value.status.messages) {
            if ($msg[0] -eq "execution_success" -or $msg[0] -eq "execution_start") {
                $ts = [DateTimeOffset]::FromUnixTimeMilliseconds([int64]$msg[1].timestamp).LocalDateTime
                if (-not $lastJobTime -or $ts -gt $lastJobTime) { $lastJobTime = $ts }
            }
        }
    }
} catch {
    Write-Log "Could not read /history ($($_.Exception.Message)) -- falling back to process start time only."
}

$proc = Get-CimInstance Win32_Process -Filter "Name='python.exe'" |
    Where-Object { $_.CommandLine -match 'main\.py.*--port\s+8188' } |
    Select-Object -First 1

if (-not $proc) {
    Write-Log "No matching ComfyUI process found via CommandLine match -- server may be running outside the pattern this script expects. Skipping rather than guessing."
    exit 0
}

$procStart = $proc.CreationDate
$lastActivity = if ($lastJobTime -and $lastJobTime -gt $procStart) { $lastJobTime } else { $procStart }
$idleFor = (Get-Date) - $lastActivity
$ramGB = [math]::Round($proc.WorkingSetSize / 1GB, 2)

# Two independent reasons to cycle it, both of which still require an empty queue (checked
# above -- a job in flight is never interrupted, whatever the footprint):
#   * idle for long enough that nobody is waiting on it, or
#   * carrying more memory than a working server should, which starves everything else on
#     the box long before it fails loudly.
$idleTrip = $idleFor.TotalHours -ge $IdleHours
$ramTrip  = $ramGB -ge $MaxRamGB

if (-not $idleTrip -and -not $ramTrip) {
    Write-Log ("Idle {0:N1}h (< {1}h), {2} GB (< {3} GB) -- leaving it running." -f $idleFor.TotalHours, $IdleHours, $ramGB, $MaxRamGB)
    exit 0
}

$reason = if ($ramTrip -and $idleTrip) { "idle AND oversized" } elseif ($ramTrip) { "OVERSIZED" } else { "idle" }
Write-Log ("Restarting ({0}): idle {1:N1}h vs {2}h, RAM {3} GB vs {4} GB, queue empty -- PID {5} (started {6})." -f $reason, $idleFor.TotalHours, $IdleHours, $ramGB, $MaxRamGB, $proc.ProcessId, $procStart)

Stop-Process -Id $proc.ProcessId -Force
Start-Sleep -Seconds 3

$launchArgs = "main.py --listen 0.0.0.0 --port 8188 --disable-auto-launch --fp8_e4m3fn-unet --reserve-vram 2.0 --use-ck-attention"
Start-Process -FilePath "$ComfyWorkspace\..\python_embeded\python.exe" `
    -ArgumentList $launchArgs `
    -WorkingDirectory $ComfyWorkspace `
    -WindowStyle Hidden

Write-Log "Relaunch command issued. Not blocking to confirm health here -- next scheduled check will report if it didn't come back up (queue/history call will fail and get logged)."
