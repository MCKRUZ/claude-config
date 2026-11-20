#Requires -Version 7.2
<#
.SYNOPSIS
  Checks and updates Claude Code, its plugins, and personal skills on this machine.

.DESCRIPTION
  Steps, in order:
    1. Claude Code CLI        `claude update`
    2. Plugin marketplaces    `claude plugin marketplace update` (catalog refresh only)
    3. Plugins                compares installed vs latest, applies safe bumps with `claude plugin update`
    4. skills CLI skills      `npx skills check` / `update -g` for ~/.agents/skills
    5. Git-cloned skills      fast-forward pulls for clean clones in ~/.claude/skills
    6. GitHub MCP server      report only (the binary never self-updates)

  Plugin policy:
    - Patch and minor bumps apply automatically.
    - Major bumps, and minor bumps below 1.0 (0.x semver treats those as breaking), are
      HELD and listed. Apply them with -AllowMajor, or name plugins with -Plugin.
    - Sha-pinned catalog entries are current when the installed commit matches the pin.
    - A catalog whose marketplace.json and plugin.json disagree is reported as drift, not updated.
    - Plugins managed elsewhere (synced from claude.ai, skills-dir, project-scoped) are reported only.

  Git skills are never pulled when they have local changes, and skills that link into
  your own working repos are reported only.

  Run it in an interactive terminal: some plugin updates show a marketplace-declared
  command that must be confirmed, and the CLI refuses those without a TTY.

.PARAMETER AllowMajor
  Also apply held major / 0.x-minor plugin bumps.

.PARAMETER Plugin
  Only update these plugin ids (name@marketplace). Naming a plugin opts it in even if held.

.PARAMETER SkipCli
  Skip `claude update`.

.PARAMETER SkipPlugins
  Skip marketplace refresh and plugin updates.

.PARAMETER SkipSkillsCli
  Skip the `npx skills` step (it runs npx even under -WhatIf, because `check` is read-only).

.PARAMETER SkipGitSkills
  Skip git-cloned skills.

.EXAMPLE
  .\update.ps1 -WhatIf          # report everything, change nothing
.EXAMPLE
  .\update.ps1                  # apply safe updates, list held ones
.EXAMPLE
  .\update.ps1 -Plugin context-mode@context-mode,claude-hud@claude-hud
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$AllowMajor,
    [string[]]$Plugin,
    [switch]$SkipCli,
    [switch]$SkipPlugins,
    [switch]$SkipSkillsCli,
    [switch]$SkipGitSkills
)

$ErrorActionPreference = 'Stop'
$claudeHome = Join-Path $env:USERPROFILE '.claude'
$pluginsHome = Join-Path $claudeHome 'plugins'
$agentsSkills = Join-Path $env:USERPROFILE '.agents\skills'
$held = [System.Collections.Generic.List[string]]::new()

function Write-Step([string]$title) { Write-Host "`n=== $title ===" -ForegroundColor Cyan }

function ConvertTo-SemVer([string]$text) {
    $parsed = $null
    if ($text -and [System.Management.Automation.SemanticVersion]::TryParse($text.TrimStart('v'), [ref]$parsed)) { return $parsed }
    return $null
}

function Get-BumpKind([string]$installed, [string]$latest) {
    $from = ConvertTo-SemVer $installed
    $to = ConvertTo-SemVer $latest
    if (-not $from -or -not $to) { return 'unknown' }
    if ($to -eq $from) { return 'current' }
    if ($to -lt $from) { return 'older' }
    if ($to.Major -ne $from.Major) { return 'major' }
    if ($from.Major -eq 0 -and $to.Minor -ne $from.Minor) { return 'major' }
    return 'minor'
}

# --- Step 1 -----------------------------------------------------------------

function Update-ClaudeCli {
    Write-Step 'Claude Code CLI'
    Write-Host "Installed: $(& claude --version)"
    if ($PSCmdlet.ShouldProcess('Claude Code', 'claude update')) { & claude update }
}

# --- Steps 2-3: plugins -----------------------------------------------------

function Get-RemotePluginVersion($source) {
    $repo = $null
    if ($source.source -eq 'github') { $repo = $source.repo }
    elseif ($source.url -match 'github\.com[/:]([^/]+/[^/.]+)') { $repo = $Matches[1] }
    if (-not $repo) { return $null }
    $sub = if ($source.path) { "$($source.path)/" } else { '' }
    try {
        $json = Invoke-RestMethod "https://raw.githubusercontent.com/$repo/HEAD/$sub.claude-plugin/plugin.json" -TimeoutSec 15
        return $json.version
    } catch { return $null }
}

