# Support

## Documentation

- [README](README.md) — install, hotkeys, and usage
- [CONTRIBUTING.md](CONTRIBUTING.md) — development setup
- [AGENTS.md](AGENTS.md) — architecture for coding agents

## Getting help

1. Check the [README](README.md) and existing [issues](https://github.com/andresousadotpt/macshot/issues).
2. Search [closed issues](https://github.com/andresousadotpt/macshot/issues?q=is%3Aissue+is%3Aclosed).
3. Open a [new issue](https://github.com/andresousadotpt/macshot/issues/new/choose) with the appropriate template.

For bugs, include your macOS version, install method, and whether you used `make run` or the packaged app (`make app`).

## Common topics

| Topic | Notes |
| ----- | ----- |
| **Screen Recording permission** | Required for GIF recording. Open Settings → Privacy & Security → Screen Recording and enable Macshot. Screenshots use display capture at selection time. |
| **Hotkeys not working** | Ensure Macshot is running and **Accessibility** is enabled for Macshot in System Settings. Defaults are `⌘⇧4` (screenshot) and `⌘⇧3` (GIF). Change them in Settings. |
| **GIF paste not supported** | Some apps do not accept GIF from clipboard; try Preview, Slack, or Discord. |
| **Gatekeeper / "app is damaged"** | Expected for Homebrew and GitHub Release builds (ad-hoc signed). Right-click → Open, or build from source with `make app`. |
| **Tests fail to run** | `make test` needs full Xcode installed, not Command Line Tools alone. |

## Security issues

Do not open public issues for security vulnerabilities. See [SECURITY.md](SECURITY.md).

## Feature requests

We welcome ideas. Please use the feature request template and describe the problem you are trying to solve.

## No official support SLA

This is an open-source project maintained in spare time. Issues and pull requests are handled as capacity allows.
