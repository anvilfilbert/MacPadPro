import AppKit
import NotepadMacCore

@MainActor
enum MainMenuFactory {
    static func makeMenu(target: AnyObject, extensionRegistry: ExtensionRegistry, recentFiles: [String]) -> NSMenu {
        let mainMenu = NSMenu(title: "Main Menu")

        let appMenu = NSMenu(title: "MacPad Pro")
        addItem("About MacPad Pro", to: appMenu, action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), target: NSApp)
        appMenu.addItem(.separator())
        addItem("Quit MacPad Pro", to: appMenu, action: #selector(NSApplication.terminate(_:)), target: NSApp, key: "q")
        let appRoot = NSMenuItem()
        appRoot.submenu = appMenu
        mainMenu.addItem(appRoot)

        let fileMenu = NSMenu(title: "File")
        addItem("New Tab", to: fileMenu, action: #selector(AppDelegate.openNewTab(_:)), target: target, key: "n")
        addItem("New Window", to: fileMenu, action: #selector(AppDelegate.openNewWindow(_:)), target: target, key: "n", modifiers: [.command, .shift])
        addItem("Open...", to: fileMenu, action: #selector(AppDelegate.openDocument(_:)), target: target, key: "o")
        let recentMenu = NSMenu(title: "Open Recent Files...")
        for path in recentFiles.prefix(5) {
            let item = addItem(URL(fileURLWithPath: path).lastPathComponent, to: recentMenu, action: #selector(AppDelegate.openRecentFile(_:)), target: target)
            item.representedObject = path
            item.toolTip = path
        }
        if recentFiles.isEmpty {
            let emptyItem = NSMenuItem(title: "No Recent Files", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            recentMenu.addItem(emptyItem)
        }
        let recentRoot = NSMenuItem(title: "Open Recent Files...", action: nil, keyEquivalent: "")
        recentRoot.submenu = recentMenu
        fileMenu.addItem(recentRoot)
        addItem("Close", to: fileMenu, action: #selector(NSWindow.performClose(_:)), target: nil, key: "w")
        fileMenu.addItem(.separator())
        addItem("Save", to: fileMenu, action: #selector(AppDelegate.save(_:)), target: target, key: "s")
        addItem("Save As...", to: fileMenu, action: #selector(AppDelegate.saveAs(_:)), target: target, key: "S")
        fileMenu.addItem(.separator())
        addItem("Print...", to: fileMenu, action: #selector(AppDelegate.printDocument(_:)), target: target, key: "p")
        mainMenu.addItem(rootItem(for: fileMenu))

        let editMenu = NSMenu(title: "Edit")
        addItem("Undo", to: editMenu, action: Selector(("undo:")), target: nil, key: "z")
        addItem("Redo", to: editMenu, action: Selector(("redo:")), target: nil, key: "Z")
        editMenu.addItem(.separator())
        addItem("Cut", to: editMenu, action: #selector(NSText.cut(_:)), target: nil, key: "x")
        addItem("Copy", to: editMenu, action: #selector(NSText.copy(_:)), target: nil, key: "c")
        addItem("Paste", to: editMenu, action: #selector(NSText.paste(_:)), target: nil, key: "v")
        addItem("Delete", to: editMenu, action: #selector(NSText.delete(_:)), target: nil)
        editMenu.addItem(.separator())
        addItem("Find...", to: editMenu, action: #selector(AppDelegate.showFind(_:)), target: target, key: "f")
        addItem("Find Next", to: editMenu, action: #selector(AppDelegate.findNext(_:)), target: target, key: "g")
        addItem("Find Previous", to: editMenu, action: #selector(AppDelegate.findPrevious(_:)), target: target, key: "G")
        addItem("Replace...", to: editMenu, action: #selector(AppDelegate.showReplace(_:)), target: target, key: "h")
        addItem("Go To...", to: editMenu, action: #selector(AppDelegate.goToLine(_:)), target: target, key: "l")
        editMenu.addItem(.separator())
        addItem("Select All", to: editMenu, action: #selector(NSText.selectAll(_:)), target: nil, key: "a")
        addItem("Time/Date", to: editMenu, action: #selector(AppDelegate.insertTimeDate(_:)), target: target, key: "t", modifiers: [])
        mainMenu.addItem(rootItem(for: editMenu))

        let formatMenu = NSMenu(title: "Format")
        addItem("Word Wrap", to: formatMenu, action: #selector(AppDelegate.toggleWordWrap(_:)), target: target, key: "w", modifiers: [.command, .option])
        addItem("Font...", to: formatMenu, action: #selector(AppDelegate.chooseFont(_:)), target: target, key: "f", modifiers: [.command, .option])
        mainMenu.addItem(rootItem(for: formatMenu))

        let extensionsMenu = NSMenu(title: "Extensions")
        addItem("Manage Extensions...", to: extensionsMenu, action: #selector(AppDelegate.showExtensionManager(_:)), target: target)
        addItem("AI Agent Settings...", to: extensionsMenu, action: #selector(AppDelegate.showAIAgentSettings(_:)), target: target)
        extensionsMenu.addItem(.separator())

        if !extensionRegistry.aiTextTasks.isEmpty || !extensionRegistry.aiSmartSearches.isEmpty {
            let aiMenu = NSMenu(title: "AI")
            for task in extensionRegistry.aiTextTasks {
                let item = addItem(task.menuTitle, to: aiMenu, action: #selector(AppDelegate.runAITextTask(_:)), target: target)
                item.representedObject = task.id
            }
            for smartSearch in extensionRegistry.aiSmartSearches {
                let item = addItem(smartSearch.title, to: aiMenu, action: #selector(AppDelegate.showAISmartSearch(_:)), target: target)
                item.representedObject = smartSearch.id
            }

            let aiRoot = NSMenuItem(title: "AI", action: nil, keyEquivalent: "")
            aiRoot.submenu = aiMenu
            extensionsMenu.addItem(aiRoot)
            extensionsMenu.addItem(.separator())
        }

        if !extensionRegistry.markdownPreviews.isEmpty || !extensionRegistry.markdownTools.isEmpty {
            let markdownMenu = NSMenu(title: "Markdown")
            for preview in extensionRegistry.markdownPreviews {
                let item = addItem(preview.title, to: markdownMenu, action: #selector(AppDelegate.showMarkdownPreview(_:)), target: target)
                item.representedObject = preview.id
            }
            if !extensionRegistry.markdownPreviews.isEmpty && !extensionRegistry.markdownTools.isEmpty {
                markdownMenu.addItem(.separator())
            }
            if !extensionRegistry.markdownTools.isEmpty {
                let toolsMenu = NSMenu(title: "Tools")
                let toggleItem = addItem("Toggle Checkbox", to: toolsMenu, action: #selector(AppDelegate.runMarkdownTool(_:)), target: target)
                toggleItem.representedObject = "toggle-checkbox"
                let tableItem = addItem("Insert Table", to: toolsMenu, action: #selector(AppDelegate.runMarkdownTool(_:)), target: target)
                tableItem.representedObject = "insert-table"
                let listItem = addItem("Format List", to: toolsMenu, action: #selector(AppDelegate.runMarkdownTool(_:)), target: target)
                listItem.representedObject = "format-list"
                let renumberItem = addItem("Renumber Ordered List", to: toolsMenu, action: #selector(AppDelegate.runMarkdownTool(_:)), target: target)
                renumberItem.representedObject = "renumber-ordered-list"
                let toolsRoot = NSMenuItem(title: "Tools", action: nil, keyEquivalent: "")
                toolsRoot.submenu = toolsMenu
                markdownMenu.addItem(toolsRoot)
            }
            let markdownRoot = NSMenuItem(title: "Markdown", action: nil, keyEquivalent: "")
            markdownRoot.submenu = markdownMenu
            extensionsMenu.addItem(markdownRoot)
            extensionsMenu.addItem(.separator())
        }

        if !extensionRegistry.exportTools.isEmpty {
            let exportMenu = NSMenu(title: "Export")
            for exportTool in extensionRegistry.exportTools {
                let item = addItem(exportTool.title, to: exportMenu, action: #selector(AppDelegate.exportDocument(_:)), target: target)
                item.representedObject = exportTool.id
            }
            let exportRoot = NSMenuItem(title: "Export", action: nil, keyEquivalent: "")
            exportRoot.submenu = exportMenu
            extensionsMenu.addItem(exportRoot)
            extensionsMenu.addItem(.separator())
        }

        if !extensionRegistry.documentStatistics.isEmpty || !extensionRegistry.diffViewers.isEmpty {
            let toolsMenu = NSMenu(title: "Tools")
            for statistics in extensionRegistry.documentStatistics {
                let item = addItem(statistics.title, to: toolsMenu, action: #selector(AppDelegate.showDocumentStatistics(_:)), target: target)
                item.representedObject = statistics.id
            }
            for diffViewer in extensionRegistry.diffViewers {
                let item = addItem(diffViewer.title, to: toolsMenu, action: #selector(AppDelegate.showDiffViewer(_:)), target: target)
                item.representedObject = diffViewer.id
            }
            let toolsRoot = NSMenuItem(title: "Tools", action: nil, keyEquivalent: "")
            toolsRoot.submenu = toolsMenu
            extensionsMenu.addItem(toolsRoot)
            extensionsMenu.addItem(.separator())
        }

        if !extensionRegistry.autoBackups.isEmpty {
            let backupMenu = NSMenu(title: "Backup")
            for backup in extensionRegistry.autoBackups {
                let item = addItem(backup.title, to: backupMenu, action: #selector(AppDelegate.showVersionHistory(_:)), target: target)
                item.representedObject = backup.id
            }
            let backupRoot = NSMenuItem(title: "Backup", action: nil, keyEquivalent: "")
            backupRoot.submenu = backupMenu
            extensionsMenu.addItem(backupRoot)
            extensionsMenu.addItem(.separator())
        }

        for clipboardSnippets in extensionRegistry.clipboardSnippets {
            let item = addItem(clipboardSnippets.title, to: extensionsMenu, action: #selector(AppDelegate.showClipboardSnippets(_:)), target: target)
            item.representedObject = clipboardSnippets.id
        }
        if !extensionRegistry.clipboardSnippets.isEmpty {
            extensionsMenu.addItem(.separator())
        }

        if !extensionRegistry.fileOutlines.isEmpty {
            let navigationMenu = NSMenu(title: "Navigation")
            for outline in extensionRegistry.fileOutlines {
                let item = addItem(outline.title, to: navigationMenu, action: #selector(AppDelegate.showFileOutline(_:)), target: target)
                item.representedObject = outline.id
            }
            let navigationRoot = NSMenuItem(title: "Navigation", action: nil, keyEquivalent: "")
            navigationRoot.submenu = navigationMenu
            extensionsMenu.addItem(navigationRoot)
            extensionsMenu.addItem(.separator())
        }

        if !extensionRegistry.csvTableViewers.isEmpty {
            let dataMenu = NSMenu(title: "Data")
            for tableViewer in extensionRegistry.csvTableViewers {
                let item = addItem(tableViewer.title, to: dataMenu, action: #selector(AppDelegate.showCSVTablePreview(_:)), target: target)
                item.representedObject = tableViewer.id
            }
            let dataRoot = NSMenuItem(title: "Data", action: nil, keyEquivalent: "")
            dataRoot.submenu = dataMenu
            extensionsMenu.addItem(dataRoot)
            extensionsMenu.addItem(.separator())
        }

        if !extensionRegistry.encodingLineEndings.isEmpty {
            let textMenu = NSMenu(title: "Text")
            for encodingTool in extensionRegistry.encodingLineEndings {
                let item = addItem(encodingTool.title, to: textMenu, action: #selector(AppDelegate.showEncodingLineEndings(_:)), target: target)
                item.representedObject = encodingTool.id
            }
            textMenu.addItem(.separator())
            let unixItem = addItem("Convert to Unix (LF)", to: textMenu, action: #selector(AppDelegate.convertLineEndings(_:)), target: target)
            unixItem.representedObject = LineEnding.unix.rawValue
            let windowsItem = addItem("Convert to Windows (CRLF)", to: textMenu, action: #selector(AppDelegate.convertLineEndings(_:)), target: target)
            windowsItem.representedObject = LineEnding.windows.rawValue
            let macItem = addItem("Convert to Classic Mac (CR)", to: textMenu, action: #selector(AppDelegate.convertLineEndings(_:)), target: target)
            macItem.representedObject = LineEnding.classicMac.rawValue
            let textRoot = NSMenuItem(title: "Text", action: nil, keyEquivalent: "")
            textRoot.submenu = textMenu
            extensionsMenu.addItem(textRoot)
            extensionsMenu.addItem(.separator())
        }

        if !extensionRegistry.focusModes.isEmpty {
            let viewMenu = NSMenu(title: "View")
            for focusMode in extensionRegistry.focusModes {
                let item = addItem(focusMode.title, to: viewMenu, action: #selector(AppDelegate.toggleFocusMode(_:)), target: target)
                item.representedObject = focusMode.id
            }
            let viewRoot = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
            viewRoot.submenu = viewMenu
            extensionsMenu.addItem(viewRoot)
            extensionsMenu.addItem(.separator())
        }

        for browser in extensionRegistry.documentBrowsers {
            let item = addItem(browser.title, to: extensionsMenu, action: #selector(AppDelegate.showDocumentBrowser(_:)), target: target)
            item.representedObject = browser.id
        }
        if !extensionRegistry.documentBrowsers.isEmpty {
            extensionsMenu.addItem(.separator())
        }

        for clipboard in extensionRegistry.clipboards {
            let clipboardMenu = NSMenu(title: clipboard.title)
            let saveMenu = NSMenu(title: "Save Current Clipboard")
            let copyMenu = NSMenu(title: "Copy Saved Slot")
            let pasteMenu = NSMenu(title: "Paste Saved Slot")

            for slot in 1...clipboard.slotCount {
                let saveItem = addItem("Slot \(slot)", to: saveMenu, action: #selector(AppDelegate.saveClipboardSlot(_:)), target: target)
                saveItem.tag = slot

                let copyItem = addItem("Slot \(slot)", to: copyMenu, action: #selector(AppDelegate.copyClipboardSlot(_:)), target: target)
                copyItem.tag = slot

                let pasteItem = addItem("Slot \(slot)", to: pasteMenu, action: #selector(AppDelegate.pasteClipboardSlot(_:)), target: target)
                pasteItem.tag = slot
            }

            let saveRoot = NSMenuItem(title: "Save Current Clipboard", action: nil, keyEquivalent: "")
            saveRoot.submenu = saveMenu
            clipboardMenu.addItem(saveRoot)

            let copyRoot = NSMenuItem(title: "Copy Saved Slot", action: nil, keyEquivalent: "")
            copyRoot.submenu = copyMenu
            clipboardMenu.addItem(copyRoot)

            let pasteRoot = NSMenuItem(title: "Paste Saved Slot", action: nil, keyEquivalent: "")
            pasteRoot.submenu = pasteMenu
            clipboardMenu.addItem(pasteRoot)

            clipboardMenu.addItem(.separator())
            addItem("Clear All Slots", to: clipboardMenu, action: #selector(AppDelegate.clearClipboardSlots(_:)), target: target)

            let clipboardRoot = NSMenuItem(title: clipboard.title, action: nil, keyEquivalent: "")
            clipboardRoot.submenu = clipboardMenu
            extensionsMenu.addItem(clipboardRoot)
        }
        if !extensionRegistry.clipboards.isEmpty {
            extensionsMenu.addItem(.separator())
        }

        let themesMenu = NSMenu(title: "Themes")
        for (index, theme) in extensionRegistry.themes.enumerated() {
            let item = addItem(theme.name, to: themesMenu, action: #selector(AppDelegate.applyTheme(_:)), target: target)
            item.tag = index
        }
        let themesRoot = NSMenuItem(title: "Themes", action: nil, keyEquivalent: "")
        themesRoot.submenu = themesMenu
        extensionsMenu.addItem(themesRoot)
        extensionsMenu.addItem(.separator())

        let formattersMenu = NSMenu(title: "Format As")
        for formatter in extensionRegistry.formatters {
            let item = addItem(formatter.name, to: formattersMenu, action: #selector(AppDelegate.runCodeFormatter(_:)), target: target)
            item.representedObject = formatter.id
        }
        let formatRoot = NSMenuItem(title: "Format As", action: nil, keyEquivalent: "")
        formatRoot.submenu = formattersMenu
        extensionsMenu.addItem(formatRoot)
        extensionsMenu.addItem(.separator())

        for command in extensionRegistry.textCommands {
            let item = addItem(command.title, to: extensionsMenu, action: #selector(AppDelegate.runTextCommand(_:)), target: target)
            item.representedObject = command.id
        }
        mainMenu.addItem(rootItem(for: extensionsMenu))

        let viewMenu = NSMenu(title: "View")
        addItem("Zoom In", to: viewMenu, action: #selector(AppDelegate.zoomIn(_:)), target: target, key: "+")
        addItem("Zoom Out", to: viewMenu, action: #selector(AppDelegate.zoomOut(_:)), target: target, key: "-")
        addItem("Restore Default Zoom", to: viewMenu, action: #selector(AppDelegate.restoreZoom(_:)), target: target, key: "0")
        viewMenu.addItem(.separator())
        addItem("Status Bar", to: viewMenu, action: #selector(AppDelegate.toggleStatusBar(_:)), target: target, key: "/", modifiers: [.command])
        mainMenu.addItem(rootItem(for: viewMenu))

        let windowMenu = NSMenu(title: "Window")
        addItem("Minimize", to: windowMenu, action: #selector(NSWindow.miniaturize(_:)), target: nil, key: "m")
        addItem("Zoom", to: windowMenu, action: #selector(NSWindow.performZoom(_:)), target: nil)
        windowMenu.addItem(.separator())
        addItem("Show Previous Tab", to: windowMenu, action: #selector(NSWindow.selectPreviousTab(_:)), target: nil, key: "[", modifiers: [.command, .shift])
        addItem("Show Next Tab", to: windowMenu, action: #selector(NSWindow.selectNextTab(_:)), target: nil, key: "]", modifiers: [.command, .shift])
        mainMenu.addItem(rootItem(for: windowMenu))
        NSApp.windowsMenu = windowMenu

        return mainMenu
    }

    private static func rootItem(for submenu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem()
        item.submenu = submenu
        return item
    }

    @discardableResult
    private static func addItem(
        _ title: String,
        to menu: NSMenu,
        action: Selector?,
        target: AnyObject?,
        key: String = "",
        modifiers: NSEvent.ModifierFlags = [.command]
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = target
        item.keyEquivalentModifierMask = modifiers
        menu.addItem(item)
        return item
    }
}
