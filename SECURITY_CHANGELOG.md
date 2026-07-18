# Security Changelog

## 0.2.0 - Security Hardening Release

- Pinned `RepositoryExtensions/catalog.json` to a SHA-256 value embedded in the app release.
- Required `sourceURL` and `sourceSHA256` for downloadable JavaScript text-command packages.
- Added bounded HTTPS/file downloads for extension catalogs, manifests, scripts, and resources.
- Added a separate `MacPadProScriptRunner` helper process for JavaScript text commands.
- Added script input, script file, output, and execution-time limits.
- Added `Extensions > Clear Local Extension Data...` for clipboard slots, snippets, backup snapshots, and session text.
- Added a warning before AI Smart Search sends open-document snippets to non-local AI endpoints.
- Saved AI agent tokens with explicit Keychain status checks and `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
- Added optional Developer ID signing and notarization support in release scripts.
- Fixed the bare `t` keyboard shortcut bug by moving Time/Date to F5.

## Review Artifact

The security review that drove this release is tracked in `security_best_practices_report.md`.
