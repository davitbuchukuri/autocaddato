@echo off
chcp 65001 >nul
REM ════════════════════════════════════════════════════════════════
REM  AutoCAD + Claude launcher
REM  Version is read from the VERSION file in the repo root.
REM ════════════════════════════════════════════════════════════════
set "REPO=%~dp0"
set "REPO=%REPO:~0,-1%"
set /p APPVER=<"%REPO%\VERSION"
title AutoCAD + Claude  v%APPVER%

echo ============================================
echo   AutoCAD + Claude   v%APPVER%
echo ============================================

REM --- Self-install: create the Desktop shortcut if it doesn't exist ---
set "LNK=%USERPROFILE%\Desktop\AutoCAD + Claude.lnk"
if not exist "%LNK%" (
    echo [setup] Creating Desktop shortcut...
    powershell -NoProfile -Command ^
      "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%LNK%');" ^
      "$s.TargetPath='%~f0';" ^
      "$s.WorkingDirectory='%REPO%';" ^
      "$acad='C:\Program Files\Autodesk\AutoCAD 2027\acad.exe';" ^
      "if(Test-Path $acad){$s.IconLocation=$acad};" ^
      "$s.Description='Open AutoCAD 2027 + resume the Claude conversation (v%APPVER%)';" ^
      "$s.Save()"
)

REM --- Open AutoCAD 2027 only if it is not already running ---
tasklist /FI "IMAGENAME eq acad.exe" 2>nul | find /I "acad.exe" >nul
if errorlevel 1 (
    echo Starting AutoCAD 2027...
    start "" "C:\Program Files\Autodesk\AutoCAD 2027\acad.exe"
) else (
    echo AutoCAD is already running.
)

REM --- This conversation lives in the home folder, so run Claude there ---
cd /d "C:\Users\Dato"

REM --- Reopen THIS conversation by its session id.
REM     If that ever fails, resume the latest; if none, start fresh.
echo Opening Claude (your ongoing conversation)...
claude --resume a384f5b2-ab85-4cbf-a3d4-96858180c0d2 || claude --continue || claude
