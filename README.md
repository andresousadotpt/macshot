# Macshot

A native macOS menu bar app for **region screenshots** and **region GIF recording**. Select an area with a frozen, dimmed overlay and crosshair cursor — similar to the built-in screenshot tool — then copy the result to your clipboard.

## Features

- **Region screenshot** — freezes the screen, dims the overlay, crosshair cursor, drag to select, PNG copied to clipboard
- **Region GIF** — same selection UI, then records the live region and copies an animated GIF to clipboard
- **Multi-display** — overlay on every connected display
- **Settings** — dim opacity, GIF FPS, max recording duration, launch at login, permission status

## Hotkeys

| Action | Default hotkey |
| ------ | -------------- |
| Screenshot | `⌘⇧4` |
| Record GIF | `⌘⇧3` |

While Macshot is running, these replace the matching **macOS screenshot shortcuts**. Hotkeys are configurable in **Settings**. **Accessibility** permission is required for global hotkey interception. You can also trigger captures from the menu bar icon.

## Requirements

- macOS 14 (Sonoma) or later
- **Accessibility** permission (required to override global screenshot hotkeys)
- **Accessibility**, **Screen Recording**, and **Notifications** — Macshot requests these shortly after first launch

## Install

### Build from source (recommended)

```bash
git clone https://github.com/andresousadotpt/macshot.git
cd macshot
make app
open dist/macshot.app
```

### Homebrew

```bash
brew tap andresousadotpt/tap
brew install --cask macshot
```

### GitHub Release

Download `macshot-{version}.zip` from [Releases](https://github.com/andresousadotpt/macshot/releases), unzip, and open the app.

If macOS blocks launch the first time, right-click the app → **Open**, or use System Settings → Privacy & Security → **Open Anyway**.

## Usage

1. Launch Macshot — it runs as a menu bar agent (no Dock icon) and starts automatically at login.
2. Press `⌘⇧4` or choose **Capture Screenshot** from the menu.
3. Drag a rectangle on the frozen overlay; release to copy PNG to clipboard.
4. Press `⌘⇧3` or choose **Record GIF** to select a region, then click **Stop** on the HUD when done.
5. Open **Settings** from the menu to customize hotkeys, dim opacity, GIF FPS, max duration, and launch at login.

Press `Esc` during region selection or GIF recording to cancel (recording is discarded, nothing copied).

## Development

```bash
make build    # debug build
make run      # build and launch via swift run
make test     # unit tests (requires full Xcode)
make app      # release .app in ./dist/
make clean    # remove build artifacts
```

### Project layout

| Target | Purpose |
| ------ | ------- |
| **MacshotCore** | Models, image/GIF encoding, settings — no UI imports |
| **Macshot** | SwiftUI shell, AppKit overlays, ScreenCaptureKit bridges |

AI agents should read [AGENTS.md](AGENTS.md) for architecture and conventions.

## Releasing

Version lives in `packaging/Info.plist` (`CFBundleShortVersionString`). Push to `main` and GitHub Actions will build, publish a release zip, and update the Homebrew cask.

```bash
make bump-version BUMP=minor   # or BUMP=major
git add packaging/Info.plist && git commit -m "chore: bump version to X.Y.Z"
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

| Document | Purpose |
| -------- | ------- |
| [AGENTS.md](AGENTS.md) | Architecture and agent conventions |
| [SUPPORT.md](SUPPORT.md) | Help and FAQs |
| [SECURITY.md](SECURITY.md) | Report vulnerabilities privately |
| [CHANGELOG.md](CHANGELOG.md) | Version history |

## License

MIT — see [LICENSE](LICENSE).
