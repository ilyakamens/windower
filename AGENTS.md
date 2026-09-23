# Windower

Native macOS menu bar window manager, built with Swift and AppKit. Requires macOS
13 or later. Shipping builds target arm64 (Apple Silicon), with no external dependencies.

## Workflow

- Use `mise exec -- sd next`, `sd show <id>`, `sd start <id>`, and `sd done <id>` for tasks.
- Preserve Git history and unrelated work. Origin is https://github.com/ilyakamens/windower.
- Keep UI copy minimal: controls, errors, and actual status only.
- Use public macOS APIs. Accessibility access must be granted by the user.
- Do not add a web runtime, package manager dependencies, or a background daemon.

## Structure

- `Sources/WindowGeometry`: pure display selection and layout calculations, using top-left coordinates.
- `Sources/Windower`: menu bar app, Carbon global hotkeys, Accessibility window operations, login item.
- `Tests/WindowGeometryTests`: geometry regression tests.
- `Resources/Info.plist`: app metadata; LSUIElement keeps the app out of the Dock.
- `scripts/build.sh`: build and sign an arm64 app bundle.
- `scripts/install.sh`: install into ~/Applications and launch.

## Validation

Run `swift test` and `./scripts/build.sh`. For changes to native integrations, also
verify the installed app manually with Accessibility enabled. Cover all shortcuts,
menu actions, multiple displays, minimum-size windows, and login-item status when
relevant. Do not claim runtime verification when macOS permission prevents it.
