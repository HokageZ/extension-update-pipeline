@echo off
setlocal EnableDelayedExpansion

REM ============================================================
REM HungerStation Fraud Detection - One-Click Installer
REM ============================================================

REM Catch any unexpected exit and pause so the user can read output.
if not defined FD_INSTALLER_PAUSE (
    set "FD_INSTALLER_PAUSE=1"
    cmd /k "%~f0" %*
    exit /b
)

echo ============================================================
echo   HungerStation Fraud Detection - One-Click Installer
echo ============================================================
echo.

REM Install paths (per-user, no admin required)
set "INSTALL_DIR=%LOCALAPPDATA%\HungerStation-FD"
set "EXT_DIR=%INSTALL_DIR%\extension"
set "UPDATER_DIR=%APPDATA%\FD-Updater"
set "ZIP_FILE=%INSTALL_DIR%\extension.zip"

REM Public GitHub Pages URLs
set "RELEASE_ZIP=https://hokagez.github.io/extension-update-pipeline/extension.zip"
set "INSTRUCTIONS_URL=https://hokagez.github.io/extension-update-pipeline/instructions.html"

REM Create install directory
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

REM --------------------------------------------------
REM Browser detection and menu (PowerShell helper)
REM --------------------------------------------------
set "PS_HELPER=%TEMP%\fd_browser_menu.ps1"
set "SELECTED_FILE=%TEMP%\fd_selected_browser.txt"
if exist "%SELECTED_FILE%" del "%SELECTED_FILE%"

