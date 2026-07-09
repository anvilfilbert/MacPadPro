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
- Include `sourceSHA256` for downloadable script files.
- Do not include obfuscated scripts or hidden network calls.
- Native Swift extension behavior must be reviewed and built with the app; MacPad Pro does not load arbitrary native third-party bundles.

## Reporting

Open a private GitHub security advisory for `anvilfilbert/MacPadPro` or contact the repository owner through GitHub.
