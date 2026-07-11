# Changelog

## Current

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
