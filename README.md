# MacPad Pro

MacPad Pro is the experimental extension-friendly edition of MacPad.

MacPad stays small and Notepad-like. MacPad Pro is where customization and developer-oriented features can grow without changing the simple app.

## Current Pro Extensions

- Document Browser: detachable, resizable, and closable open-document browser
- Themes: System, Night, Paper, and Terminal
- Language recognition in the status bar for common code and markup files
- Formatter extensions:
  - Format As JSON
- Text commands:
  - Trim trailing whitespace
  - Sort lines
  - Uppercase
  - Lowercase
  - Pretty Print JSON

Pro extensions are registered through `ExtensionRegistry` in `NotepadMacCore`.
The registry currently owns built-in document browsers, themes, language definitions, text commands, and code formatters.

Downloadable extensions are represented through `ExtensionCatalog`.
Each extension has a unique id, version, type, and download URL so users can download and install extensions one by one as `.macpadproext` packages.

Use `Extensions > Manage Extensions...` to load or delete extensions one by one.
Loaded extension ids are stored locally and control which extension menu items appear.

## Build

```sh
./scripts/build-app.sh
```

The app bundle is created at:

```text
build/MacPad Pro.app
```

Install it into `/Applications` with:

```sh
./scripts/install-app.sh
```

Create a release zip with:

```sh
./scripts/package-release.sh
```

## Development

Run tests:

```sh
swift test
```