function Get-CatalogEntry([string]$name, [string]$marketplace) {
    $root = Join-Path $pluginsHome "marketplaces\$marketplace"
    $catalogPath = Join-Path $root '.claude-plugin\marketplace.json'
    if (-not (Test-Path $catalogPath)) { return $null }
    # -AsHashtable: some third-party catalogs carry keys that differ only by case.
    $entry = (Get-Content $catalogPath -Raw | ConvertFrom-Json -AsHashtable).plugins | Where-Object { $_.name -eq $name }
    if (-not $entry) { return $null }
    $manifestVersion = $null
    if ($entry.source -is [string]) {
        $manifest = Join-Path $root (Join-Path $entry.source '.claude-plugin\plugin.json')
        if (Test-Path $manifest) { $manifestVersion = (Get-Content $manifest -Raw | ConvertFrom-Json).version }
    }
    [pscustomobject]@{ Entry = $entry; ManifestVersion = $manifestVersion }
}

function Resolve-PluginStatus($p, [hashtable]$shas) {
    $name, $marketplace = $p.id -split '@', 2
    $result = { param($status, $latest) [pscustomobject]@{ Id = $p.id; Installed = $p.version; Latest = $latest; Status = $status; Scope = $p.scope } }
    if ($marketplace -in 'synced', 'skills-dir') { return & $result 'managed elsewhere' '' }
    if ($p.readFromFolder) {
        if (-not $p.folderVersion) { return & $result 'no version in source folder' '' }
        return & $result (Get-BumpKind $p.version $p.folderVersion) $p.folderVersion
    }
    $catalog = Get-CatalogEntry $name $marketplace
    if (-not $catalog) { return & $result 'not in catalog' '' }
    $source = $catalog.Entry.source
    if ($source -isnot [string] -and $source.sha) {
        $installedSha = $shas[$p.id]
        if ($installedSha -and $source.sha.StartsWith($installedSha)) { return & $result 'current (pinned)' $p.version }
        return & $result 'unknown' "pin $($source.sha.Substring(0, 8))"
    }
    $catalogVersion = $catalog.Entry.version
    if ($catalogVersion -and $catalog.ManifestVersion -and $catalogVersion -ne $catalog.ManifestVersion) {
        return & $result 'catalog drift' "marketplace.json $catalogVersion / plugin.json $($catalog.ManifestVersion)"
    }
    $latest = $catalog.ManifestVersion ?? $catalogVersion
    if (-not $latest -and $source -isnot [string]) { $latest = Get-RemotePluginVersion $source }
    return & $result (Get-BumpKind $p.version $latest) $latest
}

function Get-PluginReport {
    $installed = (& claude plugin list --json | ConvertFrom-Json)
    $shas = @{}
    $registry = Get-Content (Join-Path $pluginsHome 'installed_plugins.json') -Raw | ConvertFrom-Json -AsHashtable
    foreach ($id in $registry.plugins.Keys) {
        $sha = @($registry.plugins[$id])[0].gitCommitSha
        if ($sha) { $shas[$id] = $sha }
    }
    foreach ($p in $installed) { Resolve-PluginStatus $p $shas }
}

function Test-ShouldApply($row) {
    if ($Plugin) { return $row.Id -in $Plugin -and $row.Status -in 'minor', 'major', 'unknown' }
    if ($row.Scope -ne 'user') { return $false }
    if ($row.Status -eq 'minor') { return $true }
    return $AllowMajor -and $row.Status -in 'major', 'unknown'
}

function Update-Plugins {
    Write-Step 'Plugin marketplaces'
    if ($PSCmdlet.ShouldProcess('all marketplaces', 'refresh catalog')) { & claude plugin marketplace update }
    Write-Step 'Plugins'
    $report = @(Get-PluginReport | Sort-Object Status, Id)
    $report | Format-Table Id, Installed, Latest, Status, Scope -AutoSize | Out-Host
    foreach ($row in $report) {
        if (Test-ShouldApply $row) {
            if ($PSCmdlet.ShouldProcess($row.Id, "update $($row.Installed) -> $($row.Latest)")) {
                & claude plugin update $row.Id --scope $row.Scope
                if ($LASTEXITCODE -ne 0) { Write-Warning "Update failed for $($row.Id) (exit $LASTEXITCODE)" }
            }
        } elseif ($row.Status -in 'major', 'unknown') {
            $held.Add("$($row.Id)  $($row.Installed) -> $($row.Latest)  [$($row.Status); read its changelog, then rerun with -Plugin $($row.Id)]")
        } elseif ($row.Status -eq 'catalog drift') {
            $held.Add("$($row.Id)  catalog drift: $($row.Latest). Fix the plugin's own repo so both files agree (``claude plugin tag`` checks this).")
        } elseif ($row.Status -eq 'minor' -and $row.Scope -ne 'user') {
            $held.Add("$($row.Id)  $($row.Installed) -> $($row.Latest)  [$($row.Scope)-scoped; run 'claude plugin update $($row.Id) --scope $($row.Scope)' from that project]")
        }
    }
}

