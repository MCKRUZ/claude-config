param(
    [Parameter(Mandatory=$true)]
    [string]$Profile,
    [switch]$List,
    [switch]$Status
)

$profilesDir = "$PSScriptRoot"
$agentsDir = Join-Path (Split-Path $profilesDir) "agents"
$activeLink = Join-Path $agentsDir "_profile-active"

if ($List) {
    Get-ChildItem $profilesDir -Filter "*.json" | ForEach-Object {
        $config = Get-Content $_.FullName | ConvertFrom-Json
        Write-Host "$($config.name): $($config.description)"
    }
    return
}

if ($Status) {
    if (Test-Path $activeLink) {
        $current = Get-Content (Join-Path $activeLink "profile-name.txt") -ErrorAction SilentlyContinue
        Write-Host "Active profile: $current"
    } else {
        Write-Host "No profile active (base config only)"
    }
    return
}

$profileFile = Join-Path $profilesDir "$Profile.json"
if (-not (Test-Path $profileFile)) {
    Write-Error "Profile '$Profile' not found. Available: $(Get-ChildItem $profilesDir -Filter '*.json' | ForEach-Object { $_.BaseName })"
    return
}

$config = Get-Content $profileFile | ConvertFrom-Json

if (Test-Path $activeLink) {
    Remove-Item $activeLink -Recurse -Force
}

New-Item -ItemType Directory -Path $activeLink -Force | Out-Null
$Profile | Out-File (Join-Path $activeLink "profile-name.txt") -NoNewline

foreach ($agent in $config.agents.activate) {
    $source = Join-Path $agentsDir $agent
    if (Test-Path $source) {
        $destName = (Split-Path $agent -Leaf)
        Copy-Item $source (Join-Path $activeLink $destName)
        Write-Host "  Activated: $destName"
    } else {
        Write-Warning "  Not found: $agent"
    }
}

Write-Host "`nProfile '$Profile' activated with $($config.agents.activate.Count) agents."
Write-Host "To deactivate: Remove-Item '$activeLink' -Recurse"
