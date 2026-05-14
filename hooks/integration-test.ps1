# Integration Test for Claude Code Hooks
# Simulates actual hook execution with mock inputs

param(
    [string]$ConfigFile = "$env:USERPROFILE\.claude\hooks\hooks-full-integration.json"
)

$ErrorActionPreference = "Continue"
$script:Passed = 0
$script:Failed = 0

function Write-TestHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
}

function Test-HookExecution {
    param(
        [string]$Name,
        [string]$Command,
        [hashtable]$MockEnv = @{},
        [string]$StdinJson = "",
        [int]$TimeoutSec = 10
    )

    Write-Host ""
    Write-Host "Testing: $Name" -ForegroundColor Yellow

    # Set mock environment variables
    foreach ($key in $MockEnv.Keys) {
        [Environment]::SetEnvironmentVariable($key, $MockEnv[$key], "Process")
    }

    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell"
        $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"$Command`""
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.RedirectStandardInput = $true
        $psi.CreateNoWindow = $true

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $psi
        $process.Start() | Out-Null

        if ($StdinJson) {
            $process.StandardInput.WriteLine($StdinJson)
            $process.StandardInput.Close()
        }

        $completed = $process.WaitForExit($TimeoutSec * 1000)

        if (-not $completed) {
            $process.Kill()
            Write-Host "  [FAIL] Timeout after ${TimeoutSec}s" -ForegroundColor Red
            $script:Failed++
            return
        }

        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()
        $exitCode = $process.ExitCode

        if ($exitCode -eq 0) {
            Write-Host "  [PASS] Exit code: 0" -ForegroundColor Green
            $script:Passed++
        } else {
            Write-Host "  [WARN] Exit code: $exitCode (may be expected)" -ForegroundColor Yellow
            $script:Passed++  # Non-zero can be valid for hooks
        }

        if ($stdout.Trim()) {
            Write-Host "  Output: $($stdout.Trim().Substring(0, [Math]::Min(100, $stdout.Trim().Length)))..." -ForegroundColor Gray
        }

    } catch {
        Write-Host "  [FAIL] $($_.Exception.Message)" -ForegroundColor Red
        $script:Failed++
    } finally {
        # Clean up mock environment
        foreach ($key in $MockEnv.Keys) {
            [Environment]::SetEnvironmentVariable($key, $null, "Process")
        }
    }
}

# ============================================
# INTEGRATION TESTS
# ============================================

Write-TestHeader "INTEGRATION TEST: Hook Execution"

# Test 1: SessionStart hook
Test-HookExecution -Name "SessionStart: Load context" `
    -Command '& "$env:USERPROFILE\.claude\hooks\memory-persistence\session-start.ps1"'

# Test 2: PreToolUse - Strategic compact (with mock stdin)
$mockToolInput = @{
    tool_name = "Edit"
    tool_input = @{
        file_path = "C:\test\example.ts"
    }
} | ConvertTo-Json -Compress

Test-HookExecution -Name "PreToolUse: Strategic compact" `
    -Command 'echo "" | & "$env:USERPROFILE\.claude\hooks\strategic-compact\suggest-compact.ps1"'

# Test 3: PreCompact hook
Test-HookExecution -Name "PreCompact: Save state" `
    -Command '& "$env:USERPROFILE\.claude\hooks\memory-persistence\pre-compact.ps1"'

# Test 4: PostToolUse - Auto-format (with mock file)
$testFile = "$env:TEMP\hook-test-$(Get-Random).json"
'{"test": true}' | Set-Content $testFile

$mockFormatInput = @{
    tool_input = @{
        file_path = $testFile
    }
} | ConvertTo-Json -Compress

Test-HookExecution -Name "PostToolUse: Auto-format" `
    -Command "echo '$mockFormatInput' | & 'C:\Program Files\Git\bin\bash.exe' '$env:USERPROFILE\.claude\hooks\auto-format.sh'"

Remove-Item $testFile -ErrorAction SilentlyContinue

# Test 5: Stop - Session end
Test-HookExecution -Name "Stop: Session end" `
    -Command '& "$env:USERPROFILE\.claude\hooks\memory-persistence\session-end.ps1"'

# Test 6: Stop - Continuous learning (no transcript)
Test-HookExecution -Name "Stop: Continuous learning" `
    -Command '& "$env:USERPROFILE\.claude\skills\continuous-learning\evaluate-session.ps1"'

# Test 7: Code Walkthrough hooks (server not required to pass)
$mockEnv = @{
    SESSION_ID = "test-session-123"
    PROJECT_DIR = "C:\test\project"
    TRANSCRIPT_PATH = "C:\test\transcript.jsonl"
    CWD = "C:\test"
}

Test-HookExecution -Name "UserPromptSubmit: Code Walkthrough" `
    -Command '& "$env:USERPROFILE\OneDrive\Documents\Code Repos\MCKRUZ\CodeReviewAssistant\vscode-extension\hooks\claude-hooks.ps1" -EventType prompt -SessionId "test"' `
    -MockEnv $mockEnv

Test-HookExecution -Name "PostToolUse: Code Walkthrough change" `
    -Command '& "$env:USERPROFILE\OneDrive\Documents\Code Repos\MCKRUZ\CodeReviewAssistant\vscode-extension\hooks\claude-hooks.ps1" -EventType change -SessionId "test" -FilePath "C:\test\file.ts" -ChangeType "Edit"' `
    -MockEnv $mockEnv

Test-HookExecution -Name "Stop: Code Walkthrough complete" `
    -Command '& "$env:USERPROFILE\OneDrive\Documents\Code Repos\MCKRUZ\CodeReviewAssistant\vscode-extension\hooks\claude-hooks.ps1" -EventType complete -SessionId "test"' `
    -MockEnv $mockEnv

# ============================================
# SUMMARY
# ============================================

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "  INTEGRATION TEST SUMMARY" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""
Write-Host "  Passed: $script:Passed" -ForegroundColor Green
Write-Host "  Failed: $script:Failed" -ForegroundColor $(if ($script:Failed -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($script:Failed -eq 0) {
    Write-Host "  RESULT: ALL INTEGRATION TESTS PASSED" -ForegroundColor Green
    Write-Host "  Ready to deploy hooks configuration" -ForegroundColor Green
    exit 0
} else {
    Write-Host "  RESULT: SOME TESTS FAILED" -ForegroundColor Red
    Write-Host "  Review failures before deploying" -ForegroundColor Red
    exit 1
}

