#!/bin/bash
set -euo pipefail
IPA="${1:-SafeCache.tipa}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

unzip -q "$IPA" -d "$TMP"
APP="$TMP/Payload/SafeCache.app"
BIN="$APP/SafeCache"
PLIST="$APP/Info.plist"

[ -d "$APP" ] || { echo "ERROR: app bundle missing"; exit 1; }
[ -f "$PLIST" ] || { echo "ERROR: Info.plist missing"; exit 1; }
[ -x "$BIN" ] || { echo "ERROR: executable missing/not executable"; exit 1; }

/usr/bin/plutil -lint "$PLIST"
BID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$PLIST")
EXE=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$PLIST")
VER=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST")
[ "$BID" = "com.safecache.cleaner" ] || { echo "ERROR: unexpected bundle id $BID"; exit 1; }
[ "$EXE" = "SafeCache" ] || { echo "ERROR: unexpected executable $EXE"; exit 1; }
[ "$VER" = "0.4.1" ] || { echo "ERROR: unexpected version $VER"; exit 1; }

for icon in AppIcon60x60@2x.png AppIcon60x60@3x.png AppIcon40x40@2x.png; do
    [ -f "$APP/$icon" ] || { echo "ERROR: icon not copied to bundle root: $icon"; find "$APP" -maxdepth 2 -type f -print; exit 1; }
done

file "$BIN" | grep -q 'arm64' || { echo "ERROR: arm64 slice not found"; file "$BIN"; exit 1; }

ENTS="$(ldid -e "$BIN")"
printf '%s\n' "$ENTS" | grep -q 'com.apple.private.security.no-sandbox' || { echo "ERROR: no-sandbox entitlement missing"; exit 1; }
for banned in 'platform-application' 'com.apple.private.persona-mgmt' 'com.apple.private.skip-library-validation' 'dynamic-codesigning' 'com.apple.private.cs.debugger'; do
    if printf '%s\n' "$ENTS" | grep -q "$banned"; then
        echo "ERROR: banned/unwanted entitlement found: $banned"
        exit 1
    fi
done

echo "PASS: IPA structure, icon resources, arm64 executable, Info.plist and entitlements verified"
