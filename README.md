# Extension Update Pipeline

This repository hosts public browser extension update artifacts for a private source project. It exists solely so that Chromium-based browsers can fetch the auto-update manifest (`update.xml`) and the signed extension package over HTTPS.

## What is hosted here

| File | Purpose |
|------|---------|
| `update.xml` | Extension update manifest for auto-updates. |
| `install-policy-chrome.bat` | Windows registry policy installer for **Chrome**. |
| `install-policy-edge.bat` | Windows registry policy installer for **Microsoft Edge**. |
| `install-policy-brave.bat` | Windows registry policy installer for **Brave**. |
| `policy-templates/` | Official Brave `.admx` and `.adml` policy templates (optional advanced method). |

## Installation

### Quick Install (All Browsers)

1. Choose the `.bat` file for your browser:
   - **Chrome**: `install-policy-chrome.bat`
   - **Edge**: `install-policy-edge.bat`
   - **Brave**: `install-policy-brave.bat`

2. Right-click the `.bat` file and select **"Run as administrator"**.

3. Follow the on-screen instructions. The script will:
   - Set Windows registry policies to auto-install the extension
   - Display a green confirmation message
   - Instruct you to fully restart the browser

4. **Fully restart the browser:**
   - Close all browser windows
   - Open **Task Manager** and end any remaining processes (e.g., `chrome.exe`, `msedge.exe`, `brave.exe`)
   - Reopen the browser
   - The extension will auto-install and be automatically enabled ✅

### URLs

- Update manifest: `https://hokagez.github.io/extension-update-pipeline/update.xml`
- Landing page: `https://hokagez.github.io/extension-update-pipeline/`

## Brave-Specific Notes

Brave supports Chromium's enterprise policies but has limited enforcement on extension auto-enabling compared to Chrome/Edge. If the `.bat` file doesn't work:

**Option 1: Use Official Policy Templates (Advanced)**

1. Download `policy-templates/brave.admx` and `policy-templates/en-US/brave.adml`
2. Copy to your Windows Policy Definitions folder:
   - `brave.admx` → `%systemroot%\PolicyDefinitions\`
   - `brave.adml` → `%systemroot%\PolicyDefinitions\en-US\`
3. Open `gpedit.msc` (Group Policy Editor)
4. Navigate to: **Computer Configuration > Administrative Templates > Brave > Extensions**
5. Configure:
   - **ExtensionInstallForcelist**: `jmpppkgmikaopefjkngeiffakoojkcjm;https://hokagez.github.io/extension-update-pipeline/update.xml`
   - **ExtensionInstallAllowlist**: `jmpppkgmikaopefjkngeiffakoojkcjm`
6. Restart Brave fully (see step 4 above)

**Option 2: Manual Registry (Advanced)**

Run these commands as Administrator (replace values as needed):
```batch
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave\ExtensionInstallForcelist" /v 1 /t REG_SZ /d "jmpppkgmikaopefjkngeiffakoojkcjm;https://hokagez.github.io/extension-update-pipeline/update.xml" /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave\ExtensionInstallAllowlist" /v 1 /t REG_SZ /d "jmpppkgmikaopefjkngeiffakoojkcjm" /f
```

Then fully restart Brave.

## How it is updated

This repository is updated automatically by a GitHub Actions workflow in the private source repository on every release. Do not edit `update.xml` manually.

## Notes

- No source code is stored in this repository.
- No authentication is required to download these files.
- The extension ID is fixed by the signing key: `jmpppkgmikaopefjkngeiffakoojkcjm`
- Chrome and Edge have full enterprise policy support for extensions.
- Brave has limited but supported enterprise policy enforcement.
