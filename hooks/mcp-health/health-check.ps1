# MCP Health Check Hook — Verify MCP servers respond on session start
#
# SessionStart: pings key MCP endpoints to verify they're available.
# Warns (does not block) if a server is unreachable.

. "$PSScriptRoot\..\hook-profile.ps1" -HookId "mcp-health-check" -MinProfile "standard"
if ($script:HookSkipped) { exit 0 }

$servers = @(
    @{ Name = "Bifrost"; Url = "http://192.168.50.189:8090/mcp"; Timeout = 5 },
    @{ Name = "Nexus"; Url = "http://localhost:3579"; Timeout = 3 },
    @{ Name = "Context-Mode"; Check = "process"; ProcessName = "context-mode" }
)

$healthy = 0
$unhealthy = 0
$warnings = @()

foreach ($server in $servers) {
    if ($server.Check -eq "process") {
        $proc = Get-Process -Name $server.ProcessName -ErrorAction SilentlyContinue
        if ($proc) {
            $healthy++
        } else {
            $unhealthy++
            $warnings += "  - $($server.Name): process not running"
        }
        continue
    }

    try {
        $response = Invoke-WebRequest -Uri $server.Url -Method Head -TimeoutSec $server.Timeout -UseBasicParsing -ErrorAction Stop
        if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
            $healthy++
        } else {
            $unhealthy++
            $warnings += "  - $($server.Name): HTTP $($response.StatusCode)"
        }
    } catch {
        # Try a simple TCP connection as fallback
        try {
            $uri = [System.Uri]$server.Url
            $tcp = New-Object System.Net.Sockets.TcpClient
            $tcp.Connect($uri.Host, $uri.Port)
            $tcp.Close()
            $healthy++
        } catch {
            $unhealthy++
            $warnings += "  - $($server.Name): unreachable ($($_.Exception.Message))"
        }
    }
}

if ($unhealthy -gt 0) {
    Write-Host "[MCP Health] $healthy/$($healthy + $unhealthy) servers healthy. Issues:" -ForegroundColor Yellow
    foreach ($w in $warnings) {
        Write-Host $w -ForegroundColor Yellow
    }
} else {
    Write-Host "[MCP Health] All $healthy servers healthy" -ForegroundColor Green
}

exit 0

