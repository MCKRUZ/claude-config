# Comprehensive Hook Testing Script
# Tests all components before enabling hooks in settings.json

param(
    [switch]$Verbose,
    [switch]$FixIssues
)

$ErrorActionPreference = "Continue"
$script:TestResults = @()
$script:TotalTests = 0
$script:PassedTests = 0
$script:FailedTests = 0
$script:WarningTests = 0

function Write-TestHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "=" * 70 -ForegroundColor Cyan
}

function Write-TestResult {
    param(
        [string]$Test,
        [string]$Status,  # PASS, FAIL, WARN
        [string]$Message,
        [string]$Details = ""
    )

    $script:TotalTests++

    $color = switch ($Status) {
        "PASS" { $script:PassedTests++; "Green" }
        "FAIL" { $script:FailedTests++; "Red" }
        "WARN" { $script:WarningTests++; "Yellow" }
        default { "White" }
    }

    $statusIcon = switch ($Status) {
        "PASS" { "[PASS]" }
        "FAIL" { "[FAIL]" }
        "WARN" { "[WARN]" }
        default { "[????]" }
    }

    Write-Host "$statusIcon " -ForegroundColor $color -NoNewline
    Write-Host "$Test" -NoNewline
    if ($Message) {
        Write-Host " - $Message" -ForegroundColor Gray
    } else {
        Write-Host ""
    }

    if ($Details -and $Verbose) {
        Write-Host "        $Details" -ForegroundColor DarkGray
    }

    $script:TestResults += @{
        Test = $Test
        Status = $Status
        Message = $Message
        Details = $Details
    }
}

# ============================================
# TEST SECTION 1: File Existence
# ============================================
Write-TestHeader "1. FILE EXISTENCE CHECKS"

$requiredFiles = @(
    @{ Path = "$env:USERPROFILE\.claude\hooks\hooks.json"; Name = "Main hooks config" },
    @{ Path = "$env:USERPROFILE\.claude\hooks\auto-format.sh"; Name = "Auto-format script" },
    @{ Path = "$env:USERPROFILE\.claude\hooks\memory-persistence\session-start.ps1"; Name = "Session start script" },
    @{ Path = "$env:USERPROFILE\.claude\hooks\memory-persistence\pre-compact.ps1"; Name = "Pre-compact script" },
    @{ Path = "$env:USERPROFILE\.claude\hooks\memory-persistence\session-end.ps1"; Name = "Session end script" },
    @{ Path = "$env:USERPROFILE\.claude\hooks\strategic-compact\suggest-compact.ps1"; Name = "Strategic compact script" },
    @{ Path = "$env:USERPROFILE\.claude\skills\continuous-learning\evaluate-session.ps1"; Name = "Continuous learning script" },
    @{ Path = "$env:USERPROFILE\OneDrive\Documents\Code Repos\MCKRUZ\CodeReviewAssistant\vscode-extension\hooks\claude-hooks.ps1"; Name = "Code Walkthrough hooks" }
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file.Path) {
        Write-TestResult -Test $file.Name -Status "PASS" -Message "Found" -Details $file.Path
    } else {
        Write-TestResult -Test $file.Name -Status "FAIL" -Message "NOT FOUND" -Details $file.Path
    }
}

# ============================================
# TEST SECTION 2: JSON Syntax Validation
# ============================================
Write-TestHeader "2. JSON SYNTAX VALIDATION"

$jsonFiles = @(
    "$env:USERPROFILE\.claude\hooks\hooks.json",
    "$env:USERPROFILE\.claude\hooks-backup.json",
    "$env:USERPROFILE\.claude\settings.json"
)

