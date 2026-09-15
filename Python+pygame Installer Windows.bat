@echo off
setlocal EnableDelayedExpansion
title Snake Game - Launcher
cd /d "%~dp0"

REM ============================================================
REM  Snake Game bootstrapper (Windows)
REM
REM  This script only checks/installs the Python interpreter
REM  itself. It never touches snake_game_data.json (your saves,
REM  settings, achievements, high scores) — that file is only
REM  ever read/written by the game (SGFF.py), never by this
REM  launcher. Once Python is confirmed working, this script
REM  hands off to SGFF.py, which runs its own checks for pygame
REM  and other packages and can update those itself.
REM ============================================================

echo.
echo ================================================
echo   Snake Game - Startup Check
echo ================================================
echo.

set "PYCMD="
set "MIN_MAJOR=3"
set "MIN_MINOR=8"

REM --- Step 1: look for a working Python launcher ------------
echo [1/3] Checking for Python...

where py >nul 2>&1
if %ERRORLEVEL%==0 (
    py -3 --version >nul 2>&1
    if !ERRORLEVEL!==0 (
        set "PYCMD=py -3"
    )
)

if not defined PYCMD (
    where python >nul 2>&1
    if !ERRORLEVEL!==0 (
        python --version >nul 2>&1
        if !ERRORLEVEL!==0 (
            set "PYCMD=python"
        )
    )
)

if not defined PYCMD (
    echo   No Python installation was found on this PC.
    goto :offer_install
)

REM --- Step 2: check the version is new enough ----------------
echo [2/3] Checking Python version...

for /f "tokens=2" %%v in ('%PYCMD% --version 2^>^&1') do set "PYVER=%%v"
echo   Found Python !PYVER!

%PYCMD% -c "import sys; sys.exit(0 if sys.version_info >= (%MIN_MAJOR%, %MIN_MINOR%) else 1)"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo   Python !PYVER! is older than the minimum needed ^(%MIN_MAJOR%.%MIN_MINOR%+^).
    goto :offer_update
)

echo   Python !PYVER! is OK.
goto :launch_game

REM ============================================================
:offer_install
echo.
echo   Snake Game needs Python %MIN_MAJOR%.%MIN_MINOR% or newer to run.
echo.
set /p "REPLY=  Install it now? (y/n): "
if /i "%REPLY%"=="y" goto :do_install
if /i "%REPLY%"=="yes" goto :do_install
goto :ask_close_required

REM ============================================================
:offer_update
echo.
set /p "REPLY=  Update Python now? (y/n): "
if /i "%REPLY%"=="y" goto :do_install
if /i "%REPLY%"=="yes" goto :do_install
goto :ask_close_required

REM ============================================================
:ask_close_required
echo.
echo   Snake Game can't run correctly without a compatible Python.
set /p "REPLY2=  Install now, or close the game? (install/close): "
if /i "%REPLY2%"=="install" goto :do_install
echo.
echo   Closing. Run this launcher again whenever you're ready.
pause
exit /b 1

REM ============================================================
:do_install
echo.
echo [3/3] Installing/updating Python — this may take a few minutes.
echo   Using only official, trusted sources ^(winget / python.org^).
echo.

where winget >nul 2>&1
if %ERRORLEVEL%==0 (
    echo   Installing via winget ^(Windows Package Manager^)...
    winget install --id Python.Python.3.12 -e --source winget --accept-package-agreements --accept-source-agreements
    if !ERRORLEVEL! NEQ 0 (
        echo   winget install did not complete successfully. Falling back to
        echo   the official python.org installer...
        goto :install_from_python_org
    )
) else (
    goto :install_from_python_org
)
goto :recheck_after_install

:install_from_python_org
echo   Downloading the official installer from python.org ...
set "PY_INSTALLER_URL=https://www.python.org/ftp/python/3.12.7/python-3.12.7-amd64.exe"
set "PY_INSTALLER=%TEMP%\python-installer.exe"
curl -L -o "%PY_INSTALLER%" "%PY_INSTALLER_URL%"
if not exist "%PY_INSTALLER%" (
    echo   Download failed. Please install Python manually from
    echo   https://www.python.org/downloads/ and run this launcher again.
    pause
    exit /b 1
)
echo   Running the official installer ^(follow any prompts it shows^)...
"%PY_INSTALLER%" InstallAllUsers=0 PrependPath=1 Include_test=0
del "%PY_INSTALLER%" >nul 2>&1

:recheck_after_install
echo.
echo   Verifying installation...
set "PYCMD="
where py >nul 2>&1
if %ERRORLEVEL%==0 set "PYCMD=py -3"
if not defined PYCMD (
    where python >nul 2>&1
    if !ERRORLEVEL!==0 set "PYCMD=python"
)
if not defined PYCMD (
    echo.
    echo   Python still isn't available on PATH. You may need to restart
    echo   your PC once, or reinstall from https://www.python.org/downloads/
    pause
    exit /b 1
)
%PYCMD% --version
echo   Python installed/updated successfully.
echo.

REM ============================================================
:launch_game
echo.
echo Starting Snake Game...
echo.
%PYCMD% "%~dp0SGF.py"
set "GAME_EXIT=%ERRORLEVEL%"
if not "%GAME_EXIT%"=="0" (
    echo.
    echo Snake Game exited with an error ^(code %GAME_EXIT%^).
    pause
)
exit /b %GAME_EXIT%
