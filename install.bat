@echo off
setlocal EnableDelayedExpansion

echo ============================================================
echo   HungerStation Fraud Detection - One-Click Installer
echo ============================================================
echo.

REM Install paths (per-user, no admin required)
set "INSTALL_DIR=%LOCALAPPDATA%\HungerStation-FD"
set "EXT_DIR=%INSTALL_DIR%\extension"
set "UPDATER_DIR=%APPDATA%\FD-Updater"
set "ZIP_FILE=%INSTALL_DIR%\extension.zip"

REM Release download URL (hosted on public GitHub Pages repo)
set "RELEASE_ZIP=https://hokagez.github.io/extension-update-pipeline/extension.zip"

REM Create install directory
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

REM Detect default browser from registry
echo Detecting your default browser...
for /f "tokens=2*" %%a in ('reg query "HKCR\http\shell\open\command" /ve 2^>nul ^| findstr /C:"REG_SZ"') do set "BROWSER_CMD=%%b"

if not defined BROWSER_CMD (
    echo Could not detect default browser. Falling back to Chrome.
    set "BROWSER_CMD=chrome"
)

REM Extract executable name for detection
set "BROWSER_LOWER=%BROWSER_CMD%"
set "BROWSER_LOWER=%BROWSER_LOWER:\=/%"
set "BROWSER_LOWER=%BROWSER_LOWER:chrome.exe=chrome%"
set "BROWSER_LOWER=%BROWSER_LOWER:msedge.exe=edge%"
set "BROWSER_LOWER=%BROWSER_LOWER:brave.exe=brave%"

if not "x%BROWSER_LOWER:chrome=%"=="x%BROWSER_LOWER%" (
    set "BROWSER_NAME=chrome"
) else if not "x%BROWSER_LOWER:edge=%"=="x%BROWSER_LOWER%" (
    set "BROWSER_NAME=edge"
) else if not "x%BROWSER_LOWER:brave=%"=="x%BROWSER_LOWER%" (
    set "BROWSER_NAME=brave"
) else (
    set "BROWSER_NAME=chrome"
)

echo Default browser detected: %BROWSER_NAME%
echo.

REM Download latest extension.zip
echo Downloading latest extension package...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -Uri '%RELEASE_ZIP%' -OutFile '%ZIP_FILE%' -UseBasicParsing -MaximumRedirection 3 } catch { exit 1 }"

if not exist "%ZIP_FILE%" (
    echo.
    echo ERROR: Could not download extension.zip.
    echo Please check your internet connection and try again.
    pause
    exit /b 1
)

REM Remove old extension folder and extract
echo Extracting extension files...
if exist "%EXT_DIR%" rmdir /S /Q "%EXT_DIR%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%INSTALL_DIR%' -Force"

if not exist "%EXT_DIR%\manifest.json" (
    echo.
    echo ERROR: Extraction failed or manifest.json not found.
    pause
    exit /b 1
)

REM Install updater helper files
echo Installing auto-update helper...
if not exist "%UPDATER_DIR%" mkdir "%UPDATER_DIR%"
copy /Y "%EXT_DIR%\updater\helper.cmd" "%UPDATER_DIR%\helper.cmd" > NUL 2>&1
copy /Y "%EXT_DIR%\updater\helper.ps1" "%UPDATER_DIR%\helper.ps1" > NUL 2>&1
copy /Y "%EXT_DIR%\updater\native-host.json" "%UPDATER_DIR%\native-host.json" > NUL 2>&1

REM Write updater config
(
echo {
echo   "extensionPath": "%EXT_DIR:\=\\%"
echo }
) > "%UPDATER_DIR%\config.json"

REM Update native-host.json with absolute path
powershell -NoProfile -ExecutionPolicy Bypass -Command "
$json = Get-Content '%UPDATER_DIR%\native-host.json' | ConvertFrom-Json
$json.path = '%UPDATER_DIR%\helper.cmd'.Replace('\', '\\')
$json | ConvertTo-Json -Compress | Set-Content '%UPDATER_DIR%\native-host.json' -Encoding UTF8
"

REM Register Native Messaging host for all browsers (HKCU only, no admin needed)
echo Registering browser updater integration...
set "HOST_NAME=com.hungerstation.fd_updater"

reg add "HKCU\SOFTWARE\Google\Chrome\NativeMessagingHosts\%HOST_NAME%" /ve /t REG_SZ /d "%UPDATER_DIR%\native-host.json" /f > NUL 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Edge\NativeMessagingHosts\%HOST_NAME%" /ve /t REG_SZ /d "%UPDATER_DIR%\native-host.json" /f > NUL 2>&1
reg add "HKCU\SOFTWARE\BraveSoftware\Brave\NativeMessagingHosts\%HOST_NAME%" /ve /t REG_SZ /d "%UPDATER_DIR%\native-host.json" /f > NUL 2>&1

REM Copy extension path to clipboard
echo %EXT_DIR% | clip

REM Build browser-specific URLs
set "CHROME_EXT_URL=chrome://extensions/"
set "EDGE_EXT_URL=edge://extensions/"
set "BRAVE_EXT_URL=brave://extensions/"

REM Try to launch browser with extension auto-loaded for immediate use
echo.
echo Launching browser with the extension loaded...
echo (If a new browser window opens, you can use it right away.)
echo.

if "%BROWSER_NAME%"=="chrome" (
    start "" chrome --load-extension="%EXT_DIR%" "%CHROME_EXT_URL%"
) else if "%BROWSER_NAME%"=="edge" (
    start "" msedge --load-extension="%EXT_DIR%" "%EDGE_EXT_URL%"
) else if "%BROWSER_NAME%"=="brave" (
    start "" brave --load-extension="%EXT_DIR%" "%BRAVE_EXT_URL%"
) else (
    start "" chrome --load-extension="%EXT_DIR%" "%CHROME_EXT_URL%"
)

REM Wait a moment for browser to open
timeout /t 3 /nobreak > NUL

REM Show final instructions
echo.
echo ============================================================
echo   Installation Complete!
echo ============================================================
echo.
echo Extension folder: %EXT_DIR%
echo.
echo The extension path has been copied to your clipboard.
echo.
echo IMPORTANT: For the extension to persist after browser restart,
echo you must load it unpacked:
echo.
echo   1. In the browser window that just opened, enable 
echo      DEVELOPER MODE (toggle top-right).
echo   2. Click LOAD UNPACKED.
echo   3. Press Ctrl+V, then press Enter (path is already copied).
echo   4. Click SELECT FOLDER.
echo.
echo After that, the extension will auto-update itself from the
echo Help & Updates tab whenever a new version is released.
echo.
echo Press any key to close this window...
pause > NUL
