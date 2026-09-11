import Foundation

public enum AuthoringGuide {
    public static let markdown = #"""
    # Creating Mac-friendly No Man's Sky mods

    ## The short version

    A Mac-ready mod is an HGPAK archive whose internal paths match the paths expected by the current macOS game build. Put the finished archive in `GAMEDATA/MACOSBANKS/MODS`. Do not replace or rebuild a stock `NMSARC.*.pak`.

    ## What the loader accepts

    Install a Mac-compatible HGPAK archive using `.pak` or `.hgpak`. The manager checks the file for the `HGPAK` header instead of trusting its extension. Mac archives use LZ4 compression; a Windows `.pak` may use a different container or compression and usually needs rebuilding.

    The archive should contain only changed game files at their exact virtual paths. Use a unique filename such as `Author.ModName.1.2.0.pak`. Do not rely on `_`, `!`, or `zzz` prefixes to resolve conflicts between mods.

    ## Recommended workflow

    1. Start from the **current Mac game assets**. Game updates can change MBIN schemas and archive contents.
    2. Find the stock Mac HGPAK containing the asset you intend to change.
    3. Extract the target asset while preserving its virtual path.
    4. For MBIN data, decompile the current Mac MBIN to a complete editable MXML representation.
    5. Make the smallest intentional edits and keep a source copy of those edits.
    6. Compile against the matching current-game schema.
    7. Package only changed files into an HGPAK v2 archive with Mac-compatible LZ4 compression, preserving exact paths and letter case.
    8. Add useful metadata: name, author, version, compatible game build, changed asset paths, and dependencies.
    9. Install through this manager, launch, and test on a disposable save before normal play.

    ## Porting a Windows mod

    A Windows `.pak` is not automatically a Mac archive. Inspect the header and archive listing; renaming the file is not conversion. If it contains complete replacement assets, unpack it and rebuild those files as Mac HGPAK/LZ4. Older PSARC archives require a compatible legacy extractor.

    If it contains sparse EXML edits, apply those edits to a full MXML decompiled from the **current Mac vanilla MBIN**, then compile and package the result. Stop on missing or ambiguous nodes. Never treat sparse EXML as a complete Mac asset.

    When two mods edit the same MBIN, their changes must be merged before compilation. Archive order alone cannot safely combine two complete replacements of the same virtual file.

    ## Compatibility checker and Lua scripts

    The manager reads the internal file list from Mac HGPAK archives and warns when installed mods replace the same virtual path. An **active conflict** means both overlapping mods are enabled. A **potential conflict** means at least one is disabled.

    AMUMSS `.lua` files are build recipes, not files the game can load. The checker can scan their declared `.MBIN` targets to predict overlap before conversion. This is conservative: Lua can construct paths dynamically, and two scripts targeting the same MBIN may still be mergeable if they edit different values. Use an AMUMSS-aware merge against the current vanilla asset to resolve those cases.

    ## Compatibility checklist

    - Built from the same No Man's Sky update as the player's Mac game
    - HGPAK container, even if the filename uses `.pak`
    - Exact internal virtual paths and case
    - No stock archives modified
    - Changed MBIN paths documented
    - Conflicts with other MBIN edits documented
    - Removal works by deleting the mod archive

    ## Current feature boundary

    This release installs completed Mac HGPAK archives. Automatic Windows archive conversion and sparse EXML/MBIN merging are planned but not enabled yet. Until then, use external extraction, MBIN, and HGPAK packaging tools and validate their current command-line options.

    The complete authoring and conversion guide is available in `docs/MOD_AUTHORING.md` in the project repository.

    ## Recovery

    If the game stops launching, disable all mods first. If that does not help, restore the executable backup from the Dashboard or ask Steam to verify the game. A Steam update may replace the executable; the manager will flag its fingerprint for review rather than applying an old patch blindly.
    """#
}
