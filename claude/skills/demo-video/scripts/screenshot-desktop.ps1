<#
.SYNOPSIS
    Capture a screenshot of the desktop or a specific window.

.PARAMETER OutputPath
    Path to save the screenshot. Default: ./output/screenshot.png

.PARAMETER WindowTitle
    If specified, capture only the window matching this title (partial match).

.PARAMETER Region
    Capture a specific region: "x,y,width,height" (e.g. "100,100,800,600").

.EXAMPLE
    .\screenshot-desktop.ps1
    .\screenshot-desktop.ps1 -OutputPath "./output/app.png"
    .\screenshot-desktop.ps1 -WindowTitle "Notepad"
    .\screenshot-desktop.ps1 -Region "0,0,1920,1080"
#>

param(
    [string]$OutputPath = "./output/screenshot.png",
    [string]$WindowTitle = "",
    [string]$Region = ""
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Ensure output directory exists
$outDir = Split-Path -Parent $OutputPath
if ($outDir -and -not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

# ── Window capture via title ──────────────────────────────────
if ($WindowTitle) {
    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class Win32 {
        [DllImport("user32.dll")]
        public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        [StructLayout(LayoutKind.Sequential)]
        public struct RECT {
            public int Left, Top, Right, Bottom;
        }
    }
"@

    $proc = Get-Process | Where-Object { $_.MainWindowTitle -like "*$WindowTitle*" } | Select-Object -First 1
    if (-not $proc) {
        Write-Error "No window found matching '$WindowTitle'"
        exit 1
    }

    $hwnd = $proc.MainWindowHandle
    [Win32]::SetForegroundWindow($hwnd) | Out-Null
    Start-Sleep -Milliseconds 300

    $rect = New-Object Win32+RECT
    [Win32]::GetWindowRect($hwnd, [ref]$rect) | Out-Null

    $x = $rect.Left
    $y = $rect.Top
    $w = $rect.Right - $rect.Left
    $h = $rect.Bottom - $rect.Top
}
# ── Region capture ────────────────────────────────────────────
elseif ($Region) {
    $parts = $Region -split ','
    if ($parts.Count -ne 4) {
        Write-Error "Region must be 'x,y,width,height' (e.g. '100,100,800,600')"
        exit 1
    }
    $x = [int]$parts[0]
    $y = [int]$parts[1]
    $w = [int]$parts[2]
    $h = [int]$parts[3]
}
# ── Full screen capture ──────────────────────────────────────
else {
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $x = $screen.X
    $y = $screen.Y
    $w = $screen.Width
    $h = $screen.Height
}

# Capture
$bitmap = New-Object System.Drawing.Bitmap($w, $h)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.CopyFromScreen($x, $y, 0, 0, (New-Object System.Drawing.Size($w, $h)))
$graphics.Dispose()

$bitmap.Save((Resolve-Path -Path $outDir | Join-Path -ChildPath (Split-Path -Leaf $OutputPath)))
$bitmap.Dispose()

Write-Host "Screenshot saved: $OutputPath ($w x $h)"
