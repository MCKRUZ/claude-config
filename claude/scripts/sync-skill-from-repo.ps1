#!/usr/bin/env pwsh
# Sync Claude Skills from GitHub Repo to Global
# Usage: sync-skill-from-repo.ps1 -SkillName "comfyui-character-gen"

param(
    [Parameter(Mandatory=$true)]
    [string]$SkillName,

    [string]$RepoPath = "C:\Users\kruz7\OneDrive\Documents\Code Repos\MCKRUZ\ComfyUI Expert"
)

$GlobalSkillPath = "C:\Users\kruz7\.claude\skills\$SkillName"
$RepoSkillPath = "$RepoPath\skills\$SkillName"

# Check if skill exists in repo
if (-not (Test-Path $RepoSkillPath)) {
    Write-Error "❌ Skill not found in repo: $RepoSkillPath"
    exit 1
}

Write-Host "📋 Syncing skill: $SkillName" -ForegroundColor Cyan
Write-Host "   From: $RepoSkillPath" -ForegroundColor Gray
Write-Host "   To:   $GlobalSkillPath" -ForegroundColor Gray

# Backup existing global skill if present
if (Test-Path $GlobalSkillPath) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = "$GlobalSkillPath.backup-$timestamp"
    Copy-Item -Path $GlobalSkillPath -Destination $backupPath -Recurse -Force
    Write-Host "💾 Backed up existing skill to: $backupPath" -ForegroundColor Yellow
    Remove-Item -Path $GlobalSkillPath -Recurse -Force
}

# Copy skill from repo to global
Copy-Item -Path $RepoSkillPath -Destination $GlobalSkillPath -Recurse -Force
Write-Host "✅ Skill synced successfully" -ForegroundColor Green

Write-Host "`n✨ Sync complete! Skill is now available globally." -ForegroundColor Green
