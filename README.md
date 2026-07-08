# MacPad Pro

MacPad Pro is the experimental extension-friendly edition of [MacPad](https://github.com/anvilfilbert/MacPad)

MacPad stays small and Notepad-like. MacPad Pro is where customization and developer-oriented features can grow without changing the simple app.

## Current Pro Extensions

- Document Browser: detachable, resizable, and closable open-document browser
- Themes: System, Night, Paper, and Terminal
- Language recognition in the status bar for common code and markup files
- Formatter extensions:
  - Format As JSON
  - Format C/PHP/C++ brace-style code
- Text commands:
  - Trim trailing whitespace
  - Sort lines
  - Uppercase
  - Lowercase
  - Pretty Print JSON

Pro extensions are registered through `ExtensionRegistry` in `NotepadMacCore`.
The registry currently owns built-in document browsers, themes, language definitions, text commands, and code formatters.

Downloadable extensions are represented through `ExtensionCatalog`.
Each extension has a unique id, description, version, type, and download URL so users can download and install extensions one by one as `.macpadproext` packages.

MacPad Pro publishes its downloadable extension catalog from this GitHub repo at:

```text
RepositoryExtensions/catalog.json
```

The app reads the raw GitHub catalog URL:

```text
https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/catalog.json
```

Use `Extensions > Manage Extensions...` to refresh the MacPadPro GitHub catalog, search extensions by name, id, description, or type, download extension packages, load local extensions, activate/deactivate extensions without deleting them, or delete them one by one.
Installed and deactivated extension ids are stored locally and control which extension menu items appear.
Open editor windows resolve the current active extension state when applying themes, running formatters, and detecting languages.
Downloaded `.macpadproext` packages are stored in the user's Application Support folder under `MacPad Pro/Extensions`.

Each downloadable extension owns its own source directory under:

```text
Sources/NotepadMacCore/Extensions/<extension-id>/
```

Each repository package also has its own directory under:

```text
RepositoryExtensions/<extension-id>/
```

Current extension packages:

- `Extensions/open-documents/OpenDocumentsExtensionPackage.swift`
- `Extensions/json-formatter/JSONFormatterExtensionPackage.swift`
- `Extensions/c-family-formatter/CFamilyFormatterExtensionPackage.swift`
- `Extensions/pro-themes/ProThemesExtensionPackage.swift`

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