REM Build helper script line-by-line to avoid batch block parsing issues
> "%PS_HELPER%" echo $ErrorActionPreference = 'SilentlyContinue'
>> "%PS_HELPER%" echo.
>> "%PS_HELPER%" echo $progMap = @{
>> "%PS_HELPER%" echo     'ChromeHTML' = 'chrome'
>> "%PS_HELPER%" echo     'MSEdgeHTM'  = 'edge'
>> "%PS_HELPER%" echo     'BraveHTML'  = 'brave'
>> "%PS_HELPER%" echo }
>> "%PS_HELPER%" echo.
>> "%PS_HELPER%" echo $defaultProgId = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice' -Name ProgId).ProgId
>> "%PS_HELPER%" echo $defaultId = if ($progMap.ContainsKey($defaultProgId)) { $progMap[$defaultProgId] } else { $null }
>> "%PS_HELPER%" echo.
>> "%PS_HELPER%" echo function Get-BrowserPathFromCommand($cmd) {
>> "%PS_HELPER%" echo     if (-not $cmd) { return $null }
>> "%PS_HELPER%" echo     $cmd = $cmd.Trim().TrimStart('"').Split('"')[0]
>> "%PS_HELPER%" echo     if (Test-Path $cmd) { return $cmd }
>> "%PS_HELPER%" echo     return $null
>> "%PS_HELPER%" echo }
>> "%PS_HELPER%" echo.
>> "%PS_HELPER%" echo function Find-InStartMenuInternet($searchName, $id) {
>> "%PS_HELPER%" echo     $roots = @('HKLM:\SOFTWARE\Clients\StartMenuInternet', 'HKLM:\SOFTWARE\WOW6432Node\Clients\StartMenuInternet')
>> "%PS_HELPER%" echo     :rootLoop foreach ($root in $roots) {
>> "%PS_HELPER%" echo         foreach ($item in (Get-ChildItem $root -ErrorAction SilentlyContinue)) {
>> "%PS_HELPER%" echo             $display = (Get-ItemProperty $item.PSPath -Name DisplayName -ErrorAction SilentlyContinue).DisplayName
>> "%PS_HELPER%" echo             if (-not $display) { $display = $item.PSChildName }
>> "%PS_HELPER%" echo             if ($display -like "*$searchName*") {
>> "%PS_HELPER%" echo                 $cmd = (Get-ItemProperty "$($item.PSPath)\shell\open\command" -Name '(Default)' -ErrorAction SilentlyContinue).'(Default)'
>> "%PS_HELPER%" echo                 $path = Get-BrowserPathFromCommand $cmd
>> "%PS_HELPER%" echo                 if ($path) {
>> "%PS_HELPER%" echo                     return [PSCustomObject]@{ Id = $id; Name = $display; Path = $path }
>> "%PS_HELPER%" echo                 }
>> "%PS_HELPER%" echo             }
>> "%PS_HELPER%" echo         }
>> "%PS_HELPER%" echo     }
>> "%PS_HELPER%" echo     return $null
>> "%PS_HELPER%" echo }
>> "%PS_HELPER%" echo.
>> "%PS_HELPER%" echo function Find-InHtmlProgId($progId, $id, $fallbackName) {
>> "%PS_HELPER%" echo     $cmd = (Get-ItemProperty "HKCR:\$progId\shell\open\command" -Name '(Default)' -ErrorAction SilentlyContinue).'(Default)'
>> "%PS_HELPER%" echo     $path = Get-BrowserPathFromCommand $cmd
>> "%PS_HELPER%" echo     if ($path) {
>> "%PS_HELPER%" echo         return [PSCustomObject]@{ Id = $id; Name = $fallbackName; Path = $path }
>> "%PS_HELPER%" echo     }
>> "%PS_HELPER%" echo     return $null
>> "%PS_HELPER%" echo }
>> "%PS_HELPER%" echo.
>> "%PS_HELPER%" echo $browsers = @()
>> "%PS_HELPER%" echo.
>> "%PS_HELPER%" echo $chrome = Find-InStartMenuInternet 'Chrome' 'chrome'
>> "%PS_HELPER%" echo if (-not $chrome) { $chrome = Find-InHtmlProgId 'ChromeHTML' 'chrome' 'Google Chrome' }
>> "%PS_HELPER%" echo if ($chrome) { $browsers += $chrome }
>> "%PS_HELPER%" echo.
>> "%PS_HELPER%" echo $brave = Find-InStartMenuInternet 'Brave' 'brave'
>> "%PS_HELPER%" echo if (-not $brave) { $brave = Find-InHtmlProgId 'BraveHTML' 'brave' 'Brave' }
>> "%PS_HELPER%" echo if ($brave) { $browsers += $brave }
>> "%PS_HELPER%" echo.
>> "%PS_HELPER%" echo $edge = Find-InStartMenuInternet 'Edge' 'edge'
>> "%PS_HELPER%" echo if (-not $edge) { $edge = Find-InHtmlProgId 'MSEdgeHTM' 'edge' 'Microsoft Edge' }
>> "%PS_HELPER%" echo if ($edge) { $browsers += $edge }
>> "%PS_HELPER%" echo.
>> "%PS_HELPER%" echo $seen = @{}
>> "%PS_HELPER%" echo $browsers = $browsers ^| Where-Object { if ($seen.ContainsKey($_.Path)) { $false } else { $seen[$_.Path] = $true; $true } }
>> "%PS_HELPER%" echo.
>> "%PS_HELPER%" echo if ($browsers.Count -eq 0) {
>> "%PS_HELPER%" echo     Write-Host "No supported browser detected." -ForegroundColor Red
>> "%PS_HELPER%" echo     Write-Host "Please install Chrome, Edge, or Brave and try again."
>> "%PS_HELPER%" echo     exit 1
>> "%PS_HELPER%" echo }
>> "%PS_HELPER%" echo.
>> "%PS_HELPER%" echo Write-Host "Available browsers: (default marked with *)"
>> "%PS_HELPER%" echo for ($i = 0; $i -lt $browsers.Count; $i++) {
>> "%PS_HELPER%" echo     $b = $browsers[$i]
>> "%PS_HELPER%" echo     $isDefault = ($b.Id -eq $defaultId)
>> "%PS_HELPER%" echo     $marker = if ($isDefault) { '*' } else { ' ' }
>> "%PS_HELPER%" echo     $suffix = if ($isDefault) { ' (default)' } else { '' }
>> "%PS_HELPER%" echo     Write-Host "  [$marker$($i+1)$marker] $($b.Name)$suffix"
>> "%PS_HELPER%" echo }
>> "%PS_HELPER%" echo.
>> "%PS_HELPER%" echo $choice = Read-Host "Choose browser [1-$($browsers.Count)]"
>> "%PS_HELPER%" echo $idx = 0
>> "%PS_HELPER%" echo if ($choice -match '^\d+$') {
>> "%PS_HELPER%" echo     $n = [int]$choice
>> "%PS_HELPER%" echo     if ($n -ge 1 -and $n -le $browsers.Count) {
>> "%PS_HELPER%" echo         $idx = $n - 1
>> "%PS_HELPER%" echo     } else {
>> "%PS_HELPER%" echo         for ($i = 0; $i -lt $browsers.Count; $i++) { if ($browsers[$i].Id -eq $defaultId) { $idx = $i; break } }
>> "%PS_HELPER%" echo     }
>> "%PS_HELPER%" echo } else {
>> "%PS_HELPER%" echo     for ($i = 0; $i -lt $browsers.Count; $i++) { if ($browsers[$i].Id -eq $defaultId) { $idx = $i; break } }
>> "%PS_HELPER%" echo }
>> "%PS_HELPER%" echo.
>> "%PS_HELPER%" echo $sel = $browsers[$idx]
>> "%PS_HELPER%" echo "$($sel.Id)|$($sel.Name)|$($sel.Path)" ^| Out-File "$env:TEMP\fd_selected_browser.txt" -Encoding ASCII

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_HELPER%"
if !errorlevel! neq 0 (
    goto :ErrorPause
)

if not exist "%SELECTED_FILE%" (
    echo ERROR: Browser selection failed.
    goto :ErrorPause
)

for /f "usebackq tokens=1-3 delims=|" %%a in ("%SELECTED_FILE%") do (
    set "BROWSER_NAME=%%a"
    set "BROWSER_DISPLAY=%%b"
    set "BROWSER_EXE=%%c"
)

echo.
echo Selected browser: %BROWSER_DISPLAY%
echo.

