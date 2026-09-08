# Kills claude.exe processes whose parent terminal is gone (orphaned by closing a
# terminal window/tab without /exit) once they've been running longer than the
# threshold, plus any node.exe MCP helper processes that were children of those
# orphaned sessions. Safety net for the leak diagnosed 2026-08-24 (11 sessions from
# 3 days earlier, still holding ~1.5GB RAM). Age gate exists so a session that just
# lost its terminal a minute ago still has time to be noticed before it's killed.

param(
    [int]$ThresholdHours = 6
)

$logDir = "C:\Users\kruz7\.claude\logs"
$logFile = Join-Path $logDir "orphan-cleanup.log"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

function Write-Log {
    param([string]$Message)
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $logFile -Value $line
}

$cutoff = (Get-Date).AddHours(-$ThresholdHours)

$claudeProcs = Get-CimInstance Win32_Process -Filter "Name='claude.exe'" -ErrorAction SilentlyContinue
if (-not $claudeProcs) {
    Write-Log "No claude.exe processes found. Nothing to do."
    exit 0
}

$orphanedClaudePids = @()

foreach ($proc in $claudeProcs) {
    $createTime = $proc.CreationDate
    if (-not $createTime) { continue }
    if ($createTime -gt $cutoff) { continue }  # too young, leave it alone

    $parentAlive = $false
    if ($proc.ParentProcessId) {
        $parentAlive = [bool](Get-Process -Id $proc.ParentProcessId -ErrorAction SilentlyContinue)
    }

    if (-not $parentAlive) {
        $orphanedClaudePids += $proc.ProcessId
        Write-Log ("Orphan candidate: claude.exe PID {0}, started {1}, parent PID {2} not running" -f $proc.ProcessId, $createTime, $proc.ParentProcessId)
    }
}

if ($orphanedClaudePids.Count -eq 0) {
    Write-Log "No orphaned claude.exe processes older than $ThresholdHours hours. Nothing to do."
    exit 0
}

# Node.exe MCP helpers whose parent was one of the orphans, or whose own parent is
# already gone and who are old enough to be leftovers rather than mid-startup.
$nodeProcs = Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue
$orphanedNodePids = @()
foreach ($proc in $nodeProcs) {
    $childOfOrphan = $orphanedClaudePids -contains $proc.ParentProcessId
    $parentGoneAndOld = $false
    if (-not $childOfOrphan -and $proc.CreationDate -and $proc.CreationDate -le $cutoff) {
        $parentGoneAndOld = -not [bool](Get-Process -Id $proc.ParentProcessId -ErrorAction SilentlyContinue)
    }
    if ($childOfOrphan -or $parentGoneAndOld) {
        $orphanedNodePids += $proc.ProcessId
        Write-Log ("Orphan candidate: node.exe PID {0}, parent PID {1} (childOfOrphan={2})" -f $proc.ProcessId, $proc.ParentProcessId, $childOfOrphan)
    }
}

foreach ($p in $orphanedClaudePids) {
    try {
        Stop-Process -Id $p -Force -ErrorAction Stop
        Write-Log "Killed claude.exe PID $p"
    } catch {
        Write-Log "Failed to kill claude.exe PID $p : $($_.Exception.Message)"
    }
}

foreach ($p in $orphanedNodePids) {
    try {
        Stop-Process -Id $p -Force -ErrorAction Stop
        Write-Log "Killed node.exe PID $p"
    } catch {
        Write-Log "Failed to kill node.exe PID $p : $($_.Exception.Message)"
    }
}

Write-Log ("Cleanup pass complete: {0} claude.exe, {1} node.exe killed" -f $orphanedClaudePids.Count, $orphanedNodePids.Count)
