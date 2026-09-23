#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift build -c release --arch arm64
binary_dir=$(swift build -c release --arch arm64 --show-bin-path)
app="$PWD/build/Windower.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$binary_dir/Windower" "$app/Contents/MacOS/Windower"
cp Resources/Info.plist "$app/Contents/Info.plist"
cp Resources/Windower.icns "$app/Contents/Resources/Windower.icns"
# Developer ID distribution requires hardened runtime and a secure timestamp.
signing_options=(--force --sign "${CODE_SIGN_IDENTITY:--}")
if [ "${CODE_SIGN_IDENTITY:--}" != "-" ]; then
    signing_options+=(--options runtime --timestamp)
fi
codesign "${signing_options[@]}" --identifier com.ilyakamens.windower "$app"
codesign --verify --strict "$app"
printf 'Built %s\n' "$app"
