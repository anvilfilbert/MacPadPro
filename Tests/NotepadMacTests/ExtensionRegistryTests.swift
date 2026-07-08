import XCTest
@testable import NotepadMacCore

final class ExtensionRegistryTests: XCTestCase {
    func testDefaultRegistryIncludesThemeLanguageCommandAndFormatterExtensions() {
        let registry = ExtensionRegistry.default

        XCTAssertTrue(registry.languages.contains { $0.id == "php" })
        XCTAssertTrue(registry.textCommands.contains { $0.id == "trim-trailing-whitespace" })
        XCTAssertEqual(registry.themes.map(\.id), ["system"])
        XCTAssertTrue(registry.formatters.isEmpty)
        XCTAssertTrue(registry.documentBrowsers.isEmpty)
    }

    func testBundledDefaultDoesNotPreinstallDownloadableExtensions() {
        let installed = InstalledExtensions.bundledDefault

        XCTAssertTrue(installed.installedIDs.isEmpty)
        for extensionItem in ExtensionCatalog.default.extensions {
            XCTAssertFalse(installed.isInstalled(extensionItem.id))
        }
    }

    func testDocumentBrowserExtensionDeclaresDetachedResizableClosableWindowCapabilities() throws {
        let registry = ExtensionRegistry.loaded(installedExtensions: InstalledExtensions(installedIDs: ["open-documents"]))
        let browser = try XCTUnwrap(registry.documentBrowsers.first { $0.id == "open-documents" })

        XCTAssertEqual(browser.title, "Document Browser")
        XCTAssertTrue(browser.opensDetachedWindow)
        XCTAssertTrue(browser.isResizable)
        XCTAssertTrue(browser.isClosable)
    }

    func testExtensionCatalogDecodesSeparateDownloadableExtensions() throws {
        let data = """
        {
          "extensions": [
            {
              "id": "open-documents",
              "title": "Document Browser",
              "description": "Browse and focus open documents in a detached window.",
              "version": "1.0.0",
              "kind": "documentBrowser",
              "downloadURL": "https://example.com/extensions/open-documents.macpadproext"
            },
            {
              "id": "json-formatter",
              "title": "JSON Formatter",
              "description": "Format JSON documents with stable indentation and sorted keys.",
              "version": "1.0.0",
              "kind": "formatter",
              "downloadURL": "https://example.com/extensions/json-formatter.macpadproext"
            }
          ]
        }
        """.data(using: .utf8)!

        let catalog = try JSONDecoder().decode(ExtensionCatalog.self, from: data)

        XCTAssertEqual(catalog.extensions.count, 2)
        XCTAssertEqual(catalog.extension(withID: "open-documents")?.downloadURL.absoluteString, "https://example.com/extensions/open-documents.macpadproext")
        XCTAssertEqual(catalog.extension(withID: "open-documents")?.description, "Browse and focus open documents in a detached window.")
        XCTAssertEqual(catalog.extension(withID: "json-formatter")?.kind, .formatter)
    }

    func testExtensionCatalogExposesOneDownloadPerExtension() {
        let catalog = ExtensionCatalog.default

        XCTAssertTrue(catalog.extensions.contains { $0.id == "open-documents" && $0.kind == .documentBrowser })
        XCTAssertTrue(catalog.extensions.contains { $0.id == "json-formatter" && $0.kind == .formatter })
        XCTAssertTrue(catalog.extensions.contains { $0.id == "c-family-formatter" && $0.kind == .formatter })
        XCTAssertEqual(Set(catalog.extensions.map(\.id)).count, catalog.extensions.count)
    }

    func testDefaultCatalogDownloadsFromMacPadProGitHubRepository() throws {
        let catalog = ExtensionCatalog.default

        for extensionItem in catalog.extensions {
            let url = extensionItem.downloadURL
            XCTAssertEqual(url.scheme, "https")
            XCTAssertEqual(url.host, "raw.githubusercontent.com")
            XCTAssertTrue(url.path.contains("/anvilfilbert/MacPadPro/"))
            XCTAssertTrue(url.lastPathComponent.hasSuffix(".macpadproext"))
        }
    }

