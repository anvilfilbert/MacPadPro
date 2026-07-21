# Security

MacPad Pro is local-first by default. Report security issues privately before opening public issues.

## Sensitive Data

Do not commit:

- API keys or tokens
- private endpoints
- local usernames or machine paths in examples
- document contents from private files
- crash logs containing secrets

AI extensions must not ship built-in credentials. Users configure their own local or remote agent in `Extensions > AI Agent Settings...`.

## Extension Privacy Rules

- Do not upload document text automatically.
- Use selected text for AI text tasks unless the extension explicitly requires document snippets.
- Keep clipboard, snippets, backups, and version history local.
- Store tokens in Keychain when practical.
- Do not log document text, snippets, backups, or tokens.

## Plugin Package Rules

- Declare plugin permissions in the catalog and package manifest.
- Use the narrowest permissions possible, such as `readSelectedText` and `editSelectedText` for text commands.
- Include `sourceURL` and `sourceSHA256` for downloadable script files. Missing script checksums are rejected.
- Include `sourceSHA256` for package-owned resource files.
- Use `packageFormatVersion` and `minimumMacPadProVersion` when a package depends on newer app behavior.
- Do not include obfuscated scripts or hidden network calls.
- Native Swift extension behavior must be reviewed and built with the app; MacPad Pro does not load arbitrary native third-party bundles.
- Update the pinned catalog SHA-256 in app source whenever `RepositoryExtensions/catalog.json` changes.
- Public checks reject local user names, local paths, private IP addresses, emails, and common token/key formats before release.

## Executable Gate

Run the public hygiene and package validation gate before pushing:

```sh
./scripts/verify-public-repo.sh
```

Run the full release gate before publishing:

```sh
./scripts/verify-release.sh
```

## Reporting

Open a private GitHub security advisory for `anvilfilbert/MacPadPro` or contact the repository owner through GitHub.
