:' || goto :batch
# PowerShell one-liner guard — falls through to :batch
::
:batch
@echo off
title HungerStation Fraud Detection — Microsoft Edge Policy Installer
cls
echo.
echo  HungerStation Fraud Detection — Microsoft Edge Policy Installer
echo  This script tells Edge to allow and auto-enable the extension.
echo.
:: Run as administrator check
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  [X] This script must be run as Administrator.
    echo      Right-click this file and select "Run as administrator".
    echo.
    pause
    exit /b 1
)

set EXT_ID=jmpppkgmikaopefjkngeiffakoojkcjm
set UPDATE_URL=https://hokagez.github.io/extension-update-pipeline/update.xml

echo  [+] Adding extension to Edge allowlist (machine) ...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallAllowlist" /v 1 /t REG_SZ /d "%EXT_ID%" /f >nul

echo  [+] Adding extension to Edge force-install list (machine) ...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist" /v 1 /t REG_SZ /d "%EXT_ID%;%UPDATE_URL%" /f >nul

echo  [+] Adding extension to Edge allowlist (user) ...
reg add "HKCU\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallAllowlist" /v 1 /t REG_SZ /d "%EXT_ID%" /f >nul

echo  [+] Adding extension to Edge force-install list (user) ...
reg add "HKCU\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist" /v 1 /t REG_SZ /d "%EXT_ID%;%UPDATE_URL%" /f >nul

powershell -NoProfile -Command "Write-Host '  [OK] Policy applied successfully.' -ForegroundColor Green"
echo.
powershell -NoProfile -Command "Write-Host '  [IMPORTANT] Fully restart Edge now:' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host '    1. Close all Edge windows.' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host '    2. Open Task Manager and end any remaining msedge.exe processes.' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host '    3. Re-open Edge.' -ForegroundColor Yellow"
echo.
powershell -NoProfile -Command "Write-Host '  After restart, Edge will auto-install the extension automatically.' -ForegroundColor Green"

echo.
pause
exit /b 0
