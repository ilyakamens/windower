# Windower

A native Apple Silicon menu bar app for moving and resizing the focused window.
Requires macOS 13 or later. No Rosetta or third-party runtime.

| Shortcut | Action |
| --- | --- |
| Control–Option–Command–← | Left half |
| Control–Option–Command–→ | Right half |
| Control–Option–Command–↑ | Top half |
| Control–Option–Command–↓ | Bottom half |
| Control–Option–Command–C | Center at 75% of screen width and height |
| Control–Option–Command–M | Fill screen |

Actions use the display containing most of the window and respect the menu bar
and Dock. Fill Screen resizes the window in the current desktop; it does not enter
macOS full screen. All actions are also available from the menu bar icon.

## Install

With Xcode or its Command Line Tools installed:

```sh
./scripts/install.sh
```

This builds an arm64 app, installs it at `~/Applications/Windower.app`, and opens it.
Grant **Windower** access in **System Settings → Privacy & Security → Accessibility**.
The menu's **Enable Accessibility…** item opens that pane. Permission takes effect
without restarting the app.

Launch at Login is enabled on first launch. The menu toggle controls it afterward;
if macOS requires approval, use **Approve Launch at Login…**. Startup occurs when
you log in, when windows are available, rather than before login.

Quit SizeUp or disable any conflicting shortcuts before running Windower. Quit
Windower from its menu before reinstalling.

## Development

```sh
swift test
./scripts/build.sh
```

The app icon is vector artwork in `scripts/generate-icon.swift`. To regenerate its
committed macOS icon resource:

```sh
xcrun swift scripts/generate-icon.swift
iconutil -c icns build/Windower.iconset -o Resources/Windower.icns
```

Open `Package.swift` in Xcode to edit. Run the packaged app rather than the bare
Swift executable when testing Accessibility and login items.

The build uses ad-hoc signing for local use. A rebuild can require removing and
re-adding Windower in Accessibility settings. To sign with an installed Developer
ID identity, set `CODE_SIGN_IDENTITY` when running the build or install script.
Distribution to other Macs would additionally need notarization.

## Website and public releases

The [companion site](https://ilyakamens.github.io/windower/) lives in `website/`
and uses plain HTML, CSS, and JavaScript. Changes to it on `main` deploy through
the GitHub Pages workflow.
Preview it with `python3 -m http.server 8080 --bind 127.0.0.1 --directory website`.
`website/release.json` controls the download link; it stays unavailable until a
public release is configured.

See [distribution instructions](docs/distribution.md) for Developer ID setup,
notarization, GitHub Releases, and website hosting. `scripts/release.sh` creates a
verified, notarized ZIP once signing credentials are configured. It does not
publish automatically. The current window-management implementation cannot run
inside the sandbox required by the Mac App Store.

## Limits

Apps can impose minimum window sizes, fixed aspect ratios, or resize increments;
their constraints take precedence over the requested dimensions. Full-screen,
nonresizable, and apps without standard Accessibility windows are unsupported.
Errors appear in the menu and its icon tooltip. No screen recording or input
monitoring permission is required.
