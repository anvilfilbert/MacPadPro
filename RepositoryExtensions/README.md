# Repository Extension Catalog

This directory is the public download source for MacPad Pro extensions.

MacPad Pro reads:

```text
https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/catalog.json
```

Each extension has one directory:

```text
RepositoryExtensions/<extension-id>/<extension-id>.macpadproext
```

Extensions can include extra package-owned files in the same directory. Script text-command extensions use:

```text
RepositoryExtensions/<extension-id>/transform.js
```

The manifest should include `scriptCommand.sourceURL` and `scriptCommand.sourceSHA256` so Extension Manager can download and verify the script before saving it locally.

The `.macpadproext` manifest must match the catalog entry exactly:

- `id`
- `title`
- `description`
- `version`
- `kind`

If any value differs, Extension Manager rejects the package.

Extension Manager also displays optional trust metadata:

- `author`
- `permissions`

Installed packages show `Update Available` when this catalog publishes a newer semantic version than the local package.

## Current Keywords

Use these terms in extension descriptions when relevant so users can find packages through Extension Manager search:

- markdown
- preview
- export
- pdf
- html
- rtf
- statistics
- diff
- backup
- versions
- clipboard
- snippets
- outline
- navigation
- csv
- tsv
- table
- encoding
- line endings
- focus mode
- themes
- formatter
- php
- c++
- json
- ai agent
- ollama
- openrouter
- javascript
- script command
- title case

## Publishing Checklist

- Add source under `Sources/NotepadMacCore/Extensions/<extension-id>/`.
- Add package under `RepositoryExtensions/<extension-id>/`.
- Add catalog entry in `RepositoryExtensions/catalog.json`.
- Add package entry to `ExtensionCatalog.default`.
- Add tests for catalog, package validation, activation/deactivation, and core behavior.
- Update `README.md` and docs when the extension adds a new user-facing capability.
- Run `./scripts/verify-release.sh` before publishing.
