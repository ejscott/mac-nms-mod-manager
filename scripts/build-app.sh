#!/bin/zsh
set -euo pipefail

PROJECT_ROOT=${0:A:h:h}
BUILD_ROOT="$PROJECT_ROOT/work/release-build"
APP_ROOT="$PROJECT_ROOT/outputs/Mac NMS Mod Manager.app"
ARCHIVE_ROOT="$PROJECT_ROOT/outputs/Mac NMS Mod Manager.zip"

env CLANG_MODULE_CACHE_PATH="$PROJECT_ROOT/work/module-cache" \
    SWIFTPM_MODULECACHE_OVERRIDE="$PROJECT_ROOT/work/module-cache" \
    swift build -c release --scratch-path "$BUILD_ROOT"

mkdir -p "$APP_ROOT/Contents/MacOS"
cp "$BUILD_ROOT/arm64-apple-macosx/release/MacNMSModManager" "$APP_ROOT/Contents/MacOS/MacNMSModManager"
cp "$PROJECT_ROOT/Resources/Info.plist" "$APP_ROOT/Contents/Info.plist"
xattr -cr "$APP_ROOT"
codesign --force --deep --sign - "$APP_ROOT"
codesign --verify --deep --strict "$APP_ROOT"
rm -f "$ARCHIVE_ROOT"
ditto -c -k --norsrc --keepParent "$APP_ROOT" "$ARCHIVE_ROOT"

echo "$ARCHIVE_ROOT"
