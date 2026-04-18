# ============================================================
#  build.ps1 — Full build pipeline for ig-normalizer
#  Run from project root on Windows (PowerShell):
#    .\build.ps1
# ============================================================
param(
    [switch]$SkipInstaller  # pass -SkipInstaller to skip Inno Setup step
)

$ErrorActionPreference = "Stop"
$Root     = $PSScriptRoot
$VenvDir  = "$Root\.venv"
$DistExe  = "$Root\dist\ig-normalizer.exe"
$SpecFile = "$Root\ig-normalizer.spec"
$IssFile  = "$Root\installer\ig-normalizer.iss"
$OutDir   = "$Root\installer\output"

function Write-Step($n, $msg) {
    Write-Host ""
    Write-Host "[$n] $msg" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  ig-normalizer build script" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow

# --- Step 1: venv ---
Write-Step "1/4" "Setting up virtual environment..."
if (-not (Test-Path "$VenvDir\Scripts\Activate.ps1")) {
    python -m venv $VenvDir
}
& "$VenvDir\Scripts\Activate.ps1"

# --- Step 2: install deps ---
Write-Step "2/4" "Installing package + PyInstaller..."
pip install -e $Root --quiet
pip install pyinstaller --quiet

# --- Step 3: PyInstaller ---
Write-Step "3/4" "Running PyInstaller..."
pyinstaller $SpecFile --clean --noconfirm

if (-not (Test-Path $DistExe)) {
    Write-Host "`nERROR: PyInstaller build failed. Check output above." -ForegroundColor Red
    exit 1
}
Write-Host "  EXE ready: $DistExe" -ForegroundColor Green

# --- Step 4: Inno Setup ---
if (-not $SkipInstaller) {
    Write-Step "4/4" "Looking for Inno Setup Compiler (ISCC.exe)..."

    $isccPaths = @(
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
        "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
    )
    $iscc = $isccPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if ($iscc) {
        Write-Host "  Found: $iscc" -ForegroundColor Green
        Write-Host "  Compiling installer..."
        & $iscc $IssFile
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "  Installer ready:" -ForegroundColor Green
            Get-ChildItem $OutDir -Filter "*.exe" | ForEach-Object {
                Write-Host "    $($_.FullName)" -ForegroundColor Green
            }
        } else {
            Write-Host "  Inno Setup compilation failed (exit code $LASTEXITCODE)." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "  Inno Setup not found — skipping." -ForegroundColor Yellow
        Write-Host "  Install from https://jrsoftware.org/isinfo.php"
        Write-Host "  Then run: ISCC.exe `"$IssFile`""
    }
} else {
    Write-Host "[4/4] Skipped Inno Setup (--SkipInstaller flag set)."
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  Build complete!" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
