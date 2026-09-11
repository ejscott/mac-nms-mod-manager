# Technical design

## Runtime patch

The ARM64 prototype changes the bank-loading sequence to:

1. The normal `MACOSBANKS` selector remains `Data + 0x469c`.
2. A hook in `cTkFileSystem::Construct` calls a repurposed, unused `cGcUIGlobals::ReadModFromFolder` body.
3. That stub enumerates `Data + 0x479c` (`MACOSBANKS/MODS`) and calls `MountAllArchives`.
4. Control returns to `Construct`, which mounts the already enumerated stock archives.

Verified virtual addresses in the prototype are documentation anchors, not update-stable inputs:

| Landmark | Verified address |
| --- | ---: |
| repurposed stub | `0x101d026b0` |
| stock selector | `0x1030d1078` |
| hook | `0x1030d109c` |
| `EnumerateBanks` | `0x1030d11bc` |
| `MountAllArchives` | `0x1030d13b8` |

The patch engine operates on the ARM64 slice inside the universal executable. Recipes use masked instruction patterns, expected match counts, and contextual validation. A recipe may additionally constrain the whole-file and ARM64-slice SHA-256. An address is accepted only as a diagnostic hint after the surrounding pattern validates.

## Safety transaction

Patching follows a prepare/commit/verify transaction:

1. Resolve the game and executable from `Info.plist`.
2. Compute universal and ARM64 fingerprints.
3. Classify as vanilla-supported, patched-supported, changed/unsupported, or invalid.
4. Create a timestamped, checksummed backup outside the app bundle.
5. Build a candidate copy, apply all edits, and validate its patched signatures.
6. Atomically replace the executable while preserving mode/ownership where permitted.
7. Ad-hoc sign the game bundle and run strict signature verification.
8. Save a patch receipt containing before/after fingerprints and recipe version.

On any failure before commit, the game is untouched. On a post-commit verification failure, restore uses the checksummed backup and signs again.

## Update detection

The registry records the executable fingerprint seen after a successful patch. On launch and before every mod-changing action the manager compares the current fingerprint and recipe classification. A Steam update therefore produces a prominent “needs review” state even if the app version in `Info.plist` did not change.

## Mods

Enabled archives live in `MACOSBANKS/MODS`. Disabled archives live in the manager's data directory. Install is copy-then-rename and never writes a stock `NMSARC.*.pak`. The registry records a stable ID, original source, managed filename, checksum, author/version metadata, dates, and enabled state.

## Conversion boundary

`ModConversionProvider` separates import classification from conversion. The built-in provider accepts Mac HGPAK archives now. Future providers can:

- unpack a Windows PSARC `.pak` and rebuild HGPAK;
- extract the current Mac vanilla MBIN from the archive index;
- decompile it to full MXML;
- merge sparse EXML edits with conflict reporting;
- compile MBIN and package a generated HGPAK;
- merge multiple mods targeting the same MBIN into one generated output.

Conversion output still enters the same registry/install transaction, so patching and stock archives remain independent.
