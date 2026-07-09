# MacPad Pro

MacPad Pro is the experimental extension-friendly edition of [MacPad](https://github.com/anvilfilbert/MacPad)

MacPad stays small and Notepad-like. MacPad Pro is where customization and developer-oriented features can grow without changing the simple app.

## Pro Capabilities

- Built-in language recognition in the status bar for common code and markup files
- Built-in syntax coloring for PHP and C-family files, including comments, strings, keywords, numbers, PHP variables, and PHP open tags
- Built-in text commands:
  - Trim trailing whitespace
  - Sort lines
  - Uppercase
  - Lowercase

Available downloadable extensions:

- Document Browser: detachable, resizable, and closable open-document browser
- Pro Themes: Night, Paper, and Terminal
- Clipboard Slots: save and reuse text clipboard content across 10 slots
- AI extensions:
  - AI Summarizer
  - AI Code Explainer
  - AI Code Refactor Assistant
  - AI Meeting Notes Cleaner
  - AI Smart Search
- Formatter extensions:
  - Format As JSON
  - Format C/PHP/C++ brace-style code
- Text command extensions:
  - Pretty Print JSON

Pro extensions are registered through `ExtensionRegistry` in `NotepadMacCore`.
The registry currently owns built-in document browsers, themes, language definitions, text commands, code formatters, clipboard tools, and AI extension commands.
Language definitions also drive editor syntax coloring so a recognized PHP, C, C++, JavaScript, TypeScript, Java, CSS, or Objective-C++ file gets code-aware colors while remaining a plain-text document on disk.

AI extensions require a user-configured local or remote OpenAI-compatible agent. MacPad Pro does not ship with built-in AI credentials, and AI calls are only made from explicit user actions. `Extensions > AI Agent Settings...` includes provider presets:

- Local Ollama: free local models, no API token
- OpenRouter Free Models: hosted free-model catalog, OpenRouter token required
- Groq Free Tier: hosted free-tier inference, Groq token required
- Google Gemini Free Tier: Gemini API free tier, Google AI Studio token required
- OpenAI: OpenAI API, OpenAI API token required

Public hosted AI endpoints normally require tokens even for free tiers. The no-token option is local Ollama.

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

Use `Extensions > Manage Extensions...` to refresh the MacPadPro GitHub catalog, search extensions by name, id, description, or type, download extension packages, load already downloaded local packages, activate/deactivate extensions without deleting them, or delete them one by one.
Installed and deactivated extension ids are stored locally and control which extension menu items appear.
Fresh installs start with downloadable extensions uninstalled so users can add them one by one.
Open editor windows resolve the current active extension state when applying themes, running formatters, and detecting languages.
Downloaded `.macpadproext` packages are stored in the user's Application Support folder under `MacPad Pro/Extensions`.
Downloaded packages are decoded and validated against the selected catalog entry before they are saved and loaded.
The Load control is enabled only when a valid matching local package file is present, and the package is validated again before it is loaded.

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
- `Extensions/clipboard-slots/ClipboardSlotsExtensionPackage.swift`
- `Extensions/ai-summarizer/AISummarizerExtensionPackage.swift`
- `Extensions/ai-code-explainer/AICodeExplainerExtensionPackage.swift`
- `Extensions/ai-code-refactor/AICodeRefactorExtensionPackage.swift`
- `Extensions/ai-meeting-notes/AIMeetingNotesExtensionPackage.swift`
- `Extensions/ai-smart-search/AISmartSearchExtensionPackage.swift`
- `Extensions/pro-themes/ProThemesExtensionPackage.swift`

User guide for plugin authors:

```text
docs/Plugin-Author-Howto.md
```

Developer reference for creating custom extensions:

```text
docs/Creating-Extensions.md
```

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
