# TDD Gate Hook — Enforce test-first development
#
# PreToolUse on Edit/Write/MultiEdit: blocks edits to production code files
# unless a corresponding test file exists in the project.

. "$PSScriptRoot\..\hook-profile.ps1" -HookId "tdd-gate" -MinProfile "strict"
if ($script:HookSkipped) { exit 0 }

$input_json = $args[0]
if (-not $input_json) {
    $input_json = [Console]::In.ReadToEnd()
}

try {
    $data = $input_json | ConvertFrom-Json -ErrorAction Stop
    $filePath = $data.tool_input.file_path
    if (-not $filePath) { $filePath = $data.tool_input.path }
} catch {
    exit 0
}

if (-not $filePath) { exit 0 }

$codeExtensions = @('.cs', '.py', '.ts', '.tsx', '.js', '.jsx', '.go', '.rs', '.rb', '.php', '.java', '.kt', '.swift', '.dart')
$ext = [System.IO.Path]::GetExtension($filePath).ToLower()

if ($codeExtensions -notcontains $ext) { exit 0 }

$fileName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
$fullFileName = [System.IO.Path]::GetFileName($filePath)

$isTestFile = (
    $fullFileName -match '\.(test|spec|tests)\.' -or
    $fullFileName -match '^test_' -or
    $fullFileName -match '(Test|Tests|Spec)\.'
)
if ($isTestFile) { exit 0 }

$skipPatterns = @(
    'Migration', 'migration', 'Startup', 'Program',
    'appsettings', 'package.json', 'tsconfig',
    '\.config\.', '\.module\.', '\.routing\.',
    'DependencyInjection', 'ServiceCollectionExtensions'
)
foreach ($sp in $skipPatterns) {
    if ($filePath -match $sp) { exit 0 }
}

$dir = Split-Path $filePath -Parent
if (-not $dir -or -not (Test-Path $dir)) { exit 0 }

$baseName = $fileName -replace '(Service|Controller|Handler|Repository|Provider|Manager|Helper|Util|Utils)$', ''

$testSearchPatterns = @(
    "${fileName}Test$ext", "${fileName}Tests$ext", "${fileName}Spec$ext",
    "${fileName}.test$ext", "${fileName}.spec$ext", "${fileName}.tests$ext",
    "test_${fileName}$ext", "${fileName}_test$ext"
)

$found = $false
foreach ($tsp in $testSearchPatterns) {
    $results = Get-ChildItem -Path $dir -Filter $tsp -Recurse -ErrorAction SilentlyContinue -Depth 1
    if ($results) { $found = $true; break }
}

if (-not $found) {
    $projectRoot = $dir
    for ($i = 0; $i -lt 6; $i++) {
        $parent = Split-Path $projectRoot -Parent
        if (-not $parent -or $parent -eq $projectRoot) { break }
        $projectRoot = $parent
    }
    foreach ($tsp in $testSearchPatterns) {
        $results = Get-ChildItem -Path $projectRoot -Filter $tsp -Recurse -ErrorAction SilentlyContinue -Depth 6
        if ($results) { $found = $true; break }
    }
}

if (-not $found) {
    Write-Error "BLOCKED: No test file found for '$fileName$ext'. Write tests first (TDD). Expected one of: ${fileName}Test$ext, ${fileName}.test$ext, ${fileName}.spec$ext, test_${fileName}$ext"
    exit 2
}

exit 0