    func testCatalogSearchMatchesTitleDescriptionKindAndID() {
        let catalog = ExtensionCatalog.default

        XCTAssertEqual(catalog.search(matching: "json").map(\.id), ["json-formatter"])
        XCTAssertEqual(catalog.search(matching: "php").map(\.id), ["c-family-formatter"])
        XCTAssertEqual(catalog.search(matching: "c++").map(\.id), ["c-family-formatter"])
        XCTAssertEqual(catalog.search(matching: "detached").map(\.id), ["open-documents"])
        XCTAssertEqual(catalog.search(matching: "theme").map(\.id), ["pro-themes"])
        XCTAssertEqual(catalog.search(matching: "OPEN").map(\.id), ["open-documents"])
        XCTAssertEqual(catalog.search(matching: "").map(\.id), catalog.extensions.map(\.id))
    }

    func testRepositoryCatalogURLPointsToMacPadProGitHubRepo() {
        let url = ExtensionRepository.macPadProGitHubCatalogURL

        XCTAssertEqual(url.scheme, "https")
        XCTAssertEqual(url.host, "raw.githubusercontent.com")
        XCTAssertTrue(url.path.contains("/anvilfilbert/MacPadPro/"))
        XCTAssertTrue(url.path.hasSuffix("/RepositoryExtensions/catalog.json"))
    }

    func testExtensionRepositoryCatalogLoaderDecodesCatalogFromURL() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let catalogURL = tempDirectory.appendingPathComponent("catalog.json")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        try Data("""
        {
          "extensions": [
            {
              "id": "repo-extension",
              "title": "Repository Extension",
              "description": "Loaded from a repository catalog.",
              "version": "1.0.0",
              "kind": "textCommand",
              "downloadURL": "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/repo-extension/repo-extension.macpadproext"
            }
          ]
        }
        """.utf8).write(to: catalogURL)
        defer {
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        let catalog = try ExtensionRepositoryCatalogLoader().loadCatalog(from: catalogURL)

        XCTAssertEqual(catalog.extensions.map(\.id), ["repo-extension"])
        XCTAssertEqual(catalog.search(matching: "repository").map(\.id), ["repo-extension"])
    }

