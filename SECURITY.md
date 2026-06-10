# Security policy

## Supported versions

Security fixes are applied to the latest release on `main`. Older releases are not maintained separately.

| Version | Supported |
| ------- | --------- |
| Latest on `main` | Yes |
| Older releases | No |

## Reporting a vulnerability

If you discover a security issue, please report it privately rather than opening a public issue.

**Preferred:** Use [GitHub private vulnerability reporting](https://github.com/andresousadotpt/macshot/security/advisories/new) if available.

**Alternative:** Contact the maintainer via GitHub ([@andresousadotpt](https://github.com/andresousadotpt)).

Include:

- A description of the vulnerability and its impact
- Steps to reproduce
- macOS version and how you installed the app (source build, Homebrew, release zip)
- Any proof-of-concept or suggested fix, if you have one

Please do not disclose the issue publicly until a fix is available, unless we agree otherwise.

## Scope

Macshot is a **local-first** macOS application. Reports we are interested in include:

- Unauthorized access to or corruption of user data or config
- Sandbox or entitlement misconfigurations that expand attack surface
- Unsafe file I/O (path traversal, symlink issues, non-atomic writes)
- Supply-chain issues in the build or release pipeline

Out of scope:

- Social engineering or physical access to an unlocked Mac
- Gatekeeper warnings for ad-hoc signed release builds (expected; build from source to avoid)

## Safe defaults

- Do not commit secrets, tokens, or signing certificates.
- CI uses repository secrets only for automated Homebrew tap updates (`HOMEBREW_TAP_TOKEN`).

Thank you for helping keep this project and its users safe.
