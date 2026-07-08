# MacPad Pro Release QA

Run this checklist before publishing a release.

## Build

- `swift test` passes.
- `./scripts/package-release.sh` creates `dist/MacPadPro-<version>-macOS-universal.zip`.
- `codesign --verify --deep --verbose=2 "build/MacPad Pro.app"` passes.
- The release zip contains only `MacPad Pro.app` files and no `__MACOSX` or `._*` entries.

## App Basics

- Launches from `build/MacPad Pro.app` and `/Applications/MacPad Pro.app`.
- App name appears as `MacPad Pro` in the menu bar, title bar, Finder, Dock, and About panel.
- App icon appears in Finder, Dock, and the About panel.
- New documents default to Windows line endings and UTF-8.

## Windows And Tabs

- `Cmd+N` opens a new tab in the current window.
- `Cmd+Shift+N` opens a separate new window.
- `File > New Tab` and `File > New Window` match their shortcut behavior.
- Multiple windows can each contain multiple tabs.
- `Cmd+W` closes the current tab or window after the normal unsaved-change prompt.
- `Window > Show Previous Tab` and `Window > Show Next Tab` switch tabs.

## Extensions

- Downloadable extension catalog entries are one extension per package URL.
- `Extensions > Manage Extensions...` opens a resizable extension manager with Load and Delete controls.
- Loading or deleting an extension updates the Extensions menu without restarting the app.
- `Extensions > Document Browser` opens a detached, resizable, and closable window listing open documents.
- Double-clicking a document in the Document Browser brings that document window forward.
- Themes can switch between System, Night, Paper, and Terminal.
- Status bar language recognition updates when opening common source files.
- `Extensions > Format As > JSON` pretty-prints valid JSON.
- Text commands work: trim trailing whitespace, sort lines, uppercase, lowercase, and pretty print JSON.

## Editing

- Undo, redo, cut, copy, paste, delete, and select all work in the editor.
- Find, find next, find previous, replace, and replace all work.
- Go To selects the requested line.
- Time/Date inserts text at the cursor.
- Word Wrap, Status Bar, Font, and Zoom controls update the editor.

## Files

- Open supports `.txt` and plain text files.
- Save writes the current document.
- Save As writes a new file and updates the title.
- Closing a changed document shows Save, Don't Save, and Cancel.
- Windows, Unix, and classic Mac line endings are detected and preserved on save.

## Session Restore

- Quit with several windows and tabs open.
- Relaunch restores separate windows, their tabs, unsaved text, selections, word wrap, status bar, zoom, and line ending mode.
- Choosing Don't Save on close removes that document from the restored session.
