# Creating MacPad Pro Extensions

MacPad Pro extensions are small downloadable packages that add optional features to the experimental Pro app. MacPad stays independent and simple; MacPad Pro owns the extension system.

Extensions are opt-in. A fresh install should not activate downloadable extensions automatically. Users download, load, deactivate, reactivate, or delete extensions from `Extensions > Manage Extensions...`.

## What An Extension Contains

Each extension has two parts:

- A Swift source directory inside the app source tree.
- A repository package manifest that Extension Manager can download and validate.

Extensions can also include package-owned files such as `transform.js` or `themes.json`. Extension Manager downloads those files into the local extension package directory after validating their SHA-256 checksums.

Use one directory per extension:

```text
Sources/NotepadMacCore/Extensions/<extension-id>/
RepositoryExtensions/<extension-id>/<extension-id>.macpadproext
```

The extension id should be lowercase, stable, and URL-friendly, for example:

```text
word-counter
markdown-tools
csv-table-viewer
```

## Package Manifest

Create a `.macpadproext` file in the matching repository directory:

```json
{
  "packageFormatVersion": 1,
  "minimumMacPadProVersion": "0.1.0",
  "id": "word-counter",
  "title": "Word Counter",
  "description": "Show word, character, and line counts for the current document.",
  "version": "1.0.0",
  "kind": "textCommand"
}
```

The manifest must match the catalog entry exactly:

- `id`
- `title`
- `description`
- `version`
- `kind`

If these do not match, MacPad Pro rejects the package.

Use `packageFormatVersion` for package schema compatibility and `minimumMacPadProVersion` when an extension requires a newer app release.

Optional trust metadata is shown in Extension Manager:

```json
{
  "author": "MacPad Pro Examples",
  "permissions": ["readSelectedText", "editSelectedText"]
}
```

Script text commands add a `scriptCommand` block:

```json
{
  "scriptCommand": {
    "id": "title-case-command",
    "title": "Title Case Selection",
    "scriptFile": "transform.js",
    "sourceURL": "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/title-case-command/transform.js",
    "sourceSHA256": "c682f3921ea7821eccedc1e0ab550f8dfe7fd444f7ae43355f74c40d060d4e8c"
  }
}
```

The script file must define `transform(input)` and return replacement text:

```js
function transform(input) {
  return input.toUpperCase();
}
```

Data-driven extensions add verified resources:

```json
{
  "resources": [
    {
      "file": "themes.json",
      "sourceURL": "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/pro-themes/themes.json",
      "sourceSHA256": "f5b2279ee3bb66b27f0866376343b2c29c7ef4b42a4433a202b50beb9033d502"
    }
  ]
}
```

Theme extensions point at the resource that contains the color definitions:

```json
{
  "themeResource": {
    "file": "themes.json"
  }
}
```

Theme JSON uses normalized RGBA color components:

```json
{
  "themes": [
    {
      "id": "night",
      "name": "Night",
      "textColor": { "red": 0.86, "green": 0.88, "blue": 0.90, "alpha": 1.0 },
      "backgroundColor": { "red": 0.10, "green": 0.11, "blue": 0.12, "alpha": 1.0 },
      "insertionPointColor": { "red": 0.39, "green": 0.76, "blue": 1.0, "alpha": 1.0 },
      "statusTextColor": { "red": 0.70, "green": 0.73, "blue": 0.76, "alpha": 1.0 },
      "statusBackgroundColor": { "red": 0.14, "green": 0.15, "blue": 0.16, "alpha": 1.0 }
    }
  ]
}
```

## Catalog Entry

Add the extension to `RepositoryExtensions/catalog.json`:

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

Also add the same entry to `ExtensionCatalog.default` through the package source file so the built app knows the extension before a remote catalog refresh.

## Source Package

Create a Swift package descriptor in the extension source directory:

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

Then register the extension in `BuiltInExtensions.contributions`.

## Choosing An Extension Kind