REM --------------------------------------------------
REM Download and extract extension
REM --------------------------------------------------
if exist "%ZIP_FILE%" del /F /Q "%ZIP_FILE%" > NUL 2>&1
set "ZIP_TEMP=%ZIP_FILE%.tmp"
if exist "%ZIP_TEMP%" del /F /Q "%ZIP_TEMP%" > NUL 2>&1

echo Downloading latest extension package...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -Uri '%RELEASE_ZIP%' -OutFile '%ZIP_TEMP%' -UseBasicParsing -MaximumRedirection 3 } catch { Write-Error $_.Exception.Message; exit 1 }"

if not exist "%ZIP_TEMP%" (
    echo.
    echo ERROR: Could not download extension.zip.
    echo Please check your internet connection and try again.
    goto :ErrorPause
)

move /Y "%ZIP_TEMP%" "%ZIP_FILE%" > NUL 2>&1

if not exist "%ZIP_FILE%" (
    echo.
    echo ERROR: Could not save extension.zip.
    goto :ErrorPause
)

echo Extracting extension files...
if exist "%EXT_DIR%" rmdir /S /Q "%EXT_DIR%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%INSTALL_DIR%' -Force } catch { Write-Error $_.Exception.Message; exit 1 }"

if not exist "%EXT_DIR%\manifest.json" (
    echo.
    echo ERROR: Extraction failed or manifest.json not found.
    echo Expected folder: %EXT_DIR%
    goto :ErrorPause
)

REM --------------------------------------------------
REM Install updater helper files
REM --------------------------------------------------
echo Installing auto-update helper...
if not exist "%UPDATER_DIR%" mkdir "%UPDATER_DIR%"
copy /Y "%EXT_DIR%\updater\helper.cmd" "%UPDATER_DIR%\helper.cmd" > NUL 2>&1
copy /Y "%EXT_DIR%\updater\helper.ps1" "%UPDATER_DIR%\helper.ps1" > NUL 2>&1
copy /Y "%EXT_DIR%\updater\native-host.json" "%UPDATER_DIR%\native-host.json" > NUL 2>&1

(
echo {
echo   "extensionPath": "%EXT_DIR:\=\\%"
echo }
) > "%UPDATER_DIR%\config.json"

powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $json = Get-Content '%UPDATER_DIR%\native-host.json' | ConvertFrom-Json; $json.path = '%UPDATER_DIR%\helper.cmd'.Replace('\', '\\'); $json | ConvertTo-Json -Compress | Set-Content '%UPDATER_DIR%\native-host.json' -Encoding UTF8 } catch { exit 1 }"

REM --------------------------------------------------
REM Register Native Messaging host for all browsers
REM --------------------------------------------------
echo Registering browser updater integration...
set "HOST_NAME=com.hungerstation.fd_updater"

reg add "HKCU\SOFTWARE\Google\Chrome\NativeMessagingHosts\%HOST_NAME%" /ve /t REG_SZ /d "%UPDATER_DIR%\native-host.json" /f > NUL 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Edge\NativeMessagingHosts\%HOST_NAME%" /ve /t REG_SZ /d "%UPDATER_DIR%\native-host.json" /f > NUL 2>&1
reg add "HKCU\SOFTWARE\BraveSoftware\Brave\NativeMessagingHosts\%HOST_NAME%" /ve /t REG_SZ /d "%UPDATER_DIR%\native-host.json" /f > NUL 2>&1

REM --------------------------------------------------
REM Copy extension path to clipboard and open browser
REM --------------------------------------------------
echo %EXT_DIR% | clip

if "%BROWSER_NAME%"=="edge" (
    set "EXT_URL=edge://extensions/"
) else if "%BROWSER_NAME%"=="brave" (
    set "EXT_URL=brave://extensions/"
) else (
    set "EXT_URL=chrome://extensions/"
)

echo.
echo Opening browser tabs...
echo   - Extensions page ^(enable Developer mode and Load unpacked here^)
echo   - Instructions page
echo.

REM Launch with both URLs. --new-window reliably opens a fresh window even when
REM the browser is already running. The extensions-internal URL must be first.
start "" "%BROWSER_EXE%" --new-window "%EXT_URL%" "%INSTRUCTIONS_URL%"

REM Give the browser time to start before we show final text.
ping -n 4 127.0.0.1 > NUL

REM --------------------------------------------------
REM Final instructions
REM --------------------------------------------------
echo.
echo ============================================================
echo   Installation files ready!
echo ============================================================
echo.
echo Extension folder: %EXT_DIR%
echo.
echo The extension path has been copied to your clipboard.
echo.
echo Next steps:
echo   1. In the Extensions tab, enable DEVELOPER MODE.
echo   2. Click LOAD UNPACKED.
echo   3. Press Ctrl+V, then Enter ^(path already copied^).
echo   4. Click SELECT FOLDER.
echo.
echo After that, the extension auto-updates from the Help ^& Updates tab.
echo.
goto :DonePause

:ErrorPause
echo.
echo ============================================================
echo   Installation Failed
echo ============================================================
:DonePause
echo.
echo Press any key to close...
pause > NUL
endlocal
