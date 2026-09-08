# Auto-Format Hook — Run formatter after file edits
#
# PostToolUse on Edit/Write/MultiEdit: automatically formats the edited file
# using the appropriate formatter (prettier, black, gofmt, dotnet format, rustfmt).

. "$PSScriptRoot\..\hook-profile.ps1" -HookId "format-on-edit" -MinProfile "strict"
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
if (-not (Test-Path $filePath)) { exit 0 }

$ext = [System.IO.Path]::GetExtension($filePath).ToLower()

try {
    switch -Regex ($ext) {
        '\.(js|jsx|ts|tsx|css|scss|json|html|vue|svelte|yaml|yml|md|mdx)$' {
            & npx prettier --write $filePath 2>&1 | Out-Null
        }
        '\.(py|pyi)$' {
            & python -m black $filePath --quiet 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) {
                & python -m autopep8 --in-place $filePath 2>&1 | Out-Null
            }
        }
        '\.(cs|csx)$' {
            & dotnet format --include $filePath 2>&1 | Out-Null
        }
        '\.go$' {
            & gofmt -w $filePath 2>&1 | Out-Null
        }
        '\.rs$' {
            & rustfmt $filePath 2>&1 | Out-Null
        }
        '\.rb$' {
            & rubocop -A $filePath --no-color 2>&1 | Out-Null
        }
    }
} catch {
    # Formatter not installed — skip silently
}

exit 0
