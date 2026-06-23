:' || goto :batch
# PowerShell one-liner guard — falls through to :batch
::
:batch
@echo off
title Allow HungerStation Fraud Detection Extension
cls
echo.
echo  HungerStation Fraud Detection — Chrome Policy Installer (User Level)
echo  This script allows the self-hosted extension and enables silent auto-updates.
echo.

set EXT_ID=jmpppkgmikaopefjkngeiffakoojkcjm
set UPDATE_URL=https://hokagez.github.io/extension-update-pipeline/update.xml

echo  [+] Adding extension to Chrome allowlist (current user) ...
reg add "HKCU\SOFTWARE\Policies\Google\Chrome\ExtensionInstallAllowlist" /v 1 /t REG_SZ /d "%EXT_ID%" /f >nul

echo  [+] Adding extension to Chrome force-install list (current user) ...
reg add "HKCU\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist" /v 1 /t REG_SZ /d "%EXT_ID%;%UPDATE_URL%" /f >nul

echo  [+] Policy applied successfully.
echo.
choice /c YN /n /m "  Restart Chrome now to apply changes? [Y/N] "
if %errorlevel% equ 1 (
    echo  [+] Restarting Chrome ...
    taskkill /f /im chrome.exe >nul 2>&1
    timeout /t 2 /nobreak >nul
    start chrome.exe
) else (
    echo  [!] Please restart Chrome manually for the change to take effect.
)

echo.
echo  Done. The extension should now be allowed and will auto-update.
pause
exit /b 0
