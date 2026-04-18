@echo off
:: ============================================================
::  build.bat — Full build pipeline for ig-normalizer
::
::  Run this script on Windows from the project root.
::  It will:
::    1. Create / activate a venv
::    2. Install dependencies
::    3. Run PyInstaller → produces dist\ig-normalizer.exe
::    4. (Optional) compile the Inno Setup installer
:: ============================================================

setlocal enabledelayedexpansion

set PROJECT_ROOT=%~dp0
set VENV_DIR=%PROJECT_ROOT%.venv
set DIST_DIR=%PROJECT_ROOT%dist
set SPEC_FILE=%PROJECT_ROOT%ig-normalizer.spec
set ISS_FILE=%PROJECT_ROOT%installer\ig-normalizer.iss

echo.
echo ============================================================
echo  ig-normalizer build script
echo ============================================================
echo.

:: --- Step 1: venv ---
if not exist "%VENV_DIR%\Scripts\activate.bat" (
    echo [1/4] Creating virtual environment...
    python -m venv "%VENV_DIR%"
) else (
    echo [1/4] Virtual environment already exists.
)

call "%VENV_DIR%\Scripts\activate.bat"

:: --- Step 2: install ---
echo [2/4] Installing package + PyInstaller...
pip install -e . --quiet
pip install pyinstaller --quiet

:: --- Step 3: PyInstaller ---
echo [3/4] Running PyInstaller...
pyinstaller "%SPEC_FILE%" --clean --noconfirm

if not exist "%DIST_DIR%\ig-normalizer.exe" (
    echo.
    echo ERROR: PyInstaller build failed. Check output above.
    exit /b 1
)

echo.
echo  EXE ready: %DIST_DIR%\ig-normalizer.exe
echo.

:: --- Step 4: Inno Setup (optional) ---
echo [4/4] Looking for Inno Setup Compiler (ISCC.exe)...

set ISCC=
for %%P in (
    "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
    "%ProgramFiles%\Inno Setup 6\ISCC.exe"
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
) do (
    if exist %%P set ISCC=%%P
)

if defined ISCC (
    echo  Found: !ISCC!
    echo  Compiling installer...
    !ISCC! "%ISS_FILE%"
    echo.
    echo  Installer ready: %PROJECT_ROOT%installer\output\
) else (
    echo  Inno Setup not found — skipping installer compilation.
    echo  Install it from https://jrsoftware.org/isinfo.php
    echo  Then run manually: ISCC.exe "%ISS_FILE%"
)

echo.
echo ============================================================
echo  Build complete!
echo ============================================================
echo.
pause