# --- Step 4: skills CLI -----------------------------------------------------

function Update-SkillsCli {
    Write-Step 'skills CLI (~/.agents/skills)'
    if (-not (Test-Path (Join-Path $env:USERPROFILE '.agents\.skill-lock.json'))) { Write-Host 'No skills CLI lock file; skipping.'; return }
    & npx --yes skills@1 check
    if ($LASTEXITCODE -eq 0) { Write-Host 'All skills CLI skills are current.'; return }
    if ($PSCmdlet.ShouldProcess('global skills CLI skills', 'npx skills update -g')) { & npx --yes skills@1 update -g }
}

# --- Step 5: git-cloned skills ----------------------------------------------

function Get-GitState([string]$repo) {
    & git -C $repo fetch --quiet 2>$null
    $behind = (& git -C $repo rev-list --count 'HEAD..@{u}' 2>$null) ?? '?'
    $dirty = @(& git -C $repo status --porcelain 2>$null).Count
    [pscustomobject]@{ Behind = $behind; Dirty = $dirty }
}

function Update-GitSkills {
    Write-Step 'Git-cloned skills (~/.claude/skills)'
    $linkedRepos = @{}
    foreach ($dir in Get-ChildItem (Join-Path $claudeHome 'skills') -Directory) {
        if ($dir.LinkType) {
            if ($dir.Target -like "$agentsSkills*") { continue }   # owned by the skills CLI
            $top = & git -C $dir.FullName rev-parse --show-toplevel 2>$null
            if ($top) { $linkedRepos[$top] = $true }
            continue
        }
        if (-not (Test-Path (Join-Path $dir.FullName '.git'))) { continue }
        $state = Get-GitState $dir.FullName
        if ($state.Behind -in '0', '?') { Write-Host "$($dir.Name): current"; continue }
        if ($state.Dirty -gt 0) {
            $held.Add("skill $($dir.Name): $($state.Behind) commits behind but has $($state.Dirty) local changes; not pulled")
            continue
        }
        if ($PSCmdlet.ShouldProcess($dir.Name, "git pull --ff-only ($($state.Behind) commits)")) { & git -C $dir.FullName pull --ff-only --quiet }
    }
    foreach ($repo in $linkedRepos.Keys) {
        $state = Get-GitState $repo
        if ($state.Behind -notin '0', '?') { $held.Add("linked repo ${repo}: $($state.Behind) commits behind; your working repo, so pull it yourself") }
    }
}

# --- Step 6: GitHub MCP server ----------------------------------------------

function Show-GitHubMcpServer {
    Write-Step 'GitHub MCP server (report only)'
    $exe = Join-Path $claudeHome 'mcp-servers\github-mcp-server\github-mcp-server.exe'
    if (-not (Test-Path $exe) -or -not (Get-Command gh -ErrorAction SilentlyContinue)) { Write-Host 'Not installed or gh missing; skipping.'; return }
    $installed = (& $exe --version | Select-String '^Version:\s*(\S+)').Matches[0].Groups[1].Value
    $latest = & gh release view -R github/github-mcp-server --json tagName -q .tagName
    $kind = Get-BumpKind $installed $latest
    Write-Host "Installed $installed, latest $latest ($kind)"
    if ($kind -notin 'current', 'older', 'unknown') {
        $held.Add("github-mcp-server $installed -> ${latest}: download github-mcp-server_Windows_x86_64.zip from the release and replace $exe")
    }
}

# --- Main -------------------------------------------------------------------

if (-not $SkipCli) { Update-ClaudeCli }
if (-not $SkipPlugins) { Update-Plugins }
if (-not $SkipSkillsCli) { Update-SkillsCli }
if (-not $SkipGitSkills) { Update-GitSkills }
Show-GitHubMcpServer

Write-Step 'Needs your decision'
if ($held.Count -eq 0) { Write-Host 'Nothing held.' } else { $held | ForEach-Object { Write-Host "- $_" -ForegroundColor Yellow } }
if (-not $SkipPlugins -and -not $WhatIfPreference) { Write-Host "`nRestart Claude Code to load updated plugins." -ForegroundColor Green }
