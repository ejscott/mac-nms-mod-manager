# Mac NMS Mod Manager

A native macOS mod manager for the Steam version of No Man's Sky. The project is intentionally conservative around executable patching: it fingerprints the universal binary, inspects the ARM64 slice, discovers and validates patch landmarks, creates a restorable backup, applies edits atomically, and verifies code signing.

The verified prototype mounts `MACOSBANKS/MODS` first and then lets the normal `MACOSBANKS` mount continue. Stock archives are never edited.

## Current milestone

- Native SwiftUI app shell with Dashboard, Mods, Authoring Guide, and Settings
- ARM64 Mach-O slice parsing, masked byte-pattern discovery, fingerprints, and patch-state validation
- Known patched-state validation for the verified 4.70 prototype
- Transactional backup/restore and code-signing service
- HGPAK install, enable, disable, and uninstall model
- JSON registry with mod metadata and game-build/patch receipts
- Conversion-provider boundary for future Windows `.pak` and sparse EXML/MBIN support
- Unit tests for pattern matching, Mach-O parsing, and registry behavior

The first milestone does **not** guess how to patch an unknown game update. A newly updated binary is reported as unsupported until a recipe containing validated original and patched signatures is added.

## Run

```sh
swift run MacNMSModManager
```

## Test

```sh
swift test
```

To create a signed app and xattr-free distributable ZIP in `outputs/`, run `scripts/build-app.sh`.

The default game location is:

`~/Library/Application Support/Steam/steamapps/common/No Man's Sky/No Man's Sky.app`

Runtime state is stored under `~/Library/Application Support/Mac NMS Mod Manager/`. Backups are kept outside the game bundle so Steam updates cannot silently replace them.

## Acknowledgements

Inspired by [Enki013's nms-mod-installer-macos](https://github.com/Enki013/nms-mod-installer-macos). Its work on making No Man's Sky mod installation practical on macOS helped inform this project.
