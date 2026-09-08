# Secret Scanner Hook — Detect hardcoded secrets before commits
#
# PreToolUse on Bash: intercepts git commit/add commands and scans staged files
# for common secret patterns (API keys, tokens, private keys, connection strings).

. "$PSScriptRoot\..\hook-profile.ps1" -HookId "secret-scanner" -MinProfile "standard"
if ($script:HookSkipped) { exit 0 }

$input_json = $args[0]
if (-not $input_json) {
    $input_json = [Console]::In.ReadToEnd()
}

try {
    $data = $input_json | ConvertFrom-Json -ErrorAction Stop
    $command = $data.tool_input.command
} catch {
    exit 0
}

if (-not $command) { exit 0 }
if ($command -notmatch 'git\s+(commit|add)') { exit 0 }

$secretPatterns = @(
    @{ Name = "AWS Access Key";         Pattern = 'AKIA[0-9A-Z]{16}' }
    @{ Name = "AWS Secret Key";         Pattern = '(?i)aws_secret_access_key\s*[=:]\s*[A-Za-z0-9/+=]{40}' }
    @{ Name = "Anthropic API Key";      Pattern = 'sk-ant-api\d{2}-[A-Za-z0-9_-]{80,}' }
    @{ Name = "OpenAI API Key";         Pattern = 'sk-(proj|svcacct)-[a-zA-Z0-9_-]{20,}' }
    @{ Name = "Google API Key";         Pattern = 'AIza[0-9A-Za-z\-_]{35}' }
    @{ Name = "GitHub Token";           Pattern = '(ghp|gho|ghs|ghr|github_pat)_[A-Za-z0-9_]{30,}' }
    @{ Name = "Stripe Secret Key";      Pattern = 'sk_(live|test)_[A-Za-z0-9]{20,}' }
    @{ Name = "Slack Token";            Pattern = 'xox[bporsca]-[0-9a-zA-Z]{10,}' }
    @{ Name = "Discord Bot Token";      Pattern = '[MN][A-Za-z\d]{23,}\.[\w-]{6}\.[\w-]{27,}' }
    @{ Name = "Telegram Bot Token";     Pattern = '\d{8,10}:[A-Za-z0-9_-]{35}' }
    @{ Name = "Azure Key";             Pattern = '(?i)(azure|az)[_-]?(api|account)?[_-]?(key|secret|token)\s*[=:]\s*[A-Za-z0-9+/=]{20,}' }
    @{ Name = "Private Key";           Pattern = '-----BEGIN\s+(RSA|DSA|EC|OPENSSH)?\s*PRIVATE\s+KEY-----' }
    @{ Name = "Connection String";      Pattern = '(?i)(mysql|postgresql|postgres|mongodb|redis|mssql)://[^\s:]+:[^\s@]+@' }
    @{ Name = "NPM Token";             Pattern = 'npm_[A-Za-z0-9]{36}' }
    @{ Name = "PyPI Token";            Pattern = 'pypi-[A-Za-z0-9_-]{100,}' }
    @{ Name = "Twilio Key";            Pattern = '(?i)twilio.*SK[0-9a-fA-F]{32}' }
    @{ Name = "SendGrid Key";          Pattern = 'SG\.[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{43}' }
    @{ Name = "Cloudflare Token";       Pattern = '(?i)cloudflare[_-]?(api)?[_-]?(key|token)\s*[=:]\s*[A-Za-z0-9_-]{37,}' }
    @{ Name = "Generic Secret";         Pattern = '(?i)(password|passwd|secret|token|api_key|apikey)\s*[=:]\s*["\x27][^\s"'\'']{8,}["\x27]' }
    @{ Name = "JWT Token";             Pattern = 'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}' }
)

$skipExtensions = @('.lock', '.sum', '.svg', '.png', '.jpg', '.gif', '.ico', '.woff', '.woff2', '.ttf', '.eot')

$sensitiveFilePatterns = @('\.env$', '\.env\.', 'credentials\.json', '\.pem$', '\.key$', '\.p12$', '\.pfx$', 'id_rsa', 'id_ed25519')

$isCommit = $command -match 'git\s+commit'
try {
    if ($isCommit) {
        $stagedFiles = git diff --cached --name-only 2>$null
    } else {
        $stagedFiles = git diff --name-only 2>$null
    }
} catch {
    exit 0
}

if (-not $stagedFiles) { exit 0 }

$findings = @()

foreach ($file in $stagedFiles) {
    foreach ($sfp in $sensitiveFilePatterns) {
        if ($file -match $sfp) {
            $findings += "  Sensitive file staged: $file"
        }
    }
}

foreach ($file in $stagedFiles) {
    if (-not (Test-Path $file)) { continue }
    $fileExt = [System.IO.Path]::GetExtension($file).ToLower()
    if ($skipExtensions -contains $fileExt) { continue }
    if ($file -match '(\.min\.|vendor/|node_modules/|\.lock$)') { continue }

    try {
        $content = Get-Content $file -Raw -ErrorAction Stop
    } catch {
        continue
    }

    foreach ($sp in $secretPatterns) {
        if ($content -match $sp.Pattern) {
            $findings += "  $($sp.Name) found in: $file"
        }
    }
}

if ($findings.Count -gt 0) {
    $msg = "BLOCKED: Potential secrets detected in staged files!`n"
    $msg += ($findings -join "`n")
    $msg += "`n`nRemove secrets and use environment variables or a secrets manager instead."
    $msg += "`nTo skip this check (NOT recommended): set CLAUDE_DISABLED_HOOKS=secret-scanner"
    Write-Error $msg
    exit 2
}

exit 0