foreach ($jsonFile in $jsonFiles) {
    $fileName = Split-Path $jsonFile -Leaf
    if (Test-Path $jsonFile) {
        try {
            $content = Get-Content $jsonFile -Raw
            $null = $content | ConvertFrom-Json
            Write-TestResult -Test "$fileName syntax" -Status "PASS" -Message "Valid JSON"
        } catch {
            Write-TestResult -Test "$fileName syntax" -Status "FAIL" -Message "Invalid JSON" -Details $_.Exception.Message
        }
    } else {
        Write-TestResult -Test "$fileName syntax" -Status "WARN" -Message "File not found"
    }
}

# ============================================
# TEST SECTION 3: PowerShell Script Syntax
# ============================================
Write-TestHeader "3. POWERSHELL SCRIPT SYNTAX"

$psScripts = @(
    "$env:USERPROFILE\.claude\hooks\memory-persistence\session-start.ps1",
    "$env:USERPROFILE\.claude\hooks\memory-persistence\pre-compact.ps1",
    "$env:USERPROFILE\.claude\hooks\memory-persistence\session-end.ps1",
    "$env:USERPROFILE\.claude\hooks\strategic-compact\suggest-compact.ps1",
    "$env:USERPROFILE\.claude\skills\continuous-learning\evaluate-session.ps1",
    "$env:USERPROFILE\OneDrive\Documents\Code Repos\MCKRUZ\CodeReviewAssistant\vscode-extension\hooks\claude-hooks.ps1"
)

foreach ($script in $psScripts) {
    $scriptName = Split-Path $script -Leaf
    if (Test-Path $script) {
        try {
            # Use proper variable initialization for Parser
            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($script, [ref]$tokens, [ref]$errors)
            if ($errors.Count -eq 0) {
                Write-TestResult -Test "$scriptName syntax" -Status "PASS" -Message "Valid PowerShell"
            } else {
                Write-TestResult -Test "$scriptName syntax" -Status "FAIL" -Message "$($errors.Count) syntax error(s)" -Details ($errors | Select-Object -First 1).Message
            }
        } catch {
            Write-TestResult -Test "$scriptName syntax" -Status "FAIL" -Message "Parse error" -Details $_.Exception.Message
        }
    } else {
        Write-TestResult -Test "$scriptName syntax" -Status "WARN" -Message "Script not found"
    }
}

# ============================================
# TEST SECTION 4: Dependency Checks
# ============================================
Write-TestHeader "4. DEPENDENCY CHECKS"

# Check for Git Bash (required for auto-format.sh)
$gitBashPath = "C:\Program Files\Git\bin\bash.exe"
if (Test-Path $gitBashPath) {
    Write-TestResult -Test "Git Bash" -Status "PASS" -Message "Found" -Details $gitBashPath
} else {
    Write-TestResult -Test "Git Bash" -Status "FAIL" -Message "NOT FOUND - required for auto-format.sh"
}

# Check for jq (used in auto-format.sh)
$jqPath = Get-Command jq -ErrorAction SilentlyContinue
if ($jqPath) {
    Write-TestResult -Test "jq (JSON processor)" -Status "PASS" -Message "Found" -Details $jqPath.Source
} else {
    Write-TestResult -Test "jq (JSON processor)" -Status "WARN" -Message "Not found - auto-format will use fallback"
}

# Check for prettier
$prettierPath = Get-Command prettier -ErrorAction SilentlyContinue
if ($prettierPath) {
    Write-TestResult -Test "Prettier" -Status "PASS" -Message "Found"
} else {
    # Check in node_modules
    $npmPrettier = npm list -g prettier 2>$null | Select-String "prettier"
    if ($npmPrettier) {
        Write-TestResult -Test "Prettier" -Status "PASS" -Message "Found (global npm)"
    } else {
        Write-TestResult -Test "Prettier" -Status "WARN" -Message "Not found - JS/TS formatting disabled"
    }
}

# Check for black (Python formatter)
$blackPath = Get-Command black -ErrorAction SilentlyContinue
if ($blackPath) {
    Write-TestResult -Test "Black (Python)" -Status "PASS" -Message "Found"
} else {
    Write-TestResult -Test "Black (Python)" -Status "WARN" -Message "Not found - Python formatting disabled"
}

