# Kills orphaned Claude Code CLI processes (terminal closed without /exit) plus their
# node.exe MCP helper children. Restricted to the actual CLI executable path — never
# touches the Claude desktop app, which shares the process name "claude.exe" but lives
# under WindowsApps and spawns its own claude.exe-named Electron subprocesses.
#
# Orphan test requires ONE of:
#   - the parent process no longer exists at all, or
#   - the "parent" PID's own creation time is AFTER this process's (proof Windows
#     recycled that PID onto an unrelated process - a plain "is parent alive" check
#     misses this, which is exactly how 14 real orphans went undetected 2026-08-25
#     to 2026-09-11: their dead parent's PID had been reused by sihost.exe)
#   - the parent chain terminates at a non-shell process without ever reaching a
#     live shell/terminal within a few hops
# Anything ambiguous is logged and left running, never killed on a guess.
#
# Age gate (default 6h) exists so a session that just lost its terminal has time to
# be noticed before it's killed. Original safety-net script from the 2026-08-24 RAM
# leak incident; merged 2026-09-11 with stricter orphan detection after a manual
# cleanup found orphans this script's simpler "is parent alive" check had missed.

param(
    [int]$ThresholdHours = 6
)

$cliPath = "C:\Users\kruz7\.local\bin\claude.exe"
$logDir  = "C:\Users\kruz7\.claude\logs"
$logFile = Join-Path $logDir "orphan-cleanup.log"
$trustedShells = @('powershell','pwsh','cmd','bash','wsl','windowsterminal','conhost','sh','ubuntu','ubuntu2004','ubuntu2204','debian')
$maxHops = 8
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

function Write-Log {
    param([string]$Message)
    Add-Content -Path $logFile -Value ("[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message)
}

function Get-ProcCreated($proc) {
    try { [Management.ManagementDateTimeConverter]::ToDateTime($proc.CreationDate) }
    catch { $null }
}

# $true only when confident the process's terminal is genuinely gone.
function Test-IsOrphan($proc) {
    $current = $proc
    $hops = 0
    while ($hops -lt $maxHops) {
        $hops++
        $parent = Get-CimInstance Win32_Process -Filter "ProcessId=$($current.ParentProcessId)" -ErrorAction SilentlyContinue
        if (-not $parent) {
            Write-Log "PID $($proc.ProcessId): orphan - parent PID $($current.ParentProcessId) no longer exists"
            return $true
        }
        $parentCreated = Get-ProcCreated $parent
        $childCreated  = Get-ProcCreated $current
        if (-not $parentCreated -or -not $childCreated) {
            Write-Log "PID $($proc.ProcessId): ambiguous - could not read a creation timestamp, leaving it alone"
            return $false
        }
        if ($parentCreated -gt $childCreated) {
            Write-Log "PID $($proc.ProcessId): orphan - parent PID $($parent.ProcessId) ($($parent.Name)) was created AFTER this process, so Windows must have reused that PID number"
            return $true
        }
        $shortName = ($parent.Name -replace '\.exe$', '').ToLower()
        if ($trustedShells -contains $shortName) {
            return $false  # attached to a live shell/terminal
        }
        if ($parent.Name -ne 'claude.exe') {
            Write-Log "PID $($proc.ProcessId): orphan - chain terminates at '$($parent.Name)' (PID $($parent.ProcessId)) without ever reaching a shell/terminal"
            return $true
        }
        $current = $parent  # walk up a chain of claude.exe -> claude.exe
    }
    Write-Log "PID $($proc.ProcessId): ambiguous after $maxHops hops, leaving it alone"
    return $false
}

$cutoff = (Get-Date).AddHours(-$ThresholdHours)
$cliProcs = Get-CimInstance Win32_Process -Filter "Name='claude.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.ExecutablePath -eq $cliPath }

if (-not $cliProcs) {
    Write-Log "No CLI claude.exe processes found. Nothing to do."
    exit 0
}

$orphanedClaudePids = @()
foreach ($proc in $cliProcs) {
    $created = Get-ProcCreated $proc
    if (-not $created -or $created -gt $cutoff) { continue }  # too young, leave it alone
    if (Test-IsOrphan $proc) {
        $orphanedClaudePids += $proc.ProcessId
    }
}

if ($orphanedClaudePids.Count -eq 0) {
    Write-Log "No orphaned CLI sessions older than $ThresholdHours hours. Nothing to do."
    exit 0
}

# node.exe MCP helpers that were children of a confirmed-orphaned CLI session.
$nodeProcs = Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue
$orphanedNodePids = @($nodeProcs | Where-Object { $orphanedClaudePids -contains $_.ParentProcessId } | Select-Object -ExpandProperty ProcessId)

foreach ($p in $orphanedClaudePids) {
    try { Stop-Process -Id $p -Force -ErrorAction Stop; Write-Log "Killed claude.exe PID $p" }
    catch { Write-Log "Failed to kill claude.exe PID $p : $($_.Exception.Message)" }
}
foreach ($p in $orphanedNodePids) {
    try { Stop-Process -Id $p -Force -ErrorAction Stop; Write-Log "Killed node.exe (MCP helper) PID $p" }
    catch { Write-Log "Failed to kill node.exe PID $p : $($_.Exception.Message)" }
}

Write-Log ("Cleanup pass complete: {0} claude.exe, {1} node.exe killed" -f $orphanedClaudePids.Count, $orphanedNodePids.Count)
