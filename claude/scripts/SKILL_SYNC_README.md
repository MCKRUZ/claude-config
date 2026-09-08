# Claude Skill Sync System

Easily sync skills between your global Claude directory and GitHub repos.

## Overview

- **Global Skills**: `C:\Users\kruz7\.claude\skills\`
- **Repo Skills**: `C:\Users\kruz7\OneDrive\Documents\Code Repos\MCKRUZ\ComfyUI Expert\skills\`

## Usage

### 1. Sync Global → Repo (After Updating a Skill)

```powershell
# Just copy
pwsh C:\Users\kruz7\.claude\scripts\sync-skill-to-repo.ps1 -SkillName "comfyui-character-gen"

# Copy AND commit to git
pwsh C:\Users\kruz7\.claude\scripts\sync-skill-to-repo.ps1 -SkillName "comfyui-character-gen" -Commit
```

### 2. Sync Repo → Global (After Pulling from GitHub)

```powershell
pwsh C:\Users\kruz7\.claude\scripts\sync-skill-from-repo.ps1 -SkillName "comfyui-character-gen"
```

### 3. Create New Skill & Sync

```powershell
# 1. Create skill in global directory
New-Item -ItemType Directory -Path "C:\Users\kruz7\.claude\skills\my-new-skill"

# 2. Add skill files (SKILL.md, references/, etc.)

# 3. Test the skill locally

# 4. Sync to repo when ready
pwsh C:\Users\kruz7\.claude\scripts\sync-skill-to-repo.ps1 -SkillName "my-new-skill" -Commit
```

## Workflow Best Practices

### Development Workflow

1. **Work in Global**: Always develop and test skills in `~/.claude/skills/`
2. **Test Thoroughly**: Test the skill with Claude before syncing
3. **Sync to Repo**: Use sync script to copy to GitHub repo
4. **Commit Changes**: Use `-Commit` flag to automatically add, commit, and push
5. **Share**: Other users can pull from GitHub and use sync-from-repo script

### Skill Update Workflow

```powershell
# Scenario: You updated comfyui-character-gen skill

# 1. Verify updates are in global location
ls C:\Users\kruz7\.claude\skills\comfyui-character-gen

# 2. Sync to repo and commit
pwsh C:\Users\kruz7\.claude\scripts\sync-skill-to-repo.ps1 -SkillName "comfyui-character-gen" -Commit

# 3. Push to remote (script will ask)
# Type 'y' when prompted
```

### Collaboration Workflow

```powershell
# Scenario: Pull updates from GitHub

# 1. Pull latest from GitHub
cd "C:\Users\kruz7\OneDrive\Documents\Code Repos\MCKRUZ\ComfyUI Expert"
git pull

# 2. Sync skills to your global directory
pwsh C:\Users\kruz7\.claude\scripts\sync-skill-from-repo.ps1 -SkillName "comfyui-character-gen"

# 3. Restart Claude Code if needed
```

## Tips

- **Always test in global first**: Global skills are immediately available to Claude
- **Backup automatically**: sync-from-repo creates timestamped backups before overwriting
- **Version control**: Git history in repo tracks all skill changes
- **Share skills**: Clone repo to share entire skill library with team

## Advanced: Sync All Skills

```powershell
# Sync all skills from global to repo
Get-ChildItem "C:\Users\kruz7\.claude\skills" -Directory | ForEach-Object {
    Write-Host "Syncing: $($_.Name)"
    pwsh C:\Users\kruz7\.claude\scripts\sync-skill-to-repo.ps1 -SkillName $_.Name
}
```

## Troubleshooting

**Skill not found error**
- Check skill name spelling (case-sensitive)
- Verify skill exists in source location

**Git commit fails**
- Ensure you're in a git repository
- Check git status manually: `cd "repo" && git status`

**Backup files accumulating**
- Remove old backups: `Remove-Item "C:\Users\kruz7\.claude\skills\*.backup-*" -Recurse`
