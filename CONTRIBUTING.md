# Contributing

Thank you for your interest in contributing. Macshot is a macOS menu bar app built with Swift Package Manager.

## Before you start

- Read the [README](README.md) for install and usage.
- Browse [open issues](https://github.com/andresousadotpt/macshot/issues) and [pull requests](https://github.com/andresousadotpt/macshot/pulls) to avoid duplicate work.
- For larger changes, open an issue first to discuss the approach.

## Requirements

- macOS 14 (Sonoma) or later
- Xcode Command Line Tools (`xcode-select --install`)
- Full **Xcode** (not Command Line Tools alone) to run `make test`

## Getting started

```bash
git clone https://github.com/andresousadotpt/macshot.git
cd macshot
make build
make run
make test
make app      # release .app in ./dist/ — use for manual QA
```

## Project layout

| Target | Purpose |
| ------ | ------- |
| **MacshotCore** | Models, persistence, pure logic — no UI imports |
| **Macshot** | SwiftUI views, AppKit bridges, app shell |

- New models/settings → `Sources/MacshotCore/Models/`
- File I/O and config → `Sources/MacshotCore/Services/` or `Utilities/`
- UI screens → `Sources/Macshot/Views/`
- AppKit bridges → `Sources/Macshot/Support/`

AI coding agents should read [AGENTS.md](AGENTS.md) for deeper conventions.

## How to contribute

### Reporting bugs

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md). Include:

- macOS version
- How you installed (build from source, Homebrew, GitHub Release)
- Steps to reproduce and expected vs actual behavior
- Whether you used `make run` or the packaged `.app`

### Suggesting features

Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md). Describe the problem, your proposed solution, and any alternatives you considered.

### Pull requests

1. Fork the repo and create a branch from `main`.
2. Make focused changes — one logical change per PR when possible.
3. Run `make build` before opening the PR.
4. Run `make test` when you change **MacshotCore** logic.
5. For UI changes, note manual QA steps (`make app` → open `dist/macshot.app`).
6. Open a PR against `main` and fill out the [pull request template](.github/pull_request_template.md).

### Commit messages

Use conventional prefixes when they fit:

- `feat:` — new user-facing behavior
- `fix:` — bug fix
- `docs:` — documentation only
- `chore:` — tooling, CI, version bumps
- `test:` — tests only

## Code guidelines

- **MacshotCore** must not import SwiftUI or AppKit.
- Match existing naming, structure, and patterns in the file you are editing.
- Avoid drive-by refactors unrelated to your change.
- Do not commit `.build/`, `dist/`, `.DS_Store`, or release artifacts.

### Testing

Tests live in `Tests/MacshotCoreTests/` and target **MacshotCore** only.

```bash
make test
```

UI and AppKit behavior is validated manually via `make app`.

## Releases

Maintainers handle releases through CI on push to `main`. See [README — Releasing](README.md#releasing). Contributors do not need to bump versions unless asked.

## Code of conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). By participating, you agree to uphold it.

## Questions

See [SUPPORT.md](SUPPORT.md).