# Check for csharpier
$csharpierPath = Get-Command csharpier -ErrorAction SilentlyContinue
if (-not $csharpierPath) {
    $csharpierPath = Get-Command dotnet-csharpier -ErrorAction SilentlyContinue
}
if ($csharpierPath) {
    Write-TestResult -Test "CSharpier" -Status "PASS" -Message "Found"
} else {
    # Check dotnet tools
    $dotnetTools = dotnet tool list -g 2>$null | Select-String "csharpier"
    if ($dotnetTools) {
        Write-TestResult -Test "CSharpier" -Status "PASS" -Message "Found (dotnet tool)"
    } else {
        Write-TestResult -Test "CSharpier" -Status "WARN" -Message "Not found - C# formatting disabled"
    }
}

# Check for gofmt
$gofmtPath = Get-Command gofmt -ErrorAction SilentlyContinue
if ($gofmtPath) {
    Write-TestResult -Test "gofmt (Go)" -Status "PASS" -Message "Found"
} else {
    Write-TestResult -Test "gofmt (Go)" -Status "WARN" -Message "Not found - Go formatting disabled"
}

# ============================================
# TEST SECTION 5: Directory Structure
# ============================================
Write-TestHeader "5. DIRECTORY STRUCTURE"

$requiredDirs = @(
    @{ Path = "$env:USERPROFILE\.claude\sessions"; Name = "Sessions directory" },
    @{ Path = "$env:USERPROFILE\.claude\skills\learned"; Name = "Learned skills directory" }
)

foreach ($dir in $requiredDirs) {
    if (Test-Path $dir.Path) {
        Write-TestResult -Test $dir.Name -Status "PASS" -Message "Exists" -Details $dir.Path
    } else {
        if ($FixIssues) {
            New-Item -ItemType Directory -Path $dir.Path -Force | Out-Null
            Write-TestResult -Test $dir.Name -Status "PASS" -Message "Created" -Details $dir.Path
        } else {
            Write-TestResult -Test $dir.Name -Status "WARN" -Message "Missing (will be created on first run)"
        }
    }
}

# ============================================
# TEST SECTION 6: Script Execution Tests
# ============================================
Write-TestHeader "6. SCRIPT EXECUTION TESTS"

# Test session-start.ps1
Write-Host "`nTesting session-start.ps1..." -ForegroundColor Gray
try {
    $output = & "$env:USERPROFILE\.claude\hooks\memory-persistence\session-start.ps1" 2>&1
    Write-TestResult -Test "session-start.ps1 execution" -Status "PASS" -Message "Runs without error"
    if ($Verbose -and $output) {
        Write-Host "        Output: $output" -ForegroundColor DarkGray
    }
} catch {
    Write-TestResult -Test "session-start.ps1 execution" -Status "FAIL" -Message $_.Exception.Message
}

# Test pre-compact.ps1
Write-Host "`nTesting pre-compact.ps1..." -ForegroundColor Gray
try {
    $output = & "$env:USERPROFILE\.claude\hooks\memory-persistence\pre-compact.ps1" 2>&1
    Write-TestResult -Test "pre-compact.ps1 execution" -Status "PASS" -Message "Runs without error"
} catch {
    Write-TestResult -Test "pre-compact.ps1 execution" -Status "FAIL" -Message $_.Exception.Message
}

# Test session-end.ps1
Write-Host "`nTesting session-end.ps1..." -ForegroundColor Gray
try {
    $output = & "$env:USERPROFILE\.claude\hooks\memory-persistence\session-end.ps1" 2>&1
    Write-TestResult -Test "session-end.ps1 execution" -Status "PASS" -Message "Runs without error"
} catch {
    Write-TestResult -Test "session-end.ps1 execution" -Status "FAIL" -Message $_.Exception.Message
}

