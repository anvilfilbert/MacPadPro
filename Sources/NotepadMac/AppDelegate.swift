import AppKit
import NotepadMacCore
import Security

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let sessionDefaultsKey = "MacPadPro.SessionState.v1"
    private let installedExtensionsDefaultsKey = "MacPadPro.InstalledExtensions.v1"
    private let clipboardSlotsDefaultsKey = "MacPadPro.ClipboardSlots.v1"
    private let aiAgentSettingsDefaultsKey = "MacPadPro.AIAgentSettings.v1"
    private let aiAgentKeychainService = "local.macpadpro.ai-agent"
    private let aiAgentKeychainAccount = "api-token"
    private var extensionCatalog = ExtensionCatalog.default
    private let extensionCatalogLoader = ExtensionRepositoryCatalogLoader()
    private let extensionPackageDownloader = ExtensionPackageDownloader()
    private var installedExtensions = InstalledExtensions.bundledDefault
    private var clipboardSlots = ClipboardSlotStore(slotCount: 10)
    private var windows: [EditorWindowController] = []
    private var documentBrowserController: DocumentBrowserWindowController?
    private var extensionManagerController: ExtensionManagerWindowController?
    private var aiAgentSettingsController: AIAgentSettingsWindowController?
    private var aiSmartSearchController: AISmartSearchWindowController?
    private var isRestoringSession = false

    private var extensionRegistry: ExtensionRegistry {
        ExtensionRegistry.loaded(installedExtensions: installedExtensions)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        installedExtensions = loadInstalledExtensions()
        clipboardSlots = loadClipboardSlots()
        rebuildMainMenu()
        if !restorePreviousSession() {
            openNewDocument(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        var confirmedControllers: [EditorWindowController] = []
        for controller in windows {
            if !controller.confirmDiscardIfNeeded() {
                for confirmedController in confirmedControllers {
                    confirmedController.keepInSessionRestore()
                }
                saveSession()
                return .terminateCancel
            }
            confirmedControllers.append(controller)
        }
        saveSession()
        return .terminateNow
    }

    func application(_ sender: NSApplication, open urls: [URL]) {
        for url in urls {
            openDocument(url: url)
        }
    }

    @objc func openNewDocument(_ sender: Any?) {
        openNewTab(sender)
    }

    @objc func openNewWindow(_ sender: Any?) {
        present(makeWindowController(), asTab: false)
    }

    @objc func openNewTab(_ sender: Any?) {
        present(makeWindowController(), asTab: keyWindowController != nil)
    }

    @objc func openDocument(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText, .text, .data]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            openDocument(url: url)
        }
    }

    private func openDocument(url: URL) {
        let controller = makeWindowController()
        present(controller, asTab: keyWindowController != nil)
        controller.loadFile(url)
    }

    private func makeWindowController() -> EditorWindowController {
        let controller = EditorWindowController(extensionRegistryProvider: { [weak self] in
            self?.extensionRegistry ?? .default
        })
        controller.onClose = { [weak self, weak controller] in
            guard let controller else { return }
            self?.windows.removeAll { $0 === controller }
            self?.saveSession()
            self?.refreshDocumentBrowser()
        }
        controller.onStateChange = { [weak self] in
            self?.saveSession()
            self?.refreshDocumentBrowser()
        }
        return controller
    }

    private func present(_ controller: EditorWindowController, asTab: Bool) {
        let parentWindow = asTab ? keyWindowController?.window : nil
        windows.append(controller)
        controller.showWindow(nil)

        if let parentWindow,
           let newWindow = controller.window,
           parentWindow !== newWindow {
            parentWindow.addTabbedWindow(newWindow, ordered: .above)
            newWindow.makeKeyAndOrderFront(nil)
        }

        saveSession()
        refreshDocumentBrowser()
    }

    private var keyWindowController: EditorWindowController? {
        windows.first { $0.window?.isKeyWindow == true } ?? windows.last
    }

    @objc func save(_ sender: Any?) { keyWindowController?.save(sender) }
    @objc func saveAs(_ sender: Any?) { keyWindowController?.saveAs(sender) }
    @objc func printDocument(_ sender: Any?) { keyWindowController?.printDocument(sender) }
    @objc func toggleWordWrap(_ sender: Any?) { keyWindowController?.toggleWordWrap(sender) }
    @objc func toggleStatusBar(_ sender: Any?) { keyWindowController?.toggleStatusBar(sender) }
    @objc func showFind(_ sender: Any?) { keyWindowController?.showFind(sender) }
    @objc func showReplace(_ sender: Any?) { keyWindowController?.showReplace(sender) }
    @objc func findNext(_ sender: Any?) { keyWindowController?.findNext(sender) }
    @objc func findPrevious(_ sender: Any?) { keyWindowController?.findPrevious(sender) }
    @objc func goToLine(_ sender: Any?) { keyWindowController?.goToLine(sender) }
    @objc func insertTimeDate(_ sender: Any?) { keyWindowController?.insertTimeDate(sender) }
    @objc func zoomIn(_ sender: Any?) { keyWindowController?.zoomIn(sender) }
    @objc func zoomOut(_ sender: Any?) { keyWindowController?.zoomOut(sender) }
    @objc func restoreZoom(_ sender: Any?) { keyWindowController?.restoreZoom(sender) }
    @objc func chooseFont(_ sender: Any?) { keyWindowController?.chooseFont(sender) }
    @objc func applyTheme(_ sender: NSMenuItem) { keyWindowController?.applyTheme(at: sender.tag) }
    @objc func runTextCommand(_ sender: NSMenuItem) {
        guard let commandID = sender.representedObject as? String,
              let command = extensionRegistry.textCommands.first(where: { $0.id == commandID }) else { return }
        keyWindowController?.runTextCommand(command)
    }
    @objc func runCodeFormatter(_ sender: NSMenuItem) {
        guard let formatterID = sender.representedObject as? String else { return }
        keyWindowController?.runCodeFormatter(id: formatterID)
    }
    @objc func showAIAgentSettings(_ sender: Any?) {
        let controller = aiAgentSettingsController ?? AIAgentSettingsWindowController(
            configuration: loadAIAgentConfiguration(),
            saveSettings: { [weak self] configuration in
                self?.saveAIAgentConfiguration(configuration)
            }
        )
        controller.onClose = { [weak self] in
            self?.aiAgentSettingsController = nil
        }
        aiAgentSettingsController = controller
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
    }
    @objc func runAITextTask(_ sender: NSMenuItem) {
        guard let taskID = sender.representedObject as? String,
              let task = extensionRegistry.aiTextTasks.first(where: { $0.id == taskID }) else { return }
        guard let controller = keyWindowController,
              let selectedText = controller.selectedTextForAI(),
              !selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError("Select text first.", detail: "AI text extensions send only the selected text.")
            return
        }
        guard let configuration = requireAIAgentConfiguration() else { return }

        let prompt = AITextPromptBuilder().prompt(
            for: task,
            selectedText: selectedText,
            fileName: controller.aiFileName,
            languageName: controller.aiLanguageName
        )

        Task {
            do {
                let result = try await AIAgentClient(configuration: configuration).complete(prompt: prompt)
                presentAIResult(result.text, for: task, sourceController: controller)
            } catch {
                showError("AI request failed.", detail: error.localizedDescription)
            }
        }
    }
    @objc func showAISmartSearch(_ sender: NSMenuItem) {
        guard extensionRegistry.aiSmartSearches.contains(where: { $0.id == sender.representedObject as? String }) else { return }
        guard requireAIAgentConfiguration() != nil else { return }

        let controller = aiSmartSearchController ?? AISmartSearchWindowController(
            runSearch: { [weak self] query in
                guard let self else { return [] }
                return try await self.runAISmartSearch(query: query)
            },
            openDocument: { [weak self] id in
                self?.focusDocumentBrowserItem(id: id)
            }
        )
        controller.onClose = { [weak self] in
            self?.aiSmartSearchController = nil
        }
        aiSmartSearchController = controller
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
    }
    @objc func saveClipboardSlot(_ sender: NSMenuItem) {
        guard extensionRegistry.clipboards.isEmpty == false,
              let clipboardText = NSPasteboard.general.string(forType: .string) else {
            NSSound.beep()
            return
        }

        clipboardSlots.save(clipboardText, to: sender.tag)
        saveClipboardSlots()
    }
    @objc func copyClipboardSlot(_ sender: NSMenuItem) {
        guard extensionRegistry.clipboards.isEmpty == false,
              let clipboardText = clipboardSlots.content(in: sender.tag) else {
            NSSound.beep()
            return
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(clipboardText, forType: .string)
    }
    @objc func pasteClipboardSlot(_ sender: NSMenuItem) {
        guard extensionRegistry.clipboards.isEmpty == false,
              let clipboardText = clipboardSlots.content(in: sender.tag) else {
            NSSound.beep()
            return
        }

        keyWindowController?.insertText(clipboardText)
    }
    @objc func clearClipboardSlots(_ sender: Any?) {
        guard extensionRegistry.clipboards.isEmpty == false else { return }
        clipboardSlots.clearAll()
        saveClipboardSlots()
    }
    @objc func showExtensionManager(_ sender: Any?) {
        let controller = extensionManagerController ?? ExtensionManagerWindowController(
            catalog: extensionCatalog,
            installedProvider: { [weak self] in self?.installedExtensions ?? .bundledDefault },
            hasLocalPackage: { [weak self] extensionItem in
                self?.extensionPackageStore.hasValidatedPackage(for: extensionItem) ?? false
            },
            refreshCatalogFromRepository: { [weak self] in
                guard let self else { return .default }
                return try self.refreshExtensionCatalogFromRepository()
            },
            downloadExtension: { [weak self] extensionItem in
                guard let self else { return }
                try self.downloadExtension(extensionItem)
            },
            loadExtension: { [weak self] extensionItem in try self?.loadExtension(extensionItem) },
            activateExtension: { [weak self] id in self?.activateExtension(id: id) },
            deactivateExtension: { [weak self] id in self?.deactivateExtension(id: id) },
            deleteExtension: { [weak self] id in self?.deleteExtension(id: id) }
        )
        controller.onClose = { [weak self] in
            self?.extensionManagerController = nil
        }
        extensionManagerController = controller
        controller.refresh()
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
    }

    @objc func showDocumentBrowser(_ sender: NSMenuItem) {
        guard let browserID = sender.representedObject as? String,
              let browser = extensionRegistry.documentBrowsers.first(where: { $0.id == browserID }) else { return }

        let controller = documentBrowserController ?? DocumentBrowserWindowController(
            title: browser.title,
            documentsProvider: { [weak self] in self?.documentBrowserItems() ?? [] },
            openDocument: { [weak self] item in self?.focusDocumentBrowserItem(id: item.id) }
        )
        controller.onClose = { [weak self] in
            self?.documentBrowserController = nil
        }
        documentBrowserController = controller
        controller.refresh()
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
    }

    private func restorePreviousSession() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: sessionDefaultsKey),
              let session = try? JSONDecoder().decode(AppSessionState.self, from: data),
              !session.windows.isEmpty else {
            return false
        }

        isRestoringSession = true
        defer {
            isRestoringSession = false
            saveSession()
        }

        for windowSession in session.windows {
            for (index, tab) in windowSession.tabs.enumerated() {
                let controller = makeWindowController()
                controller.restoreSessionState(tab)
                present(controller, asTab: index > 0)
            }
        }

        return true
    }

    private func saveSession() {
        guard !isRestoringSession else { return }

        let windowSessions = currentWindowSessions()
        guard !windowSessions.isEmpty else {
            UserDefaults.standard.removeObject(forKey: sessionDefaultsKey)
            return
        }

        if let data = try? JSONEncoder().encode(AppSessionState(windows: windowSessions)) {
            UserDefaults.standard.set(data, forKey: sessionDefaultsKey)
        }
    }

    private func currentWindowSessions() -> [EditorWindowSessionState] {
        let controllerByWindow = Dictionary(
            uniqueKeysWithValues: windows.compactMap { controller -> (ObjectIdentifier, EditorWindowController)? in
                guard let window = controller.window else { return nil }
                return (ObjectIdentifier(window), controller)
            }
        )
        var seenWindows = Set<ObjectIdentifier>()
        var sessions: [EditorWindowSessionState] = []

        for controller in windows {
            guard let window = controller.window else { continue }
            let tabbedWindows = window.tabbedWindows ?? [window]
            let orderedWindows = tabbedWindows.isEmpty ? [window] : tabbedWindows
            let identifiers = orderedWindows.map(ObjectIdentifier.init)

            if identifiers.contains(where: seenWindows.contains) {
                continue
            }

            for identifier in identifiers {
                seenWindows.insert(identifier)
            }

            let tabs = orderedWindows.compactMap { tabWindow in
                controllerByWindow[ObjectIdentifier(tabWindow)]?.sessionState
            }

            if !tabs.isEmpty {
                sessions.append(EditorWindowSessionState(tabs: tabs))
            }
        }

        return sessions
    }

    private func documentBrowserItems() -> [DocumentBrowserItem] {
        windows.map(\.documentBrowserItem)
    }

    private func focusDocumentBrowserItem(id: String) {
        windows.first { $0.documentBrowserItem.id == id }?.focusDocument()
    }

    private func refreshDocumentBrowser() {
        documentBrowserController?.refresh()
    }

    private func loadInstalledExtensions() -> InstalledExtensions {
        guard let data = UserDefaults.standard.data(forKey: installedExtensionsDefaultsKey),
              let installed = try? JSONDecoder().decode(InstalledExtensions.self, from: data) else {
            return .bundledDefault
        }
        return installed
    }

    private func saveInstalledExtensions() {
        if let data = try? JSONEncoder().encode(installedExtensions) {
            UserDefaults.standard.set(data, forKey: installedExtensionsDefaultsKey)
        }
    }

    private func loadClipboardSlots() -> ClipboardSlotStore {
        guard let data = UserDefaults.standard.data(forKey: clipboardSlotsDefaultsKey),
              let store = try? JSONDecoder().decode(ClipboardSlotStore.self, from: data) else {
            return ClipboardSlotStore(slotCount: 10)
        }
        return store
    }

    private func saveClipboardSlots() {
        if let data = try? JSONEncoder().encode(clipboardSlots) {
            UserDefaults.standard.set(data, forKey: clipboardSlotsDefaultsKey)
        }
    }

    private func loadAIAgentConfiguration() -> AIAgentConfiguration? {
        guard let data = UserDefaults.standard.data(forKey: aiAgentSettingsDefaultsKey),
              let stored = try? JSONDecoder().decode(StoredAIAgentSettings.self, from: data),
              let endpointURL = URL(string: stored.endpointURLString),
              !stored.modelName.isEmpty else {
            return nil
        }
        return AIAgentConfiguration(
            endpointURL: endpointURL,
            modelName: stored.modelName,
            apiToken: readAIAgentToken(),
            responseMode: stored.responseMode
        )
    }

    private func saveAIAgentConfiguration(_ configuration: AIAgentConfiguration?) {
        guard let configuration else {
            UserDefaults.standard.removeObject(forKey: aiAgentSettingsDefaultsKey)
            saveAIAgentToken(nil)
            return
        }

        let stored = StoredAIAgentSettings(
            endpointURLString: configuration.endpointURL.absoluteString,
            modelName: configuration.modelName,
            responseMode: configuration.responseMode
        )
        if let data = try? JSONEncoder().encode(stored) {
            UserDefaults.standard.set(data, forKey: aiAgentSettingsDefaultsKey)
        }
        saveAIAgentToken(configuration.apiToken)
    }

    private func requireAIAgentConfiguration() -> AIAgentConfiguration? {
        guard let configuration = loadAIAgentConfiguration() else {
            showError(
                "AI agent is not configured.",
                detail: "Open Extensions > AI Agent Settings... and connect a local or remote OpenAI-compatible agent."
            )
            return nil
        }
        return configuration
    }

    private func presentAIResult(_ text: String, for task: AITextTask, sourceController: EditorWindowController) {
        switch task.resultDisposition {
        case .openDocument, .previewDocument:
            openGeneratedDocument(text)
        case .replaceSelectionOrOpenDocument:
            let alert = NSAlert()
            alert.messageText = task.title
            alert.informativeText = "Use the AI result?"
            alert.addButton(withTitle: "Replace Selection")
            alert.addButton(withTitle: "Open New Document")
            alert.addButton(withTitle: "Cancel")
            switch alert.runModal() {
            case .alertFirstButtonReturn:
                sourceController.replaceSelectedText(with: text)
            case .alertSecondButtonReturn:
                openGeneratedDocument(text)
            default:
                break
            }
        }
    }

    private func openGeneratedDocument(_ text: String) {
        let controller = makeWindowController()
        present(controller, asTab: keyWindowController != nil)
        controller.loadGeneratedText(text)
    }

    private func runAISmartSearch(query: String) async throws -> [AISearchResult] {
        guard let configuration = loadAIAgentConfiguration() else { return [] }
        let documents = windows.map(\.aiSearchDocument)
        let prompt = AITextPromptBuilder().smartSearchPrompt(query: query, documents: documents)
        let result = try await AIAgentClient(configuration: configuration).complete(prompt: prompt)
        return parseAISearchResults(result.text, documents: documents)
    }

    private func parseAISearchResults(_ text: String, documents: [AISearchDocument]) -> [AISearchResult] {
        let documentsByID = Dictionary(uniqueKeysWithValues: documents.map { ($0.id, $0) })
        return text
            .split(separator: "\n")
            .compactMap { line -> AISearchResult? in
                let parts = line.split(separator: "|", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                guard let id = parts.first, let document = documentsByID[id] else { return nil }
                let reason = parts.count > 1 ? parts[1] : document.snippet
                return AISearchResult(documentID: id, title: document.title, reason: reason)
            }
    }

    private func readAIAgentToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: aiAgentKeychainService,
            kSecAttrAccount as String: aiAgentKeychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func saveAIAgentToken(_ token: String?) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: aiAgentKeychainService,
            kSecAttrAccount as String: aiAgentKeychainAccount
        ]
        SecItemDelete(query as CFDictionary)

        guard let token, !token.isEmpty, let data = token.data(using: .utf8) else { return }
        var item = query
        item[kSecValueData as String] = data
        SecItemAdd(item as CFDictionary, nil)
    }

    private func refreshExtensionCatalogFromRepository() throws -> ExtensionCatalog {
        let catalog = try extensionCatalogLoader.loadCatalog()
        extensionCatalog = catalog
        return catalog
    }

    private func downloadExtension(_ extensionItem: DownloadableExtension) throws {
        try extensionPackageDownloader.download(extensionItem, into: extensionPackagesDirectory)
        installedExtensions.load(extensionItem.id)
        saveInstalledExtensions()
        reloadExtensions()
    }

    private var extensionPackagesDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MacPad Pro", isDirectory: true)
            .appendingPathComponent("Extensions", isDirectory: true)
    }

    private var extensionPackageStore: ExtensionPackageStore {
        ExtensionPackageStore(directory: extensionPackagesDirectory)
    }

    private func loadExtension(_ extensionItem: DownloadableExtension) throws {
        try extensionPackageStore.validateInstalledPackage(for: extensionItem)
        installedExtensions.load(extensionItem.id)
        saveInstalledExtensions()
        reloadExtensions()
    }

    private func activateExtension(id: String) {
        installedExtensions.activate(id)
        saveInstalledExtensions()
        reloadExtensions()
    }

    private func deactivateExtension(id: String) {
        installedExtensions.deactivate(id)
        saveInstalledExtensions()
        reloadExtensions()
    }

    private func deleteExtension(id: String) {
        installedExtensions.delete(id)
        let packageURL = extensionPackageStore.packageURL(for: id)
        try? FileManager.default.removeItem(at: packageURL)
        saveInstalledExtensions()
        reloadExtensions()
    }

    private func reloadExtensions() {
        if !installedExtensions.isActive("open-documents") {
            documentBrowserController?.close()
            documentBrowserController = nil
        }
        if !installedExtensions.isActive("ai-smart-search") {
            aiSmartSearchController?.close()
            aiSmartSearchController = nil
        }
        extensionManagerController?.refresh()
        rebuildMainMenu()
    }

    private func rebuildMainMenu() {
        NSApp.mainMenu = MainMenuFactory.makeMenu(target: self, extensionRegistry: extensionRegistry)
    }

    private func showError(_ message: String, detail: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = message
        alert.informativeText = detail
        alert.runModal()
    }
}

private struct StoredAIAgentSettings: Codable {
    let endpointURLString: String
    let modelName: String
    let responseMode: AIAgentResponseMode
}
