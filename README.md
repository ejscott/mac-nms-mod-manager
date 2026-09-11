# Mac NMS Mod Manager

Mac NMS Mod Manager patches the Apple Silicon version of No Man's Sky so the game can load mods from its own `MACOSBANKS/MODS` folder. After the patch is enabled, Mac-compatible mods can be installed, enabled, disabled, and removed without changing the game's original asset archives.

This takes a different approach from [Enki013's nms-mod-installer-macos](https://github.com/Enki013/nms-mod-installer-macos). That project made Mac modding possible by unpacking and rebuilding the stock game archives. This project builds on that inspiration by restoring a separate, native in-game mod folder: mods load first, the normal game files load afterward, and the stock archives stay untouched.

The manager backs up the original executable, handles code signing, detects game updates, and refuses to apply an old patch to an unrecognized game build.

## Current milestone

- Native SwiftUI app shell with Dashboard, Mods, Authoring Guide, and Settings
- ARM64 Mach-O slice parsing, masked byte-pattern discovery, fingerprints, and patch-state validation
- Known patched-state validation for the verified 4.70 prototype
- Transactional backup/restore and code-signing service
- HGPAK install, enable, disable, and uninstall model
- Reversible mod toggles that retain disabled archives and their metadata outside the game's active `MODS` folder
- JSON registry with mod metadata and game-build/patch receipts
- Conversion-provider boundary for future Windows `.pak` and sparse EXML/MBIN support
- Unit tests for pattern matching, Mach-O parsing, and registry behavior

## Creating and converting mods

See the [Mac-friendly mod authoring and conversion guide](docs/MOD_AUTHORING.md) for:

- packaging loose assets as a native Mac HGPAK;
- converting Windows HGPAK or legacy PSARC archives;
- correctly porting sparse EXML/MBIN mods against current Mac vanilla assets;
- archive layout, naming, conflict handling, testing, and release checklists.

The manager currently installs completed Mac HGPAK archives. Automatic Windows archive conversion and sparse EXML/MBIN merging are planned; the guide describes the manual workflow and clearly marks the steps that still require external tools.

## Mod compatibility and convertibility

| Mod | Original creators | Source format | Conversion | Mac test | Redistribution | Known conflict |
| --- | --- | --- | --- | --- | --- | --- |
| [Instant Refiners](https://www.nexusmods.com/nomanssky/mods/2016) | wim95, NooBzPoWaH, Babscoole, BladehawkeX | AMUMSS Lua + EXML | ✅ Verified convertible | ✅ Passed | ⛔ Do not redistribute | `NMS_REALITY_GCRECIPETABLE.MBIN` |

Status guide:

- ✅ **Verified convertible** — converted, structurally validated, and tested in the Mac game.
- 🟡 **Convertible** — a conversion path is known but still needs an in-game test.
- 🔎 **Researching** — the archive or affected assets are still being analyzed.
- ❌ **Incompatible** — depends on Windows-native code or another feature this loader cannot provide.

The detailed [`catalog`](catalog/README.md) stores creator credits, original download links, source hashes, conversion recipes, affected game paths, test results, conflicts, and redistribution permissions. The machine-readable [Instant Refiners record](catalog/mods/instant-refiners.json) is the first verified entry.

Catalog inclusion never grants permission to mirror a mod. Converted archives are only published when the creator's license or explicit permission allows it; otherwise the catalog links users to the original download and records convertibility only.

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
