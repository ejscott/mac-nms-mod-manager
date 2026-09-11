# Creating and converting mods for Mac NMS Mod Manager

This guide explains the archive the loader expects, how to build a Mac-native mod, and how to port the common kinds of Windows mods safely.

> [!IMPORTANT]
> The manager currently **installs completed Mac HGPAK archives**. It does not yet perform Windows archive conversion or sparse EXML/MBIN merging for you. Those workflows require external tools until the conversion provider is implemented.

## What the loader accepts

The loader scans:

```text
No Man's Sky.app/
└── Contents/Resources/GAMEDATA/MACOSBANKS/
    ├── MODS/
    │   └── Author.ModName.pak
    └── NMSARC.*.pak
```

The file extension may be `.pak` or `.hgpak`, but the file itself must be a Mac-compatible HGPAK archive. The manager checks the archive header for:

```text
HGPAK\0\0\0
```

Mac HGPAK v2 archives use LZ4 compression. Windows HGPAK v2 archives normally use Zstandard compression, so a Windows `.pak` should not be treated as Mac-ready merely because both platforms use the `.pak` extension.

The patched game mounts `MACOSBANKS/MODS` before the normal stock `MACOSBANKS` mount. A mod can therefore replace an asset at the same virtual path without editing any stock `NMSARC.*.pak` archive.

## Before authoring or converting

1. Update No Man's Sky and launch it once without new mods.
2. Confirm that the manager reports **Mod loader: Ready**.
3. Back up any saves you care about and test gameplay changes on a disposable save.
4. Work from assets extracted from the exact Mac game update you plan to support.
5. Update MBINCompiler or its schema data for that game update before touching MBIN files.

Game updates can change asset paths and MBIN layouts without changing a mod's visible purpose. Reusing an old compiled MBIN is less reliable than rebuilding the change against current vanilla data.

## Choose the correct workflow

| Starting material | Required workflow |
| --- | --- |
| Mac HGPAK with an `HGPAK` header | Install directly and test |
| Loose complete assets | Preserve virtual paths and package as Mac HGPAK/LZ4 |
| Windows HGPAK v2 `.pak` | Extract, then repack its files as Mac HGPAK/LZ4 |
| Older Windows PSARC `.pak` | Extract with a compatible legacy tool, then build Mac HGPAK/LZ4 |
| Complete replacement MBIN | Prefer rebuilding from the current Mac vanilla MBIN; otherwise package only after compatibility testing |
| Sparse EXML/MXML edits | Merge the edits into a full current Mac vanilla MXML, compile to MBIN, then package |
| AMUMSS Lua script | Run the script against matching current assets, inspect the generated files, then follow the appropriate archive/MBIN workflow |

## Workflow A: create a native Mac mod

### 1. Identify the virtual asset path

Find the stock asset you want to replace and record its full path inside the game archives. Examples look like:

```text
METADATA/REALITY/TABLES/...
TEXTURES/UI/...
LANGUAGE/...
```

Virtual paths are not paths to the stock archive on disk. They are the paths stored inside that archive. Preserve every directory component and the filename's letter case.

### 2. Extract the current Mac asset

