# Extension Update Pipeline

This repository hosts public browser extension update artifacts for a private source project. It exists solely so that Chrome can fetch the auto-update manifest (`update.xml`) and the signed extension package (`extension.crx`) over HTTPS without requiring access to the private source repository.

## What is hosted here

| File | Purpose |
|------|---------|
| `update.xml` | Chrome extension update manifest. Points Chrome to the latest `.crx`. |
| `extension.crx` | Signed, installable browser extension package. |

## URLs

- Update manifest: `https://hokagez.github.io/extension-update-pipeline/update.xml`
- Extension package: `https://hokagez.github.io/extension-update-pipeline/extension.crx`

## How it is updated

This repository is updated automatically by a GitHub Actions workflow in the private source repository on every release. Do not edit `extension.crx` or `update.xml` manually.

## Notes

- No source code is stored in this repository.
- No authentication is required to download these files.
- The extension ID is fixed by the signing key and will not change between releases.
