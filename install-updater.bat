@echo off
setlocal EnableDelayedExpansion

echo ============================================
echo  Fraud Detection Extension Updater Setup
echo ============================================
echo.

REM Determine paths
set "UPDATER_DIR=%APPDATA%\FD-Updater"
set "SOURCE_DIR=%~dp0"
set "EXT_PATH="

REM Try to auto-detect extension folder
if exist "%SOURCE_DIR%extension\manifest.json" (
    set "EXT_PATH=%SOURCE_DIR%extension"
    echo Found extension folder: !EXT_PATH!
) else (
    echo Could not auto-detect the extension folder.
    echo.
    echo Please paste the FULL path to the folder that contains the extension files.
    echo Example: C:\Users\YourName\Downloads\hungerstation-fraud-detection\extension
    echo.
    set /p "EXT_PATH=Extension folder path: "
)

if not defined EXT_PATH (
    echo ERROR: No extension path provided.
    pause
    exit /b 1
)

if not exist "%EXT_PATH%\manifest.json" (
    echo ERROR: manifest.json not found in %EXT_PATH%
    echo Please make sure you selected the correct extension folder.
    pause
    exit /b 1
)

REM Create updater directory
if not exist "%UPDATER_DIR%" mkdir "%UPDATER_DIR%"

REM Copy updater files
copy /Y "%SOURCE_DIR%extension\updater\helper.cmd" "%UPDATER_DIR%\helper.cmd" >nul
copy /Y "%SOURCE_DIR%extension\updater\helper.ps1" "%UPDATER_DIR%\helper.ps1" >nul
copy /Y "%SOURCE_DIR%extension\updater\native-host.json" "%UPDATER_DIR%\native-host.json" >nul

REM Write config file with extension path
(
echo {
echo   "extensionPath": "%EXT_PATH:\=\\%"
echo }
) > "%UPDATER_DIR%\config.json"

REM Update native-host.json path to absolute path of helper.cmd
REM We keep it relative in the repo so it works in dev, but installed copy needs absolute.
powershell -NoProfile -Command "
$json = Get-Content '%UPDATER_DIR%\native-host.json' | ConvertFrom-Json
$json.path = '%UPDATER_DIR%\helper.cmd'.Replace('\', '\\')
$json | ConvertTo-Json -Compress | Set-Content '%UPDATER_DIR%\native-host.json' -Encoding UTF8
"

REM Register Native Messaging host for Chrome, Edge, and Brave
set "HOST_NAME=com.hungerstation.fd_updater"

echo.
echo Registering Native Messaging host...

REM Chrome
reg add "HKCU\SOFTWARE\Google\Chrome\NativeMessagingHosts\%HOST_NAME%" /ve /t REG_SZ /d "%UPDATER_DIR%\native-host.json" /f > NUL 2>&1
reg add "HKLM\SOFTWARE\Google\Chrome\NativeMessagingHosts\%HOST_NAME%" /ve /t REG_SZ /d "%UPDATER_DIR%\native-host.json" /f > NUL 2>&1

REM Edge
reg add "HKCU\SOFTWARE\Microsoft\Edge\NativeMessagingHosts\%HOST_NAME%" /ve /t REG_SZ /d "%UPDATER_DIR%\native-host.json" /f > NUL 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Edge\NativeMessagingHosts\%HOST_NAME%" /ve /t REG_SZ /d "%UPDATER_DIR%\native-host.json" /f > NUL 2>&1

REM Brave
reg add "HKCU\SOFTWARE\BraveSoftware\Brave\NativeMessagingHosts\%HOST_NAME%" /ve /t REG_SZ /d "%UPDATER_DIR%\native-host.json" /f > NUL 2>&1
reg add "HKLM\SOFTWARE\BraveSoftware\Brave\NativeMessagingHosts\%HOST_NAME%" /ve /t REG_SZ /d "%UPDATER_DIR%\native-host.json" /f > NUL 2>&1

echo.
echo ============================================
echo  Setup complete!
echo ============================================
echo.
echo Updater files installed to: %UPDATER_DIR%
echo Extension path: %EXT_PATH%
echo.
echo You can now use "Check for Updates" in the
echo extension dashboard. When an update is found,
echo click "Update Now" to install it automatically.
echo.
pause