Use the kind that matches the feature:

```swift
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

If your extension needs a new kind, add it to `ExtensionKind`, add a registry surface in `ExtensionRegistry`, and verify activation/deactivation before publishing.

Current user-facing extension groups:

- Markdown: preview and editing tools
- Export: PDF, HTML, Markdown, RTF
- Tools: document statistics and diff viewer
- Backup: local version history
- Clipboard & Snippets: local clipboard history and pinned snippets
- Navigation: file outline
- Data: CSV/TSV table preview
- Text: encoding and line-ending tools
- View: focus mode
- AI: opt-in agent-backed text tasks and smart search

Script text-command plugins appear with built-in text commands. They are the preferred first option for contributor-owned text transforms because they do not require native bundle loading.

## Activation Rules

Never make a downloadable extension active by default. Keep:

```swift
static let defaultInstalledExtensionIDs: Set<String> = []
```

Register runtime behavior only when installed and active:

```swift
let feature = installedExtensions.isActive(WordCounterExtensionPackage.id)
    ? WordCounterExtensionPackage.commands
    : []
```

This keeps extensions independently downloadable, loadable, deactivatable, and deletable.

## Menus

Menu items are created in `MainMenuFactory.swift`. Add commands only from active registry entries.

Examples:

- `Extensions > Markdown > Preview`
- `Extensions > Export > Export As...`
- `Extensions > Tools > Document Statistics`
- `Extensions > AI > Summarize Selection`

Actions usually live in `AppDelegate.swift` and call the active editor window.

Detached panels should use their own `NSWindowController` so they remain resizable and closable. Keep reusable parsing, formatting, counting, or conversion logic in `NotepadMacCore` so it can be tested without launching the app.

## Repository Keywords

When adding an extension, use clear titles and descriptions that contain search terms users will try in Extension Manager and on GitHub. Good descriptions include:

- what the extension does
- where it appears in the menu
- whether data stays local
- whether it opens a detached panel
- supported file types or languages

## Data And Privacy

Extensions should be explicit and local-first.

- Do not upload document text automatically.
- Send selected text only unless the feature clearly requires more.
- Keep backup, clipboard, and snippet data local.
- Do not ship API credentials.
- Store sensitive tokens in Keychain when possible.
- Avoid logging secrets or document content.

Declare permissions using these values:

```text
readSelectedText
editSelectedText
readDocumentText
openDetachedWindow
localStorage
networkAccess
```

For downloadable scripts and package-owned resource files, include `sourceSHA256`. Extension Manager rejects files whose actual checksum differs from the manifest.

## Public Verification

Before publishing, verify:

- Catalog contains the extension id and kind.
- Catalog search finds title, description, and kind.
- The source directory exists and contains Swift files.
- The repository package manifest validates against the catalog entry.
- Package resources exist and match their declared SHA-256 checksums.
- Activation loads the feature only when installed.
- Deactivation hides the feature without deleting the package.
- Script plugins execute `transform(input)` and reject invalid script packages.
- Installed package versions report update availability when the repository catalog has a newer version.
- No tracked tests, personal names, local paths, API keys, or secret-like values are committed.

Run:

```sh
./scripts/verify-public-repo.sh
```

## Local Verification

After public verification passes:

```sh
./scripts/install-app.sh
./scripts/package-release.sh
```

Then verify that the app opens and that `Extensions > Manage Extensions...` can download, load, deactivate, reactivate, and delete the extension.

## Release Checklist

Before pushing:

- Source directory exists under `Sources/NotepadMacCore/Extensions/<extension-id>/`.
- Package manifest exists under `RepositoryExtensions/<extension-id>/`.
- `RepositoryExtensions/catalog.json` contains the raw GitHub package URL.
- `ExtensionCatalog.default` includes the package entry.
- README or user docs mention the extension.
- `./scripts/verify-public-repo.sh` passes.
- `./scripts/verify-release.sh` passes.
- The app builds and installs locally.
