# Stop Hook: Kill MCP child processes spawned by this Claude Code session.
# Targets only node.exe and uv.exe descendants — avoids killing other hooks running in parallel.
# Always exits 0 so it never blocks session teardown.

. "$PSScriptRoot\hook-profile.ps1" -HookId "kill-mcp-children" -MinProfile "minimal"
if ($script:HookSkipped) { exit 0 }

try {
    $claudePid = (Get-WmiObject Win32_Process -Filter "ProcessId=$PID" -ErrorAction SilentlyContinue).ParentProcessId
    if (-not $claudePid) { exit 0 }

    function Get-DescendantPids {
        param([int]$ppid)
        $children = @(Get-WmiObject Win32_Process -Filter "ParentProcessId=$ppid" -ErrorAction SilentlyContinue)
        foreach ($child in $children) {
            $child.ProcessId
            Get-DescendantPids -ppid $child.ProcessId
        }
    }

    $descendants = @(Get-DescendantPids -ppid $claudePid)
    foreach ($id in $descendants) {
        $proc = Get-WmiObject Win32_Process -Filter "ProcessId=$id" -ErrorAction SilentlyContinue
        if ($proc -and $proc.Name -in @('node.exe', 'uv.exe')) {
            Stop-Process -Id $id -Force -ErrorAction SilentlyContinue
        }
    }
} catch {
    # Never block session teardown on hook failure
}

exit 0

