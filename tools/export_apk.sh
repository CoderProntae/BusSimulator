#!/usr/bin/env bash
# export_apk.sh — build the Android APK from the command line.
#
# Prerequisites (run on a machine WITH network + the Android SDK):
#   1. Install the Godot 4 Android export templates:
#        Godot Editor -> Editor -> Manage Export Templates -> Download.
#   2. Install the Android build template:
#        Project -> Export -> Android -> Install Android Build Template.
#   3. Ensure `godot` (headless) is on PATH and the ANDROID_SDK_ROOT
#      (or ANDROID_HOME) environment variable points at a valid SDK.
#
# Then:
#   ./tools/export_apk.sh
set -euo pipefail

GODOT="${GODOT:-godot}"
APK="${APK:-BusSimulator.apk}"
PRESET="Android"

echo "[export] Using engine: $GODOT"
echo "[export] Preset: $PRESET  ->  $APK"

# Validate the project can be opened (imports/scenes parse).
"$GODOT" --headless --editor --quit 2>&1 | tail -n 20 || true

# Build the release APK.
"$GODOT" --headless --export-release "$PRESET" "$APK"

if [ -f "$APK" ]; then
    echo "[export] SUCCESS: $APK ($(du -h "$APK" | cut -f1))"
else
    echo "[export] FAILED: $APK was not produced." >&2
    exit 1
fi
