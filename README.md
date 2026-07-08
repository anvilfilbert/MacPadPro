# MacPad Pro

MacPad Pro is the experimental extension-friendly edition of MacPad.

MacPad stays small and Notepad-like. MacPad Pro is where customization and developer-oriented features can grow without changing the simple app.

## Current Pro Extensions

- Themes: System, Night, Paper, and Terminal
- Language recognition in the status bar for common code and markup files
- Text commands:
  - Trim trailing whitespace
  - Sort lines
  - Uppercase
  - Lowercase
  - Pretty Print JSON

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
