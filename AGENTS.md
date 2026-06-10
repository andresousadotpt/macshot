# AGENTS.md

Instructions for AI coding agents working on **Macshot**.

## Project overview

- **What this is:** A native macOS menu bar app for region screenshots and GIF recording.
- **Platform:** macOS 14 (Sonoma) or later. Swift Package Manager project; no Xcode project file.
- **License:** MIT
- **Repo:** https://github.com/andresousadotpt/macshot

## App identity (`packaging/app.env`)

```bash
APP_BUNDLE_NAME=macshot
APP_EXECUTABLE=Macshot
APP_PACKAGE=Macshot
APP_CORE=MacshotCore
APP_DISPLAY_NAME=Macshot
APP_BUNDLE_ID=com.macshot
APP_SUPPORT_DIR=Macshot
GITHUB_OWNER=andresousadotpt
GITHUB_REPO=macshot
CASK_NAME=macshot
HOMEBREW_TAP=andresousadotpt/homebrew-tap
```

**Do not rename** `Makefile`, `packaging/build-app.sh`, `packaging/bump-version.sh`, or workflow files — they read from `app.env`.

## Architecture

Two Swift targets with strict separation of concerns:

| Target | Role | Depends on |
|--------|------|------------|
| **MacshotCore** | Models, image/GIF encoding, settings persistence | Foundation, CoreGraphics, ImageIO |
| **Macshot** | SwiftUI shell, AppKit overlays, ScreenCaptureKit bridges | MacshotCore |

```
Sources/
├── MacshotCore/
│   ├── Models/         # CaptureRect, AppSettings, DisplaySnapshot
│   └── Services/       # DisplaySnapshotService, ImageCropper, GIFEncoder, SettingsStore
└── Macshot/
    ├── MacshotApp.swift
    ├── ViewModels/     # CaptureCoordinator, SettingsViewModel
    ├── Views/          # SettingsView
    ├── Support/        # Region overlay, hotkeys, clipboard, GIF capture bridges
    └── Resources/
```

### Capture flows

1. **Screenshot:** Hotkey → freeze all displays (`CGDisplayCreateImage`) → per-display overlay → crop frozen image → PNG → clipboard.
2. **GIF:** Hotkey → same selection overlay → `SCStream` with `sourceRect` → frame buffer → `GIFEncoder` → clipboard.

### Key design choices

- **View models** use `@MainActor @Observable` (Observation framework, not Combine).
- **Persistence** uses `actor` types (`SettingsStore`, `GIFRecorder`) for thread-safe state.
- **Settings** live at `~/Library/Application Support/Macshot/settings.json` (atomic writes).
- **Menu bar agent:** `LSUIElement = true` in `packaging/Info.plist` (no Dock icon).
- **Global hotkeys:** CGEvent tap (`headInsertEventTap`) intercepts and suppresses system shortcuts — defaults `⌘⇧4` (screenshot) / `⌘⇧3` (GIF); requires Accessibility; user-configurable via `HotkeyBinding` in settings.

### UI stack

- **SwiftUI** for menu bar and settings.
- **AppKit** for region selection overlay, crosshair cursor, recording HUD.
- **ScreenCaptureKit** for live GIF region capture (requires Screen Recording permission).

## Build and run

```bash
make build    # swift build (debug)
make run      # build + swift run
make test     # swift test — requires full Xcode
make app      # release .app bundle in ./dist/
make clean    # remove .build/ and dist/
```

### Important runtime gotchas

1. **Packaged app required** for full menu bar / permission behavior — use `make app`, not only `swift run`.
2. **Screen Recording permission** required for GIF; screenshots use display capture at selection time.
3. **Version source of truth:** `packaging/Info.plist` (`CFBundleShortVersionString`).

## Testing

Tests live in `Tests/MacshotCoreTests/` and target **MacshotCore only**. UI and AppKit code is not unit-tested.

```bash
make test
swift test --filter MacshotCoreTests.testMarketingVersionIsNonEmpty
```

## Code style and conventions

- **Swift tools version:** 6.0 (`Package.swift`).
- **Minimum deployment:** macOS 14.
- Prefer `Sendable`, `Codable`, and `Equatable` on models in MacshotCore.
- Use `public` on MacshotCore types consumed by the app target.
- Do not add UI imports (`SwiftUI`, `AppKit`) to MacshotCore.
- New **models/settings** → `Sources/MacshotCore/Models/`
- New **file I/O or encoding** → `Sources/MacshotCore/Services/`
- New **screens** → `Sources/Macshot/Views/`
- New **AppKit bridges** → `Sources/Macshot/Support/`

## Packaging and release

See README.md. Releases are ad-hoc signed via CI on push to `main`.

## Git and PR guidelines

- **Do not commit** unless explicitly asked.
- **Do not push** unless explicitly asked.
- Run `make build` before finishing; run `make test` when MacshotCore logic changed.
- For UI changes, verify with `make app` → `open dist/macshot.app`.

## Security and privacy

- All capture and settings data stay **local** on the Mac.
- Do not commit secrets or tokens.

## Human-facing docs

- **README.md** — install, hotkeys, usage (update when user-visible behavior changes).
- **AGENTS.md** (this file) — agent-oriented architecture and conventions.