    func testExtensionPackageDownloaderSavesPackageByExtensionID() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let sourceURL = tempDirectory.appendingPathComponent("source.macpadproext")
        let destinationDirectory = tempDirectory.appendingPathComponent("Installed", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        try Data("""
        {
          "id": "sample-extension",
          "title": "Sample",
          "description": "Sample extension.",
          "version": "1.0.0",
          "kind": "formatter"
        }
        """.utf8).write(to: sourceURL)
        defer {
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        let extensionItem = DownloadableExtension(
            id: "sample-extension",
            title: "Sample",
            description: "Sample extension.",
            version: "1.0.0",
            kind: .formatter,
            downloadURL: sourceURL
        )

        let savedURL = try ExtensionPackageDownloader().download(extensionItem, into: destinationDirectory)

        XCTAssertEqual(savedURL.lastPathComponent, "sample-extension.macpadproext")
        let manifest = try JSONDecoder().decode(ExtensionPackageManifest.self, from: Data(contentsOf: savedURL))
        XCTAssertEqual(manifest.id, "sample-extension")
        XCTAssertEqual(manifest.description, "Sample extension.")
    }

    func testExtensionPackageDownloaderRejectsMismatchedPackageID() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let sourceURL = tempDirectory.appendingPathComponent("source.macpadproext")
        let destinationDirectory = tempDirectory.appendingPathComponent("Installed", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        try Data("""
        {
          "id": "other-extension",
          "title": "Other",
          "description": "Wrong package.",
          "version": "1.0.0",
          "kind": "formatter"
        }
        """.utf8).write(to: sourceURL)
        defer {
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        let extensionItem = DownloadableExtension(
            id: "sample-extension",
            title: "Sample",
            description: "Sample extension.",
            version: "1.0.0",
            kind: .formatter,
            downloadURL: sourceURL
        )

        XCTAssertThrowsError(try ExtensionPackageDownloader().download(extensionItem, into: destinationDirectory))
        XCTAssertFalse(FileManager.default.fileExists(atPath: destinationDirectory.appendingPathComponent("sample-extension.macpadproext").path))
    }

    func testExtensionPackageStoreDetectsAndValidatesLocalPackage() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        let extensionItem = DownloadableExtension(
            id: "sample-extension",
            title: "Sample",
            description: "Sample extension.",
            version: "1.0.0",
            kind: .formatter,
            downloadURL: tempDirectory.appendingPathComponent("source.macpadproext")
        )
        let packageURL = ExtensionPackageStore(directory: tempDirectory).packageURL(for: extensionItem.id)
        try Data("""
        {
          "id": "sample-extension",
          "title": "Sample",
          "description": "Sample extension.",
          "version": "1.0.0",
          "kind": "formatter"
        }
        """.utf8).write(to: packageURL)

        let store = ExtensionPackageStore(directory: tempDirectory)

        XCTAssertTrue(store.hasPackage(for: extensionItem.id))
        XCTAssertNoThrow(try store.validateInstalledPackage(for: extensionItem))
    }

    func testExtensionPackageStoreRejectsMismatchedLocalPackage() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        let extensionItem = DownloadableExtension(
            id: "sample-extension",
            title: "Sample",
            description: "Sample extension.",
            version: "1.0.0",
            kind: .formatter,
            downloadURL: tempDirectory.appendingPathComponent("source.macpadproext")
        )
        let packageURL = ExtensionPackageStore(directory: tempDirectory).packageURL(for: extensionItem.id)
        try Data("""
        {
          "id": "sample-extension",
          "title": "Sample",
          "description": "Sample extension.",
          "version": "2.0.0",
          "kind": "formatter"
        }
        """.utf8).write(to: packageURL)

        let store = ExtensionPackageStore(directory: tempDirectory)

        XCTAssertTrue(store.hasPackage(for: extensionItem.id))
        XCTAssertThrowsError(try store.validateInstalledPackage(for: extensionItem))
    }

    func testExtensionPackageStoreReportsOnlyValidatedPackagesAsLoadable() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        let extensionItem = DownloadableExtension(
            id: "sample-extension",
            title: "Sample",
            description: "Sample extension.",
            version: "1.0.0",
            kind: .formatter,
            downloadURL: tempDirectory.appendingPathComponent("source.macpadproext")
        )
        let store = ExtensionPackageStore(directory: tempDirectory)

        XCTAssertFalse(store.hasValidatedPackage(for: extensionItem))

        try Data("""
        {
          "id": "sample-extension",
          "title": "Sample",
          "description": "Sample extension.",
          "version": "2.0.0",
          "kind": "formatter"
        }
        """.utf8).write(to: store.packageURL(for: extensionItem.id))

        XCTAssertTrue(store.hasPackage(for: extensionItem.id))
        XCTAssertFalse(store.hasValidatedPackage(for: extensionItem))

        try Data("""
        {
          "id": "sample-extension",
          "title": "Sample",
          "description": "Sample extension.",
          "version": "1.0.0",
          "kind": "formatter"
        }
        """.utf8).write(to: store.packageURL(for: extensionItem.id))

