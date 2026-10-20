@echo off
setlocal EnableExtensions EnableDelayedExpansion
title DragShift - build and install
cd /d "%~dp0"

echo.
echo  ==== DragShift for Windows: one-click build + install ====
echo.

rem ---------- 1. Python 3.10-3.13 (installed automatically with winget if missing)
set "PYV="
call :findpy
if not defined PYV (
  echo [1/5] Python not found - installing Python 3.12 with winget...
  where winget >nul 2>nul || ( echo winget is not available. Install Python 3.12 from https://www.python.org/downloads/ ^(tick "Add python.exe to PATH"^) and run this file again. & goto :fail )
  winget install -e --id Python.Python.3.12 --scope user --silent --accept-package-agreements --accept-source-agreements
  call :findpy
  if not defined PYV ( echo Python was installed but is not visible yet. Close this window and run Install-DragShift.bat again. & goto :fail )
) else (
  echo [1/5] Using Python %PYV%
)

rem ---------- 2. private build environment
echo [2/5] Preparing build environment (first run downloads ~300 MB)...
if not exist ".build-venv\Scripts\python.exe" (
  py -%PYV% -m venv .build-venv 2>nul || python -m venv .build-venv || goto :fail
)
".build-venv\Scripts\python.exe" -m pip install --quiet --upgrade pip || goto :fail
".build-venv\Scripts\python.exe" -m pip install --quiet -r requirements.txt pyinstaller || goto :fail

rem ---------- 3. build the app folder
echo [3/5] Building DragShift...
taskkill /F /IM DragShift.exe >nul 2>nul
".build-venv\Scripts\python.exe" -m PyInstaller DragShift.spec --noconfirm --log-level WARN || goto :fail
if not exist "dist\DragShift\DragShift.exe" ( echo Build did not produce DragShift.exe & goto :fail )

rem ---------- 4. make the installer (Inno Setup, installed automatically if missing)
echo [4/5] Creating the installer...
call :findiscc
if not defined ISCC (
  where winget >nul 2>nul && winget install -e --id JRSoftware.InnoSetup --silent --accept-package-agreements --accept-source-agreements
  call :findiscc
)
if not defined ISCC (
  echo Inno Setup could not be installed automatically. The portable build is in dist\DragShift\DragShift.exe
  goto :fail
)
"%ISCC%" /Qp installer\DragShift.iss || goto :fail

rem ---------- 5. keep a standalone copy + run the installer
if not exist "release" mkdir "release"
copy /Y "dist\DragShift-Setup.exe" "release\DragShift-Setup.exe" >nul
echo [5/5] Launching DragShift-Setup.exe...
start "" "release\DragShift-Setup.exe"
echo.
echo  Done. Setup is open - follow it to finish installing.
echo.
echo  The standalone installer is saved at:
echo    %~dp0release\DragShift-Setup.exe
echo  It needs NO Python and nothing else: copy that one file to any Windows 10/11 PC and double-click it.
echo.
pause
exit /b 0

:findpy
for %%V in (3.12 3.13 3.11 3.10) do (
  if not defined PYV (
    py -%%V -c "import sys" >nul 2>nul && set "PYV=%%V"
  )
)
exit /b 0

:findiscc
set "ISCC="
for %%P in ("%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" "%ProgramFiles%\Inno Setup 6\ISCC.exe" "%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe") do (
  if exist %%P if not defined ISCC set "ISCC=%%~P"
)
exit /b 0

:fail
echo.
echo  Something went wrong - see the messages above.
pause
exit /b 1