[HGPAKtool](https://github.com/monkeyman192/HGPAKtool) can list and extract HGPAK archives. Its exact repacking support and flags can vary by version, so check `hgpaktool --help` before running commands.

Typical inspection commands are:

```sh
hgpaktool -L "/path/to/NMSARC.example.pak"
hgpaktool -U -M "/path/to/NMSARC.example.pak" -O "/path/to/extracted"
```

Use filtered extraction when supported instead of unpacking the entire game. Never point experimental repacking commands at the live `MACOSBANKS` directory.

### 3. Edit the asset

- For textures, audio, fonts, or other complete assets, preserve the format expected by the game.
- For MBIN-backed data, decompile the current vanilla MBIN to a complete editable MXML/EXML tree, make the smallest possible change, and compile it with a matching MBINCompiler version.
- Keep a human-readable record of what changed. This makes rebuilding after a game update much easier.

### 4. Stage only changed files

A source tree for a small mod might look like:

```text
MyMod-source/
├── README.md
├── CHANGELOG.md
└── payload/
    └── METADATA/
        └── REALITY/
            └── TABLES/
                └── MYCHANGEDTABLE.MBIN
```

Only the contents below `payload/` belong in the game archive. Project notes and source patches should be shipped beside the archive, not at the root of its virtual filesystem.

### 5. Build a Mac HGPAK

Use a tool that can create or repack HGPAK v2 with Mac-compatible LZ4 compression. If your tool starts from an extraction manifest, make a disposable working copy, remove unchanged payload entries as supported by that tool, update the manifest, and write a **new mod archive**.

Some toolchains expose a repack command similar to:

```sh
hgpaktool -R -Z "/path/to/manifest" -O "/path/to/Author.ModName.pak"
```

Treat this as an example, not a version-independent command. Confirm the installed tool's compression selection and repacking behavior first. Upstream HGPAKtool currently describes repacking as limited.

Do not overwrite a stock archive to produce the mod.

### 6. Validate and install

Before distribution:

```sh
xxd -l 8 "/path/to/Author.ModName.pak"
hgpaktool -L "/path/to/Author.ModName.pak"
```

The first command should show the `HGPAK` magic. The archive listing should contain only the intended game paths. Install the archive through the manager and verify that enable, disable, and uninstall all work before publishing it.

## Workflow B: convert a Windows archive

### 1. Identify its container and contents

Do not rely on the `.pak` extension. Inspect the header and list the archive:

```sh
xxd -l 8 "/path/to/WindowsMod.pak"
hgpaktool -L "/path/to/WindowsMod.pak"
```

An `HGPAK` header indicates the newer container, but its Windows compression still means it may need repacking for Mac. Older PSARC archives require an extractor that supports that format.

### 2. Extract to a disposable directory

Extract the Windows archive away from both the game and your final output. Review all virtual paths and discard installer scripts, Windows executables, or documentation that are not game payloads.

### 3. Classify every payload

- Complete textures, fonts, audio, shaders, and similar platform-compatible assets can usually be staged under the same virtual path.
- Complete MBIN files need version compatibility review.
- EXML/MXML files may be complete decompilations or sparse patches. Do not assume they are complete.
- Native code, DLL injection, Windows launchers, and executable patches are not portable through an asset archive.

### 4. Rebuild instead of renaming

Package the reviewed payload as a new Mac HGPAK/LZ4 archive. Renaming `WindowsMod.pak` does not convert its container or compression.

### 5. Test for platform-specific assets

Even after successful repacking, an asset can still be Windows-specific. Test startup, save loading, the modified feature, multiplayer behavior where relevant, and clean removal.

## Workflow C: port sparse EXML/MBIN edits

Sparse data mods require a merge, not a file copy.

```text
Current Mac vanilla MBIN
          │
          ▼
 Decompile to full MXML
          │
          ▼
 Apply sparse Windows edits ──► report missing paths and conflicts
          │
          ▼
 Compile with matching schema
          │
          ▼
 Package resulting MBIN in Mac HGPAK/LZ4
```

Use this process for each targeted MBIN:

1. Locate the target virtual MBIN path in the current Mac archives.
2. Extract that exact current Mac vanilla MBIN.
3. Decompile it to a full MXML/EXML document with a compatible MBINCompiler.
4. Read the Windows mod as a set of intended changes rather than a complete replacement.
5. Apply those changes to the full Mac tree.
6. Stop on missing nodes, ambiguous selectors, or schema differences; do not silently drop edits.
7. Compile the merged full document back to MBIN.
8. Package it at the original virtual path in the Mac mod archive.

If two mods change the same MBIN, merge both sets of edits into one full current-game document and compile one resulting MBIN. Two complete replacement MBINs cannot be safely combined by archive ordering.

## Conflicts and load order

The loader guarantees that the MODS bank is mounted before stock banks. It does **not** promise a stable conflict order between two mod archives that contain the same virtual path.

Authors should publish the list of modified virtual paths. Users should avoid enabling two mods that replace the same asset unless a compatibility merge is provided.

Recommended archive names are unique and descriptive:

```text
Author.ModName.1.2.0.pak
```

Do not depend on filename prefixes such as `_`, `!`, or `zzz` to resolve conflicts.

## Release checklist

- [ ] Built from the current Mac game assets
- [ ] Starts with the `HGPAK` magic
- [ ] Uses Mac-compatible LZ4 compression
- [ ] Contains only intended payload paths
- [ ] Preserves exact virtual paths and case
- [ ] Does not replace any stock `NMSARC.*.pak`
- [ ] Lists every changed MBIN or major asset path
- [ ] Documents the supported No Man's Sky update
- [ ] Documents dependencies and known conflicts
- [ ] Enables, disables, and uninstalls cleanly
- [ ] Tested on a disposable save
- [ ] Includes source edits or reproducible build notes where licensing permits

## Troubleshooting

### The manager says the file is a Windows archive

The `.pak` extension is not enough. Confirm that the header starts with `HGPAK` and that the archive was rebuilt with Mac-compatible compression.

### The game launches but the mod has no effect

List the archive and compare its virtual path with the current stock asset. Check case, filename, and whether another enabled mod replaces the same path.

### The game crashes while loading

Disable the mod. Recheck MBINCompiler compatibility, the completeness of the merged MXML, platform-specific asset formats, and the archive compression. Do not continue testing on an important save.

### The mod stopped working after an update

Re-extract the current Mac vanilla asset and rebuild the mod. For MBIN changes, repeat the merge against the new vanilla tree rather than recompiling an old full MXML unchanged.

## Related tools and acknowledgements

- [nms-mod-installer-macos](https://github.com/Enki013/nms-mod-installer-macos) by Enki013 inspired this project and documents the Mac HGPAK/LZ4 pipeline.
- [HGPAKtool](https://github.com/monkeyman192/HGPAKtool) reads modern No Man's Sky archives and provides extraction tooling; review its current repacking limitations.
- [MBINCompiler](https://github.com/monkeyman192/MBINCompiler) handles MBIN and EXML/MXML conversion and must match the current game schema.