        XCTAssertTrue(store.hasValidatedPackage(for: extensionItem))
    }

    func testExtensionCatalogIncludesDescriptionsForExtensionManager() {
        let catalog = ExtensionCatalog.default

        XCTAssertEqual(
            catalog.extension(withID: "open-documents")?.description,
            "Browse open documents in a detached, resizable, closable window."
        )
        XCTAssertEqual(
            catalog.extension(withID: "json-formatter")?.description,
            "Format JSON documents with stable indentation and sorted keys."
        )
        XCTAssertEqual(
            catalog.extension(withID: "c-family-formatter")?.description,
            "Format PHP, C, C++, Java, JavaScript, TypeScript, and CSS brace-style code."
        )
    }

    func testEachDownloadableExtensionHasOwnSourceDirectory() throws {
        let catalog = ExtensionCatalog.default
        let testFile = URL(fileURLWithPath: #filePath)
        let repoRoot = testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let extensionsRoot = repoRoot
            .appendingPathComponent("Sources")
            .appendingPathComponent("NotepadMacCore")
            .appendingPathComponent("Extensions")

        for extensionItem in catalog.extensions {
            let extensionDirectory = extensionsRoot.appendingPathComponent(extensionItem.id)
            var isDirectory: ObjCBool = false

            XCTAssertTrue(
                FileManager.default.fileExists(atPath: extensionDirectory.path, isDirectory: &isDirectory),
                "\(extensionItem.id) should have its own extension directory"
            )
            XCTAssertTrue(isDirectory.boolValue, "\(extensionItem.id) extension path should be a directory")

            let swiftFiles = try FileManager.default.contentsOfDirectory(at: extensionDirectory, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "swift" }
            XCTAssertFalse(swiftFiles.isEmpty, "\(extensionItem.id) extension directory should contain Swift files")
        }
    }

    func testInstalledExtensionsCanLoadAndDeleteOneExtensionAtATime() {
        var installed = InstalledExtensions(installedIDs: ["json-formatter"])

        XCTAssertTrue(installed.isInstalled("json-formatter"))
        XCTAssertFalse(installed.isInstalled("open-documents"))

        installed.load("open-documents")
        XCTAssertTrue(installed.isInstalled("open-documents"))

        installed.delete("json-formatter")
        XCTAssertFalse(installed.isInstalled("json-formatter"))
        XCTAssertTrue(installed.isInstalled("open-documents"))
    }

    func testInstalledExtensionsCanDeactivateAndReactivateWithoutDeleting() {
        var installed = InstalledExtensions(installedIDs: ["open-documents"])

        XCTAssertTrue(installed.isInstalled("open-documents"))
        XCTAssertTrue(installed.isActive("open-documents"))

        installed.deactivate("open-documents")
        XCTAssertTrue(installed.isInstalled("open-documents"))
        XCTAssertFalse(installed.isActive("open-documents"))

        installed.activate("open-documents")
        XCTAssertTrue(installed.isInstalled("open-documents"))
        XCTAssertTrue(installed.isActive("open-documents"))
    }

    func testInstalledExtensionsDecodesLegacyStateWithoutDeactivatedIDs() throws {
        let data = """
        {
          "installedIDs": ["json-formatter"]
        }
        """.data(using: .utf8)!

        let installed = try JSONDecoder().decode(InstalledExtensions.self, from: data)

        XCTAssertTrue(installed.isInstalled("json-formatter"))
        XCTAssertTrue(installed.isActive("json-formatter"))
    }

    func testRegistryLoadsDocumentBrowserOnlyWhenInstalled() {
        let withoutBrowser = ExtensionRegistry.loaded(installedExtensions: InstalledExtensions(installedIDs: []))
        let withBrowser = ExtensionRegistry.loaded(installedExtensions: InstalledExtensions(installedIDs: ["open-documents"]))

        XCTAssertTrue(withoutBrowser.documentBrowsers.isEmpty)
        XCTAssertEqual(withBrowser.documentBrowsers.first?.id, "open-documents")
    }

    func testRegistryDoesNotLoadDeactivatedDocumentBrowser() {
        var installed = InstalledExtensions(installedIDs: ["open-documents"])
        installed.deactivate("open-documents")

        let registry = ExtensionRegistry.loaded(installedExtensions: installed)

        XCTAssertTrue(registry.documentBrowsers.isEmpty)
        XCTAssertTrue(installed.isInstalled("open-documents"))
    }

    func testRegistryLoadsJsonFormatterOnlyWhenInstalled() {
        let withoutFormatter = ExtensionRegistry.loaded(installedExtensions: InstalledExtensions(installedIDs: []))
        let withFormatter = ExtensionRegistry.loaded(installedExtensions: InstalledExtensions(installedIDs: ["json-formatter"]))

        XCTAssertNil(withoutFormatter.formatter(named: "json"))
        XCTAssertEqual(withFormatter.formatter(named: "json")?.id, "json")
    }

    func testRegistryLoadsCFamilyFormatterOnlyWhenInstalled() {
        let withoutFormatter = ExtensionRegistry.loaded(installedExtensions: InstalledExtensions(installedIDs: []))
        let withFormatter = ExtensionRegistry.loaded(installedExtensions: InstalledExtensions(installedIDs: ["c-family-formatter"]))

        XCTAssertNil(withoutFormatter.formatter(named: "c-family"))
        XCTAssertEqual(withFormatter.formatter(forLanguageID: "cpp")?.id, "c-family")
        XCTAssertEqual(withFormatter.formatter(forLanguageID: "php")?.id, "c-family")
    }

    func testRegistryAlwaysKeepsSystemThemeAndLoadsProThemesWhenInstalled() {
        let base = ExtensionRegistry.loaded(installedExtensions: InstalledExtensions(installedIDs: []))
        let withThemes = ExtensionRegistry.loaded(installedExtensions: InstalledExtensions(installedIDs: ["pro-themes"]))

        XCTAssertEqual(base.themes.map(\.id), ["system"])
        XCTAssertTrue(withThemes.themes.contains { $0.id == "night" })
    }

    func testLanguageDetectionRecognizesPhpAndCppExtensions() {
        let registry = ExtensionRegistry.default

        XCTAssertEqual(registry.detectLanguage(for: URL(fileURLWithPath: "/tmp/index.php"), text: ""), "PHP")
        XCTAssertEqual(registry.detectLanguage(for: URL(fileURLWithPath: "/tmp/main.cpp"), text: ""), "C++")
    }

    func testLanguageDetectionRecognizesJsonByContent() {
        let registry = ExtensionRegistry.default

        XCTAssertEqual(registry.detectLanguage(for: nil, text: "{\"name\":\"MacPad Pro\"}"), "JSON")
    }

    func testJsonFormatterPrettyPrintsDocument() throws {
        let registry = ExtensionRegistry.loaded(installedExtensions: InstalledExtensions(installedIDs: ["json-formatter"]))
        let formatter = try XCTUnwrap(registry.formatter(forLanguageID: "json"))

        let formatted = try formatter.format("{\"b\":2,\"a\":1}")

        XCTAssertEqual(formatted, """
        {
          "a" : 1,
          "b" : 2
        }
        """)
    }

    func testCFamilyFormatterFormatsCppBracesAndStatements() throws {
        let registry = ExtensionRegistry.loaded(installedExtensions: InstalledExtensions(installedIDs: ["c-family-formatter"]))
        let formatter = try XCTUnwrap(registry.formatter(forLanguageID: "cpp"))

        let formatted = try formatter.format("int main(){return 0;}")

        XCTAssertEqual(formatted, """
        int main() {
          return 0;
        }
        """)
    }

    func testCFamilyFormatterFormatsPhpBracesAndStatements() throws {
        let registry = ExtensionRegistry.loaded(installedExtensions: InstalledExtensions(installedIDs: ["c-family-formatter"]))
        let formatter = try XCTUnwrap(registry.formatter(forLanguageID: "php"))

        let formatted = try formatter.format("<?php\nif($ready){echo \"yes\";}")

        XCTAssertEqual(formatted, """
        <?php
        if($ready) {
          echo "yes";
        }
        """)
    }
}
