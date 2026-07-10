# Contributing

MacPad Pro is the experimental extension-friendly edition of MacPad. Keep MacPad Pro independent from MacPad.

## Scope

Good contributions include:

- downloadable extension packages
- local-first editor tools
- formatters and language support
- theme improvements
- AI-agent integrations that require user-provided credentials
- documentation for extension authors

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
- public-release verification with no tracked tests, personal paths, names, or secrets

New extensions must be downloadable, loadable, deactivatable, and deletable one by one from Extension Manager.

## Verification

Run before opening a pull request:

```sh
./scripts/verify-release.sh
```

When the local `/Applications` copy should be refreshed, also run:

```sh
./scripts/install-app.sh
```

## Pull Requests

Use focused commits. Include:

- what changed
- how it was verified
- whether new data stays local
- screenshots for visible UI changes when practical
