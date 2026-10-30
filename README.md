# GridSnap

An open source alternative to [Divvy](https://mizage.com/divvy/) for macOS. Press a shortcut, a grid appears, drag across the cells you want, and the window snaps there. Save a region as a preset and it becomes a one-keystroke snap.

![Pressing the shortcut, dragging on the grid, and the window following](docs/demo.gif)

- Grid overlay with live preview: the window follows your drag and jumps back if you cancel
- Presets with their own global shortcuts; a Full screen preset on ⌃⌥F comes built in
- Undo the last snap
- Configurable grid size, gap between windows, and independent left, right, top, and bottom screen-edge insets
- Snap the focused window or the one under the cursor
- Works across multiple displays
- Menu bar app, launch at login, no Dock icon
- No network access, no analytics, no accounts

## Requirements

- macOS 14 or later. Tested on macOS 26 and 27; versions before macOS 26 use a frosted panel instead of the glass material.
- Apple Silicon or Intel.
- To build: Xcode Command Line Tools with the macOS 26 SDK or later. No Xcode project, `swiftc` compiles the files directly.

## Install

With Homebrew:

```sh
brew install --cask konieczkow/tap/gridsnap
```

Or download `GridSnap-x.y.z.zip` from the [latest release](https://github.com/konieczkow/gridsnap/releases/latest), unzip it and drag GridSnap to Applications.

On first launch GridSnap asks for **Accessibility**, which it needs to move other apps' windows. The menu bar icon has a **Grant Accessibility…** item that opens the correct pane. On current macOS releases the setting is under System Settings › Device Control and Data Access › Accessibility; earlier releases place it under Privacy & Security. GridSnap picks up the grant without a relaunch.

Or build it yourself:

```sh
git clone https://github.com/konieczkow/gridsnap.git
cd gridsnap
./build.sh install
open /Applications/GridSnap.app
```

## Use

| Action | How |
|---|---|
| Show the grid | ⌃⌥D (change it in Settings) |
| Snap | Click or drag cells and release, or press Return |
| Move the selection | Arrow keys |
| Grow or shrink it | Shift+→ / Shift+↑ grow, Shift+← / Shift+↓ shrink |
| Cancel | Esc, or drag outside the panel and release |
| Dismiss | Click anywhere outside the grid |
| Save a preset | Hold Shift when releasing or pressing Return, or use **+** in Settings |
| Apply a preset | Its shortcut, or the Presets menu |
| Undo last snap | ⌃⌥Z by default, press again to redo |

The target window's current cells are highlighted when the grid opens, so Return alone aligns it to the grid. Thin outlines show other windows snapped during the current run that remain in recognized grid positions.

The grid appears on the display under the cursor and the window snaps to that display, so moving the mouse to another monitor before pressing the shortcut moves the window there. Presets snap to the display the window is already on.

The grid uses consistent gutters so every cell has the same visual size. Its aspect ratio follows the usable screen area after the configured edge insets are applied.

**Settings** (menu bar icon › Settings…) holds both shortcuts, columns and rows, the target rule, and the presets table. **Gap** controls the space between adjacent snapped windows. **Screen edges** independently control the left, right, top, and bottom offsets from the visible screen area, after the menu bar and Dock are excluded. Names and shortcuts are editable in place; **−** removes the selected preset.

When upgrading from a version without separate screen-edge settings, each edge initially inherits the existing gap value. This preserves the previous uniform layout until the four edges are changed independently.

Some apps round or constrain their window dimensions. GridSnap reads the resulting size back and keeps the adjusted window within the configured screen-edge bounds.

## Development

```sh
./build.sh            # builds build/GridSnap.app
./build.sh install    # also copies it to /Applications
```

`Resources/icon.png` is the icon source; regenerate `AppIcon.icns` from it with `iconutil` if you change it.

Files in `Sources/`: `main.swift` startup, `AX.swift` window plumbing, `Grid.swift` overlay, `Presets.swift`, `Hotkeys.swift`, `ShortcutButton.swift` recorder, `SettingsWindow.swift`, `Menu.swift`, `Defaults.swift` stored settings.

macOS ties the Accessibility grant to the app's code signature. The default ad-hoc signature changes with every build, so it requires a new grant after each replacement. For local development, create a self-signed certificate once in Keychain Access (Certificate Assistant › Create a Certificate, type `Code Signing`, name it `GridSnap Dev`). The build script finds that identity automatically. Switching from ad-hoc signing to the certificate may require one final remove and re-add in Accessibility; later builds retain permission as long as they use the same certificate, bundle identifier, and application path. Any other identity works via `CODESIGN_IDENTITY="name" ./build.sh`.

## Known limitations

- Full-screen windows ignore snapping.
- Some apps enforce minimum or quantized window dimensions. GridSnap keeps the adjusted window inside the configured screen-edge bounds, but it may overlap neighbouring cells.

## License

MIT, see [LICENSE](LICENSE).
