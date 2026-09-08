<#
.SYNOPSIS
    Toggle Ollama subagent delegation on/off in Claude Code settings.

.DESCRIPTION
    Adds or removes the Ollama delegation hook and env vars from settings.json.
    Run without arguments to toggle. Run with -On or -Off to set explicitly.

.EXAMPLE
    pwsh ~/.claude/hooks/toggle-ollama-delegate.ps1         # toggle
    pwsh ~/.claude/hooks/toggle-ollama-delegate.ps1 -On     # enable
    pwsh ~/.claude/hooks/toggle-ollama-delegate.ps1 -Off    # disable
    pwsh ~/.claude/hooks/toggle-ollama-delegate.ps1 -Status # show current state
#>
param(
    [switch]$On,
    [switch]$Off,
    [switch]$Status
)

$settingsPath = Join-Path $env:USERPROFILE ".claude" "settings.json"
$settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

# --- Detect current state ---
$hookMarker = "ollama_task_delegate.py"
$currentHooks = $settings.hooks.PreToolUse
$isEnabled = $false

if ($currentHooks) {
    foreach ($entry in $currentHooks) {
        foreach ($h in $entry.hooks) {
            if ($h.command -and $h.command -like "*$hookMarker*") {
                $isEnabled = $true
                break
            }
        }
    }
}

if ($Status) {
    $state = if ($isEnabled) { "ENABLED" } else { "DISABLED" }
    $model = $settings.env.OLLAMA_SUBAGENT_MODEL
    $types = $settings.env.OLLAMA_DELEGATE_TYPES
    Write-Host "Ollama subagent delegation: $state"
    if ($isEnabled -and $model) { Write-Host "  Model: $model" }
    if ($isEnabled -and $types) { Write-Host "  Delegate types: $types" }
    exit 0
}

# --- Determine target state ---
if ($On -and $Off) { Write-Error "Cannot use -On and -Off together."; exit 1 }
$targetEnabled = if ($On) { $true } elseif ($Off) { $false } else { -not $isEnabled }

# --- Ollama env vars ---
$ollamaEnvKeys = @(
    "OLLAMA_SUBAGENT_MODEL",
    "OLLAMA_SUBAGENT_FLAGS",
    "OLLAMA_SUBAGENT_TIMEOUT",
    "OLLAMA_DELEGATE_TYPES"
)

$ollamaEnvDefaults = @{
    "OLLAMA_SUBAGENT_MODEL"   = "qwen3-coder:480b-cloud"
    "OLLAMA_SUBAGENT_FLAGS"   = "--dangerously-skip-permissions"
    "OLLAMA_SUBAGENT_TIMEOUT" = "300"
    "OLLAMA_DELEGATE_TYPES"   = "general-purpose,Explore"
}

# --- Ollama hook entry ---
$ollamaHookEntry = @{
    matcher = "Agent"
    hooks   = @(
        @{
            type    = "command"
            command = "python3 C:/Users/kruz7/.claude/hooks/ollama_task_delegate.py"
        }
    )
}

if ($targetEnabled -and -not $isEnabled) {
    # --- ENABLE ---

    # Add env vars (preserve existing values if already set)
    foreach ($key in $ollamaEnvKeys) {
        if (-not (Get-Member -InputObject $settings.env -Name $key -MemberType NoteProperty)) {
            $settings.env | Add-Member -NotePropertyName $key -NotePropertyValue $ollamaEnvDefaults[$key]
        }
    }

    # Add hook entry
    $hooksList = [System.Collections.ArrayList]@($settings.hooks.PreToolUse)
    $hooksList.Add($ollamaHookEntry) | Out-Null
    $settings.hooks.PreToolUse = $hooksList.ToArray()

    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
    Write-Host "Ollama subagent delegation ENABLED"
    Write-Host "  Model: $($ollamaEnvDefaults['OLLAMA_SUBAGENT_MODEL'])"
    Write-Host "  Delegate types: $($ollamaEnvDefaults['OLLAMA_DELEGATE_TYPES'])"
    Write-Host "  Restart Claude Code for changes to take effect."

} elseif (-not $targetEnabled -and $isEnabled) {
    # --- DISABLE ---

    # Remove hook entry
    $filtered = @($settings.hooks.PreToolUse | Where-Object {
        $dominated = $false
        foreach ($h in $_.hooks) {
            if ($h.command -and $h.command -like "*$hookMarker*") {
                $dominated = $true
                break
            }
        }
        -not $dominated
    })
    $settings.hooks.PreToolUse = $filtered

    # Remove env vars
    foreach ($key in $ollamaEnvKeys) {
        if (Get-Member -InputObject $settings.env -Name $key -MemberType NoteProperty) {
            $settings.env.PSObject.Properties.Remove($key)
        }
    }

    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
    Write-Host "Ollama subagent delegation DISABLED"
    Write-Host "  Restart Claude Code for changes to take effect."

} else {
    $state = if ($isEnabled) { "ENABLED" } else { "DISABLED" }
    Write-Host "Ollama subagent delegation already $state. No changes made."
}
