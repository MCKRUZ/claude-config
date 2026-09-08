param(
    [Parameter(Position = 0)]
    [ValidateSet("local", "anthropic", "status")]
    [string]$Target = "status"
)

$settingsPath = "$env:USERPROFILE\.claude\settings.json"
$settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

$localBaseUrl = "http://192.168.50.189:11434"
$localModel = "qwen2.5:32b"

$currentBase = $settings.env.PSObject.Properties["ANTHROPIC_BASE_URL"]
$isLocal = $currentBase -and $currentBase.Value -eq $localBaseUrl

switch ($Target) {
    "status" {
        if ($isLocal) {
            Write-Host "Currently using: LOCAL (qwen2.5:32b on mac-mini)" -ForegroundColor Yellow
        } else {
            Write-Host "Currently using: ANTHROPIC (cloud)" -ForegroundColor Cyan
        }
    }
    "local" {
        $settings.env | Add-Member -NotePropertyName "ANTHROPIC_BASE_URL" -NotePropertyValue $localBaseUrl -Force
        $settings.env | Add-Member -NotePropertyName "ANTHROPIC_API_KEY" -NotePropertyValue "ollama" -Force
        $settings.env | Add-Member -NotePropertyName "OLLAMA_MODEL" -NotePropertyValue $localModel -Force
        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
        Write-Host ""
        Write-Host "  SWITCHED TO LOCAL (qwen2.5:32b on mac-mini)" -ForegroundColor Yellow
        Write-Host "  Exit this session and start a new one — env vars are read at startup." -ForegroundColor DarkGray
        Write-Host ""
    }
    "anthropic" {
        $props = $settings.env.PSObject.Properties
        @("ANTHROPIC_BASE_URL", "ANTHROPIC_API_KEY", "OLLAMA_MODEL") | ForEach-Object {
            if ($props[$_]) { $props.Remove($_) }
        }
        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
        Write-Host ""
        Write-Host "  SWITCHED TO ANTHROPIC (cloud)" -ForegroundColor Cyan
        Write-Host "  Exit this session and start a new one — env vars are read at startup." -ForegroundColor DarkGray
        Write-Host ""
    }
}
