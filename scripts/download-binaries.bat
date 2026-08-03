@echo off
REM Downloads engram.exe (public release asset) and gentle-ai.exe (CI build
REM artifact) without running any local compiler. Requires:
REM   - curl and tar (built into Windows 10+)
REM   - GitHub CLI ("gh"), authenticated via "gh auth login", for gentle-ai.exe
REM     (Actions artifacts require an authenticated request even on public repos)

setlocal enabledelayedexpansion

set "DEST=%~dp0bin"
if not exist "%DEST%" mkdir "%DEST%"

echo ===============================================
echo  1/2  Downloading engram.exe (official release)
echo ===============================================

for /f "usebackq delims=" %%v in (`powershell -NoProfile -Command ^
  "(Invoke-RestMethod 'https://api.github.com/repos/Gentleman-Programming/engram/releases/latest').tag_name -replace '^v',''"`) do set "ENGRAM_VERSION=%%v"

if "%ENGRAM_VERSION%"=="" (
    echo ERROR: could not resolve latest engram version.
    exit /b 1
)

set "ENGRAM_ASSET=engram_%ENGRAM_VERSION%_windows_amd64.zip"
set "ENGRAM_URL=https://github.com/Gentleman-Programming/engram/releases/latest/download/%ENGRAM_ASSET%"

echo   version: %ENGRAM_VERSION%
curl -L --fail -o "%TEMP%\%ENGRAM_ASSET%" "%ENGRAM_URL%"
if errorlevel 1 (
    echo ERROR: failed to download %ENGRAM_URL%
    exit /b 1
)

tar -xf "%TEMP%\%ENGRAM_ASSET%" -C "%DEST%"
if errorlevel 1 (
    echo ERROR: failed to extract %ENGRAM_ASSET%
    exit /b 1
)
echo   done: %DEST%\engram.exe

echo.
echo ==========================================================
echo  2/2  Downloading gentle-ai.exe (latest CI build artifact)
echo ==========================================================

where gh >nul 2>nul
if errorlevel 1 (
    echo ERROR: GitHub CLI "gh" not found. Install from https://cli.github.com/
    echo        then run "gh auth login" once before re-running this script.
    exit /b 1
)

for /f "usebackq delims=" %%r in (`gh run list --repo felipepepe-ai-labs/gentle-ai --workflow=windows-build-artifact.yml --status=success --limit 1 --json databaseId --jq ".[0].databaseId"`) do set "RUN_ID=%%r"

if "%RUN_ID%"=="" (
    echo ERROR: no successful "windows-build-artifact" run found.
    echo        Trigger one first: gh workflow run windows-build-artifact.yml --repo felipepepe-ai-labs/gentle-ai
    exit /b 1
)

echo   run id: %RUN_ID%
gh run download %RUN_ID% --repo felipepepe-ai-labs/gentle-ai --dir "%DEST%"
if errorlevel 1 (
    echo ERROR: failed to download gentle-ai.exe artifact.
    exit /b 1
)

REM gh downloads into a subfolder named after the artifact (gentle-ai-windows-<sha>);
REM flatten it so both binaries end up directly in %DEST%.
for /d %%d in ("%DEST%\gentle-ai-windows-*") do (
    move /y "%%d\gentle-ai.exe" "%DEST%\gentle-ai.exe" >nul
    rmdir "%%d"
)

echo.
echo Done. Binaries are in: %DEST%
dir /b "%DEST%\*.exe"

endlocal
