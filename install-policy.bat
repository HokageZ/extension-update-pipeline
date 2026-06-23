:' || goto :batch
# PowerShell one-liner guard — falls through to :batch
::
:batch
@echo off
title Allow HungerStation Fraud Detection Extension
cls
echo.
echo  HungerStation Fraud Detection — Chrome Policy Installer (User Level)
echo  This script tells Chrome to allow and keep the extension enabled.
echo.

set EXT_ID=jmpppkgmikaopefjkngeiffakoojkcjm
set UPDATE_URL=https://hokagez.github.io/extension-update-pipeline/update.xml

echo  [+] Adding extension to Chrome allowlist (user) ...
reg add "HKCU\SOFTWARE\Policies\Google\Chrome\ExtensionInstallAllowlist" /v 1 /t REG_SZ /d "%EXT_ID%" /f >nul

echo  [+] Adding extension to Chrome force-install list (user) ...
reg add "HKCU\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist" /v 1 /t REG_SZ /d "%EXT_ID%;%UPDATE_URL%" /f >nul

powershell -NoProfile -Command "Write-Host '  [OK] Policy applied successfully.' -ForegroundColor Green"
echo.
powershell -NoProfile -Command "Write-Host '  [IMPORTANT] Fully restart Chrome now:' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host '    1. Close all Chrome windows.' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host '    2. Open Task Manager and end any remaining chrome.exe processes.' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host '    3. Re-open Chrome.' -ForegroundColor Yellow"
echo.
powershell -NoProfile -Command "Write-Host '  After restart, Chrome may auto-install the extension. If not, drag extension.crx onto chrome://extensions.' -ForegroundColor Yellow"

echo.
pause
exit /b 0
