import XCTest
@testable import NotepadMacCore

final class ExtensionRegistryTests: XCTestCase {
    func testDefaultRegistryIncludesThemeLanguageCommandAndFormatterExtensions() {
        let registry = ExtensionRegistry.default

        XCTAssertTrue(registry.themes.contains { $0.id == "night" })
        XCTAssertTrue(registry.languages.contains { $0.id == "php" })
        XCTAssertTrue(registry.textCommands.contains { $0.id == "trim-trailing-whitespace" })
        XCTAssertTrue(registry.formatters.contains { $0.id == "json" })
        XCTAssertTrue(registry.documentBrowsers.contains { $0.id == "open-documents" })
    }

    func testDocumentBrowserExtensionDeclaresDetachedResizableClosableWindowCapabilities() throws {
        let registry = ExtensionRegistry.default
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
              "version": "1.0.0",
              "kind": "documentBrowser",
              "downloadURL": "https://example.com/extensions/open-documents.macpadproext"
            },
            {
              "id": "json-formatter",
              "title": "JSON Formatter",
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
        XCTAssertEqual(catalog.extension(withID: "json-formatter")?.kind, .formatter)
    }

    func testExtensionCatalogExposesOneDownloadPerExtension() {
        let catalog = ExtensionCatalog.default

        XCTAssertTrue(catalog.extensions.contains { $0.id == "open-documents" && $0.kind == .documentBrowser })
        XCTAssertTrue(catalog.extensions.contains { $0.id == "json-formatter" && $0.kind == .formatter })
        XCTAssertEqual(Set(catalog.extensions.map(\.id)).count, catalog.extensions.count)
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

    func testRegistryLoadsDocumentBrowserOnlyWhenInstalled() {
        let withoutBrowser = ExtensionRegistry.loaded(installedExtensions: InstalledExtensions(installedIDs: []))
        let withBrowser = ExtensionRegistry.loaded(installedExtensions: InstalledExtensions(installedIDs: ["open-documents"]))

        XCTAssertTrue(withoutBrowser.documentBrowsers.isEmpty)
        XCTAssertEqual(withBrowser.documentBrowsers.first?.id, "open-documents")
    }

    func testRegistryLoadsJsonFormatterOnlyWhenInstalled() {
        let withoutFormatter = ExtensionRegistry.loaded(installedExtensions: InstalledExtensions(installedIDs: []))
        let withFormatter = ExtensionRegistry.loaded(installedExtensions: InstalledExtensions(installedIDs: ["json-formatter"]))

        XCTAssertNil(withoutFormatter.formatter(named: "json"))
        XCTAssertEqual(withFormatter.formatter(named: "json")?.id, "json")
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
        let registry = ExtensionRegistry.default
        let formatter = try XCTUnwrap(registry.formatter(forLanguageID: "json"))

        let formatted = try formatter.format("{\"b\":2,\"a\":1}")

        XCTAssertEqual(formatted, """
        {
          "a" : 1,
          "b" : 2
        }
        """)
    }
}
