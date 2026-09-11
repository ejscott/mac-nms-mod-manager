# Converted mod catalog

This catalog records No Man's Sky mods that have been evaluated or converted for the Mac additive mod loader. Its primary purpose is to help users discover compatibility and to make conversions reproducible without taking distribution or credit away from the original creators.

## Current tracker

| Mod | Conversion status | In-game test | Redistribution | Record |
| --- | --- | --- | --- | --- |
| [Instant Refiners](https://www.nexusmods.com/nomanssky/mods/2016) | Verified | Passed | Prohibited by source permissions | [JSON](mods/instant-refiners.json) |

## Publishing policy

The default catalog entry contains metadata, creator credit, a link to the creator's original download page, compatibility results, conflict paths, source hashes, and a conversion recipe. It does **not** contain a mirrored mod archive.

A converted archive may be linked or hosted only when all of the following are recorded:

1. The original creator and contributors are prominently credited.
2. The creator's license or explicit written permission allows redistribution of the converted work.
3. A public URL or other durable record of that permission is included in the entry.
4. Distribution complies with the rules of the original hosting platform and the game.
5. The archive contains no unnecessary stock game assets.

Credit is always required, but credit alone is not permission. When permission is unknown, the entry must use `permission_required`, set `artifactPublished` to `false`, and direct users to the creator's original download.

For Nexus-hosted mods, review the permissions displayed on the individual mod page as well as the current [Nexus Mods Terms of Service](https://help.nexusmods.com/article/18-terms-of-service). If the page prohibits re-uploading, the catalog must use `prohibited` even when local conversion is technically successful.

Whenever practical, prefer a local converter that consumes the user's legitimately obtained original mod plus their installed Mac game assets. This preserves the creator's download traffic and avoids redistributing a compiled table derived from stock assets.

## Status meanings

- `researching`: the input format or affected assets are still being identified.
- `convertible`: a conversion route is known but has not completed an in-game test.
- `verified`: the converted output passed structural checks and an in-game test.
- `blocked`: conversion currently fails or depends on unsupported platform-specific content.
- `incompatible`: the mod cannot work through this asset loader.

## Redistribution meanings

- `permission_required`: no qualifying permission has been found.
- `allowed_by_license`: a published license expressly allows redistribution and modification.
- `explicit_permission`: the creator granted specific permission for the converted archive.
- `author_hosted`: the creator publishes the Mac version; the catalog links to it.
- `prohibited`: the creator or license forbids redistribution.

## Adding an entry

1. Copy the original download URL and creator names exactly.
2. Record the original file version, declared game version, and SHA-256 hashes.
3. Identify every virtual game path affected by the mod.
4. Describe the conversion as data and operations, not by copying unlicensed source code.
5. Validate the finished HGPAK header, compression, contents, and round-trip extraction.
6. Test enable, disable, and gameplay behavior on a disposable save.
7. Record redistribution status independently from conversion status.

Entries are validated against [`schema.json`](schema.json).