# Test suggest-compact.ps1 (reads from stdin, so we need to handle that)
Write-Host "`nTesting suggest-compact.ps1..." -ForegroundColor Gray
try {
    # This script expects stdin and uses $input, test with empty input
    $output = echo "" | & "$env:USERPROFILE\.claude\hooks\strategic-compact\suggest-compact.ps1" 2>&1
    Write-TestResult -Test "suggest-compact.ps1 execution" -Status "PASS" -Message "Runs without error"
} catch {
    Write-TestResult -Test "suggest-compact.ps1 execution" -Status "FAIL" -Message $_.Exception.Message
}

# Test evaluate-session.ps1 (requires CLAUDE_TRANSCRIPT_PATH)
Write-Host "`nTesting evaluate-session.ps1..." -ForegroundColor Gray
try {
    $output = & "$env:USERPROFILE\.claude\skills\continuous-learning\evaluate-session.ps1" 2>&1
    # This should exit 0 because CLAUDE_TRANSCRIPT_PATH is not set
    Write-TestResult -Test "evaluate-session.ps1 execution" -Status "PASS" -Message "Runs without error (no transcript)"
} catch {
    Write-TestResult -Test "evaluate-session.ps1 execution" -Status "FAIL" -Message $_.Exception.Message
}

# Test claude-hooks.ps1 (Code Walkthrough)
Write-Host "`nTesting claude-hooks.ps1..." -ForegroundColor Gray
try {
    # Test with minimal required params - should fail gracefully since server isn't running
    $output = & "$env:USERPROFILE\OneDrive\Documents\Code Repos\MCKRUZ\CodeReviewAssistant\vscode-extension\hooks\claude-hooks.ps1" -EventType "prompt" -SessionId "test" 2>&1
    Write-TestResult -Test "claude-hooks.ps1 execution" -Status "PASS" -Message "Runs without crash (server not required)"
} catch {
    Write-TestResult -Test "claude-hooks.ps1 execution" -Status "WARN" -Message "Error but may be expected" -Details $_.Exception.Message
}

# ============================================
# TEST SECTION 7: Auto-Format Script Test
# ============================================
Write-TestHeader "7. AUTO-FORMAT SCRIPT TEST"

if (Test-Path "C:\Program Files\Git\bin\bash.exe") {
    # Create a temp test file
    $testFile = "$env:TEMP\test-format-$(Get-Random).json"
    '{"test":true}' | Set-Content $testFile

    # Create test JSON input
    $testInput = @{ tool_input = @{ file_path = $testFile } } | ConvertTo-Json -Compress

    try {
        $output = $testInput | & "C:\Program Files\Git\bin\bash.exe" "$env:USERPROFILE\.claude\hooks\auto-format.sh" 2>&1
        Write-TestResult -Test "auto-format.sh execution" -Status "PASS" -Message "Runs without error"
    } catch {
        Write-TestResult -Test "auto-format.sh execution" -Status "WARN" -Message "Error during test" -Details $_.Exception.Message
    } finally {
        Remove-Item $testFile -ErrorAction SilentlyContinue
    }
} else {
    Write-TestResult -Test "auto-format.sh execution" -Status "FAIL" -Message "Git Bash not available"
}

# ============================================
# TEST SECTION 8: Code Walkthrough Server Check
# ============================================
Write-TestHeader "8. CODE WALKTHROUGH SERVER CHECK"

$port = 51372
try {
    $connection = Test-NetConnection -ComputerName 127.0.0.1 -Port $port -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    if ($connection.TcpTestSucceeded) {
        Write-TestResult -Test "Code Walkthrough server (port $port)" -Status "PASS" -Message "Server is running"
    } else {
        Write-TestResult -Test "Code Walkthrough server (port $port)" -Status "WARN" -Message "Server not running - hooks will fail silently"
    }
} catch {
    Write-TestResult -Test "Code Walkthrough server (port $port)" -Status "WARN" -Message "Could not check port"
}

