# Changelog

## Current

- Released MacPad Pro 0.2.0 security hardening update.
- Pinned the GitHub extension catalog SHA-256 in the app so catalog changes require a matching release.
- Required checksums for downloadable JavaScript text-command plugins.
- Added bounded extension downloads with timeout and size limits.
- Moved JavaScript text commands into a separate helper runner with input, output, script-size, and timeout limits.
- Added a local extension data clear command for retained clipboard, snippets, backups, and session text.
- Added remote-endpoint disclosure before AI Smart Search sends open-document snippets.
- Hardened AI token Keychain writes with explicit status checks and an accessibility class.
- Added optional Developer ID signing and notarization support for release packaging.
- Fixed the Time/Date shortcut so plain `t` no longer triggers a menu command while typing.

- Added MacPad Pro About credits with links to the creator profile and public repository.
- Hardened extension packages with manifest compatibility checks, resource SHA-256 validation, and package-owned resource cleanup.
- Moved Pro Themes color definitions into `RepositoryExtensions/pro-themes/themes.json` so theme contributors can edit extension-owned data in one place.
- Added repository package validation through `MacPadProRepoCheck` and wired it into `./scripts/verify-public-repo.sh`.
- Added release smoke verification, release zip checksum output, and release zip content validation.
- Improved Auto Backup with timed, debounced local snapshots.
- Improved C/PHP formatter handling for preprocessor lines, `case`/`default`, and closing-brace continuations such as `} else {`.
- Added stable accessibility identifiers for key editor and extension-management UI surfaces.
- Updated README, extension author docs, repository extension docs, QA notes, Security notes, and pull request checklist.

## Extension Baseline

- Created MacPad Pro as the independent experimental extension edition of MacPad.
- Added downloadable extension catalog support through `RepositoryExtensions/catalog.json`.
- Added Extension Manager download, load, activate, deactivate, and delete flows.
- Added downloadable extension packages for themes, formatters, document tools, backup/version history, clipboard/snippets, Markdown tools, file outline, CSV preview, focus mode, and optional AI-agent tasks.
- Added script text-command plugin support with checksum-verified package files.
- Added syntax coloring for PHP and C-family files.
