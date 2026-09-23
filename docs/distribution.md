# Distributing Windower

Windower uses Accessibility APIs to control windows in other applications. Its
current implementation is incompatible with App Sandbox. Mac App Store apps
must be sandboxed, so the supported distribution route is a Developer ID-signed,
notarized download from the website.

Sources: [Apple App Sandbox restrictions](https://developer.apple.com/documentation/security/protecting-user-data-with-app-sandbox),
[App Review guideline 2.4.5](https://developer.apple.com/app-store/review/guidelines/#hardware-compatibility).

## One-time Apple setup

1. Enroll in the [Apple Developer Program](https://developer.apple.com/programs/enroll/),
   or use an existing membership. Apple lists USD 99 per year, with regional pricing.
2. Create and install a **Developer ID Application** certificate and its private
   key using Xcode → Settings → Accounts → Manage Certificates, or the developer
   account's Certificates section. `security find-identity -v -p codesigning`
   lists available identities. A development or Mac App Distribution certificate
   is not the right identity for direct downloads.
3. Store notarization credentials in Keychain with
   `xcrun notarytool store-credentials windower`. Follow its interactive prompts;
   an Apple ID login uses an app-specific password and your Team ID. Never commit
   passwords, API keys, signing certificates, or private keys to this repository.

See Apple's [Developer ID instructions](https://developer.apple.com/developer-id/)
and [notarization requirements](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

## Build a public release

Update `CFBundleShortVersionString` and increment `CFBundleVersion` in
`Resources/Info.plist`. Run the tests, then use your installed certificate name:

```sh
swift test
CODE_SIGN_IDENTITY='Developer ID Application: YOUR NAME (TEAMID)' \
NOTARYTOOL_PROFILE=windower ./scripts/release.sh
```

The script enables hardened runtime, signs with a secure timestamp, submits to
Apple, staples the accepted ticket to the app, verifies Gatekeeper assessment,
and creates a ZIP plus SHA-256 checksum in `build/release/`. It does not publish
anything. If notarization fails, use `xcrun notarytool log` with the submission ID
and keychain profile to inspect Apple's report.

Test the downloaded archive on a separate Apple Silicon Mac or clean user account:
installation, Accessibility setup, all six shortcuts, menu actions, login startup,
and multiple displays. App-imposed minimum sizes still apply. Do not publish the
ad-hoc CI artifact as a public release: it is only a development build.

## Publish the verified download

After the verified release has been reviewed, create a GitHub release from the
commit used for the build. For version 0.1.0, for example:

```sh
gh release create v0.1.0 --target "$(git rev-parse HEAD)" \
  --title 'Windower 0.1.0' --notes-file release-notes.md \
  build/release/Windower-0.1.0-arm64.zip \
  build/release/Windower-0.1.0-arm64.zip.sha256
```

Write `release-notes.md` before running this command. Once the release exists,
update `website/release.json` with its exact version and asset URL:

```json
{
  "version": "0.1.0",
  "url": "https://github.com/ilyakamens/windower/releases/download/v0.1.0/Windower-0.1.0-arm64.zip"
}
```

The site enables its download link only with a configured release. Until then it
shows the actual unavailable status and links to source-build instructions.

## Website

`website/` is a standalone static site. It needs no JavaScript package manager,
server, or build step. All asset paths are relative, so it works at a domain root
or a GitHub Pages project path. Preview it with:

```sh
python3 -m http.server 8080 --bind 127.0.0.1 --directory website
```

The GitHub Pages site is https://ilyakamens.github.io/windower/. The
`.github/workflows/website.yaml` workflow publishes only `website/` when its
files change on `main`, or when run manually. Pages must use GitHub Actions as
its publishing source in the repository settings.

For another static host, set its publish directory to `website` and leave the
build command empty. The download itself can remain on GitHub Releases.