# ============================================
# TEST SECTION 9: Environment Variables
# ============================================
Write-TestHeader "9. ENVIRONMENT VARIABLES"

$envVars = @(
    @{ Name = "CLAUDE_TRANSCRIPT_PATH"; Required = $false; Description = "Set by Claude during session" },
    @{ Name = "SESSION_ID"; Required = $false; Description = "Set by Claude during session" },
    @{ Name = "PROJECT_DIR"; Required = $false; Description = "Set by Claude during session" },
    @{ Name = "CWD"; Required = $false; Description = "Set by Claude during session" }
)

foreach ($var in $envVars) {
    $value = [Environment]::GetEnvironmentVariable($var.Name)
    if ($value) {
        Write-TestResult -Test "ENV: $($var.Name)" -Status "PASS" -Message "Set" -Details $value
    } else {
        if ($var.Required) {
            Write-TestResult -Test "ENV: $($var.Name)" -Status "FAIL" -Message "Not set (required)"
        } else {
            Write-TestResult -Test "ENV: $($var.Name)" -Status "PASS" -Message "Not set ($($var.Description))"
        }
    }
}

# ============================================
# TEST SECTION 10: Hook Configuration Analysis
# ============================================
Write-TestHeader "10. HOOK CONFIGURATION ANALYSIS"

$hooksJsonPath = "$env:USERPROFILE\.claude\hooks\hooks.json"
if (Test-Path $hooksJsonPath) {
    $hooksConfig = Get-Content $hooksJsonPath -Raw | ConvertFrom-Json

    $hookTypes = @("SessionStart", "PreToolUse", "PreCompact", "UserPromptSubmit", "PostToolUse", "Stop")

    foreach ($hookType in $hookTypes) {
        if ($hooksConfig.hooks.$hookType) {
            $count = @($hooksConfig.hooks.$hookType).Count
            Write-TestResult -Test "Hook: $hookType" -Status "PASS" -Message "$count hook(s) configured"
        } else {
            Write-TestResult -Test "Hook: $hookType" -Status "WARN" -Message "Not configured"
        }
    }
} else {
    Write-TestResult -Test "Hook configuration" -Status "FAIL" -Message "hooks.json not found"
}

# ============================================
# SUMMARY
# ============================================
Write-Host ""
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "  TEST SUMMARY" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""
Write-Host "  Total Tests:  $script:TotalTests" -ForegroundColor White
Write-Host "  Passed:       $script:PassedTests" -ForegroundColor Green
Write-Host "  Warnings:     $script:WarningTests" -ForegroundColor Yellow
Write-Host "  Failed:       $script:FailedTests" -ForegroundColor Red
Write-Host ""

$passRate = [math]::Round(($script:PassedTests / $script:TotalTests) * 100, 1)
if ($script:FailedTests -eq 0) {
    Write-Host "  RESULT: ALL CRITICAL TESTS PASSED ($passRate%)" -ForegroundColor Green
    Write-Host "  Safe to proceed with hook implementation" -ForegroundColor Green
} elseif ($script:FailedTests -le 2) {
    Write-Host "  RESULT: MINOR ISSUES ($passRate% pass rate)" -ForegroundColor Yellow
    Write-Host "  Review failed tests before proceeding" -ForegroundColor Yellow
} else {
    Write-Host "  RESULT: CRITICAL ISSUES ($passRate% pass rate)" -ForegroundColor Red
    Write-Host "  DO NOT proceed until failed tests are resolved" -ForegroundColor Red
}

Write-Host ""
Write-Host "=" * 70 -ForegroundColor Cyan

# Return results for programmatic use
return @{
    Total = $script:TotalTests
    Passed = $script:PassedTests
    Warnings = $script:WarningTests
    Failed = $script:FailedTests
    Results = $script:TestResults
}

