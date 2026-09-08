#!/usr/bin/env pwsh
# Sync Claude Skills to GitHub Repo
# Usage: sync-skill-to-repo.ps1 -SkillName "comfyui-character-gen" [-Commit]

param(
    [Parameter(Mandatory=$true)]
    [string]$SkillName,

    [switch]$Commit,

    [string]$RepoPath = "C:\Users\kruz7\OneDrive\Documents\Code Repos\MCKRUZ\ComfyUI Expert"
)

$GlobalSkillPath = "C:\Users\kruz7\.claude\skills\$SkillName"
$RepoSkillPath = "$RepoPath\skills\$SkillName"

# Check if skill exists globally
if (-not (Test-Path $GlobalSkillPath)) {
    Write-Error "❌ Global skill not found: $GlobalSkillPath"
    exit 1
}

# Check if repo exists
if (-not (Test-Path $RepoPath)) {
    Write-Error "❌ Repo not found: $RepoPath"
    exit 1
}

Write-Host "📋 Syncing skill: $SkillName" -ForegroundColor Cyan
Write-Host "   From: $GlobalSkillPath" -ForegroundColor Gray
Write-Host "   To:   $RepoSkillPath" -ForegroundColor Gray

# Create skills directory if it doesn't exist
$RepoSkillsDir = "$RepoPath\skills"
if (-not (Test-Path $RepoSkillsDir)) {
    New-Item -ItemType Directory -Path $RepoSkillsDir -Force | Out-Null
    Write-Host "✅ Created skills directory in repo" -ForegroundColor Green
}

# Remove existing skill in repo if present
if (Test-Path $RepoSkillPath) {
    Remove-Item -Path $RepoSkillPath -Recurse -Force
    Write-Host "🗑️  Removed old version" -ForegroundColor Yellow
}

# Copy skill to repo
Copy-Item -Path $GlobalSkillPath -Destination $RepoSkillPath -Recurse -Force
Write-Host "✅ Skill copied successfully" -ForegroundColor Green

# Git operations
if ($Commit) {
    Push-Location $RepoPath
    try {
        git add "skills/$SkillName"

        # Check if there are changes to commit
        $status = git status --porcelain "skills/$SkillName"
        if ($status) {
            $commitMsg = "Update $SkillName skill with latest changes"
            git commit -m $commitMsg
            Write-Host "✅ Changes committed: $commitMsg" -ForegroundColor Green

            # Ask about push
            $push = Read-Host "Push to remote? (y/n)"
            if ($push -eq 'y') {
                git push
                Write-Host "✅ Pushed to remote" -ForegroundColor Green
            }
        } else {
            Write-Host "ℹ️  No changes to commit" -ForegroundColor Blue
        }
    }
    finally {
        Pop-Location
    }
} else {
    Write-Host "`nℹ️  Run with -Commit flag to commit changes to git" -ForegroundColor Blue
}

Write-Host "`n✨ Sync complete!" -ForegroundColor Green
