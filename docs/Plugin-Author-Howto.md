# Plugin Author How-To

This guide explains how to add your own MacPad Pro plugin.

MacPad Pro plugins are repository-backed extensions. Each plugin has its own source directory and its own downloadable package directory. Users install, activate, deactivate, and delete plugins from `Extensions > Manage Extensions...`.

For the full developer reference, see `docs/Creating-Extensions.md`.

## Current Plugin Model

MacPad Pro supports two plugin paths:

- JavaScript text-command plugins loaded from downloaded package files.
- Source-level Swift extensions that are added to the MacPad Pro repository, tested, released, and published through the repository extension catalog.

MacPad Pro does not load arbitrary native third-party executable bundles. Native Swift extension behavior must be reviewed and built with the app.

This keeps plugins:

- independently downloadable
- independently loadable
- independently deactivatable
- independently deletable
- testable with the main app
- safe from hidden background behavior

## Choose A Plugin ID

Use a short lowercase id:

```text
word-counter
markdown-preview
csv-table-viewer
```

The id must stay stable. It is used in source code, package manifests, catalog entries, install state, and user settings.

## Create The Plugin Directories

Create one source directory:

```text
Sources/NotepadMacCore/Extensions/<plugin-id>/
```

Create one repository package directory:

```text
RepositoryExtensions/<plugin-id>/
```

Example:

```text
Sources/NotepadMacCore/Extensions/word-counter/
RepositoryExtensions/word-counter/
```

## Add The Downloadable Package

Create:

```text
RepositoryExtensions/<plugin-id>/<plugin-id>.macpadproext
```

Example:

```json
{
  "id": "word-counter",
  "title": "Word Counter",
  "description": "Show word, character, and line counts for the current document.",
  "version": "1.0.0",
  "kind": "textCommand"
}
```

The package values must match the catalog values exactly.

For a script command, include a script file, source URL, checksum, and permissions:

```json
{
  "id": "title-case-command",
  "title": "Title Case Command",
  "description": "Convert selected text to title case with a JavaScript plugin command.",
  "version": "1.0.0",
  "kind": "textCommand",
  "author": "MacPad Pro Examples",
  "permissions": ["readSelectedText", "editSelectedText"],
  "scriptCommand": {
    "id": "title-case-command",
    "title": "Title Case Selection",
    "scriptFile": "transform.js",
    "sourceURL": "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/title-case-command/transform.js",
    "sourceSHA256": "c682f3921ea7821eccedc1e0ab550f8dfe7fd444f7ae43355f74c40d060d4e8c"
  }
}
```

The script must define this function:

```js
function transform(input) {
  return input;
}
```

Only returned text replaces the selected text. Do not mutate global state or perform hidden network calls.

## Add The Plugin Source

Create a Swift file in the plugin source directory.

Example:

```swift
import Foundation

enum WordCounterExtensionPackage {
    static let id = "word-counter"

    static let catalogEntry = DownloadableExtension(
        id: id,
        title: "Word Counter",
        description: "Show word, character, and line counts for the current document.",
        version: "1.0.0",
        kind: .textCommand,
        downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/word-counter/word-counter.macpadproext")!
    )
}
```

Register the plugin in `BuiltInExtensions.downloadableExtensions`.

## Pick The Right Plugin Kind

Use an existing kind when possible:

```text
documentBrowser
theme
language
formatter
textCommand
clipboard
aiTextTask
aiSmartSearch
markdownPreview
exportTools
documentStatistics
diffViewer
autoBackup
clipboardSnippets
fileOutline
csvTableViewer
markdownTools
encodingLineEndings
focusMode
```

Use `textCommand` for JavaScript transform plugins. The command appears with other text commands after the user downloads and activates it.

If the plugin needs a new kind, add it to `ExtensionKind`, extend `ExtensionRegistry`, and add tests for activation and deactivation.

Use existing menu groups when possible:

- `Extensions > Markdown`
- `Extensions > Export`
- `Extensions > Tools`
- `Extensions > Backup`
- `Extensions > Clipboard & Snippets`
- `Extensions > Navigation`
- `Extensions > Data`
- `Extensions > Text`
- `Extensions > View`
- `Extensions > AI`

## Theme Plugin Colors

Theme color definitions belong in the theme extension source directory.

For the built-in Pro Themes extension, colors live in:

```text
Sources/NotepadMacCore/Extensions/pro-themes/ProThemesExtensionPackage.swift
```

The extension directory also contains a short local README:

```text
Sources/NotepadMacCore/Extensions/pro-themes/README.md
```

## Add The Catalog Entry

Add the plugin to:

```text
RepositoryExtensions/catalog.json
```

Example:

```json
{
  "id": "word-counter",
  "title": "Word Counter",
  "description": "Show word, character, and line counts for the current document.",
  "version": "1.0.0",
  "kind": "textCommand",
  "downloadURL": "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/word-counter/word-counter.macpadproext"
}
```

Use searchable titles and descriptions. Include keywords like Markdown, CSV, PHP, formatter, snippets, local backup, line endings, detached window, or AI agent when they apply.

## Keep Plugins Opt-In

Do not activate new plugins by default.

Plugin behavior should only appear when the user has downloaded, loaded, and activated the plugin.

Use the installed extension state before exposing menus, commands, panels, or behavior.

## Privacy Rules

Plugins must be explicit and local-first.

- Do not upload document text automatically.
- Send selected text only unless the command clearly needs more.
- Keep clipboard, snippets, backups, and version data local.
- Do not include API keys or built-in credentials.
- Store sensitive tokens in Keychain when practical.
- Do not log document text or secrets.

Declare permissions in both the catalog entry and package manifest. Use only the permissions the plugin needs:

```text
readSelectedText
editSelectedText
readDocumentText
openDetachedWindow
localStorage
networkAccess
```

Script packages should include `sourceSHA256`. MacPad Pro validates downloaded script content before saving it locally.

## Tests To Add

Add focused tests for:

- catalog entry exists
- package manifest validates
- source directory exists
- plugin loads only when active
- plugin hides when deactivated
- core logic works without launching the app

Run:

```sh
swift test
```

## Local Verification

Build and install locally:

```sh
./scripts/install-app.sh
```

Create the release zip:

```sh
./scripts/package-release.sh
```

Then open MacPad Pro and verify:

- `Extensions > Manage Extensions...` shows the plugin
- Download works
- Load works
- Deactivate hides the plugin feature
- Reactivate restores the plugin feature
- Delete removes the local package

## Publishing

Commit the source directory, repository package directory, catalog update, and tests together.

After pushing to GitHub, users can refresh the extension catalog inside MacPad Pro and download the plugin one by one.

If the extension adds a new category or notable capability, update:

- `README.md`
- `RepositoryExtensions/README.md`
- GitHub topics when the keyword describes the repo as a whole
