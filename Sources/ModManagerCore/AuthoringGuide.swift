import Foundation

public enum AuthoringGuide {
    public static let markdown = #"""
    # Creating Mac-friendly No Man's Sky mods

    ## The short version

    A Mac-ready mod is an HGPAK archive whose internal paths match the paths expected by the current macOS game build. Put the finished archive in `GAMEDATA/MACOSBANKS/MODS`. Do not replace or rebuild a stock `NMSARC.*.pak`.

    ## Recommended workflow

    1. Start from the **current Mac game assets**. Game updates can change MBIN schemas and archive contents.
    2. Find the stock Mac HGPAK containing the asset you intend to change.
    3. Extract the target asset while preserving its virtual path.
    4. For MBIN data, decompile the current Mac MBIN to a complete editable MXML representation.
    5. Make the smallest intentional edits and keep a source copy of those edits.
    6. Compile against the matching current-game schema.
    7. Package only changed files into an HGPAK, preserving exact paths and letter case.
    8. Add useful metadata: name, author, version, compatible game build, changed asset paths, and dependencies.
    9. Install through this manager, launch, and test on a disposable save before normal play.

    ## Porting a Windows mod

    A Windows `.pak` is not automatically a Mac archive. If it contains complete replacement assets, unpack it and rebuild those files as HGPAK. If it contains sparse EXML edits, apply those edits to a full MXML decompiled from the **current Mac vanilla MBIN**, then compile and package the result. Never treat sparse EXML as a complete Mac asset.

    When two mods edit the same MBIN, their changes must be merged before compilation. Archive order alone cannot safely combine two complete replacements of the same virtual file.

    ## Compatibility checklist

    - Built from the same No Man's Sky update as the player's Mac game
    - HGPAK container, even if the filename uses `.pak`
    - Exact internal virtual paths and case
    - No stock archives modified
    - Changed MBIN paths documented
    - Conflicts with other MBIN edits documented
    - Removal works by deleting the mod archive

    ## Recovery

    If the game stops launching, disable all mods first. If that does not help, restore the executable backup from the Dashboard or ask Steam to verify the game. A Steam update may replace the executable; the manager will flag its fingerprint for review rather than applying an old patch blindly.
    """#
}
