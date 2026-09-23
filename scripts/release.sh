#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [ "${1:-}" = "--help" ]; then
    printf '%s\n' 'Usage: CODE_SIGN_IDENTITY="Developer ID Application: …" NOTARYTOOL_PROFILE="windower" ./scripts/release.sh' 'Builds, notarizes, staples, and verifies an arm64 ZIP in build/release/. Does not publish.'
    exit 0
fi
: "${CODE_SIGN_IDENTITY:?Set CODE_SIGN_IDENTITY to your Developer ID Application certificate name}"
: "${NOTARYTOOL_PROFILE:?Set NOTARYTOOL_PROFILE to a notarytool keychain profile name}"
case "$CODE_SIGN_IDENTITY" in
    'Developer ID Application: '*) ;;
    *) printf 'Use a Developer ID Application identity for public distribution.\n' >&2; exit 1 ;;
esac
./scripts/build.sh
app="$PWD/build/Windower.app"
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app/Contents/Info.plist")
if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    printf 'CFBundleShortVersionString must be a semantic version such as 0.1.0.\n' >&2
    exit 1
fi
release_dir="$PWD/build/release"
mkdir -p "$release_dir"
staging=$(mktemp -d "$PWD/build/notarize.XXXXXX")
trap 'rm -rf "$staging"' EXIT
# Verify the actual signer, not only the environment variable.
codesign -dv --verbose=4 "$app" 2> "$staging/signature.txt"
if ! /usr/bin/grep -q '^Authority=Developer ID Application:' "$staging/signature.txt"; then
    printf 'The app is not signed with a Developer ID Application certificate.\n' >&2
    exit 1
fi
ditto -c -k --keepParent "$app" "$staging/Windower.zip"
xcrun notarytool submit "$staging/Windower.zip" --keychain-profile "$NOTARYTOOL_PROFILE" --wait
xcrun stapler staple "$app"
xcrun stapler validate "$app"
codesign --verify --strict --verbose=2 "$app"
spctl --assess --type execute --verbose=2 "$app"
# Package again after stapling so the download includes the notarization ticket.
archive="Windower-${version}-arm64.zip"
ditto -c -k --keepParent "$app" "$staging/$archive"
mv "$staging/$archive" "$release_dir/$archive"
(cd "$release_dir" && shasum -a 256 "$archive" > "$archive.sha256")
printf 'Verified release: %s/%s\n' "$release_dir" "$archive"
