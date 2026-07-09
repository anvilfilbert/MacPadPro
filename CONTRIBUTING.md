# Contributing

MacPad Pro is the experimental extension-friendly edition of MacPad. Keep MacPad Pro independent from MacPad.

## Scope

Good contributions include:

- downloadable extension packages
- local-first editor tools
- formatters and language support
- theme improvements
- AI-agent integrations that require user-provided credentials
- tests and documentation for extension authors

Avoid:

- adding built-in API credentials
- automatic document uploads
- making downloadable extensions active by default
- changing MacPad behavior from this repository

## Extension Rules

Each extension must have:

- `Sources/NotepadMacCore/Extensions/<extension-id>/`
- `RepositoryExtensions/<extension-id>/<extension-id>.macpadproext`
- matching entry in `RepositoryExtensions/catalog.json`
- matching `DownloadableExtension` package entry
- tests for catalog/package/activation behavior

New extensions must be downloadable, loadable, deactivatable, and deletable one by one from Extension Manager.

## Verification

Run before opening a pull request:

```sh
swift test --quiet
./scripts/build-app.sh
```

For release or install changes, also run:

```sh
./scripts/install-app.sh
./scripts/package-release.sh
```

## Pull Requests

Use focused commits. Include:

- what changed
- how it was tested
- whether new data stays local
- screenshots for visible UI changes when practical
