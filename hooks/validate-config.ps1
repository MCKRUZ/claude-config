# Validate hooks configuration file
param(
    [string]$ConfigFile = "$env:USERPROFILE\.claude\hooks\hooks-full-integration.json"
)

Write-Host "Validating: $ConfigFile" -ForegroundColor Cyan
Write-Host ""

try {
    $config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
    Write-Host "[PASS] JSON syntax valid" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] JSON syntax error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Hook Summary:" -ForegroundColor Cyan
Write-Host "-" * 50

$totalHooks = 0
foreach ($hookType in $config.hooks.PSObject.Properties) {
    $hooks = @($hookType.Value)
    $count = $hooks.Count
    $totalHooks += $count

    Write-Host ""
    Write-Host "$($hookType.Name): $count hook(s)" -ForegroundColor Yellow

    foreach ($hook in $hooks) {
        $desc = if ($hook.description) { $hook.description } else { "(no description)" }
        $matcher = if ($hook.matcher) { "[$($hook.matcher)]" } else { "[all]" }
        Write-Host "  $matcher $desc" -ForegroundColor Gray

        # Validate hook structure
        if ($hook.hooks) {
            foreach ($h in $hook.hooks) {
                if (-not $h.type) {
                    Write-Host "    [WARN] Missing 'type' field" -ForegroundColor Yellow
                }
                if ($h.type -eq "command" -and -not $h.command) {
                    Write-Host "    [FAIL] Command hook missing 'command' field" -ForegroundColor Red
                }
                if ($h.type -eq "prompt" -and -not $h.prompt) {
                    Write-Host "    [FAIL] Prompt hook missing 'prompt' field" -ForegroundColor Red
                }
            }
        } else {
            Write-Host "    [WARN] Hook missing 'hooks' array" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "-" * 50
Write-Host "Total: $totalHooks hooks across $($config.hooks.PSObject.Properties.Count) hook types" -ForegroundColor Cyan
Write-Host ""
Write-Host "[PASS] Configuration validation complete" -ForegroundColor Green

