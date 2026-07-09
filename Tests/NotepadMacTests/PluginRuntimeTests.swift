import XCTest
@testable import NotepadMacCore

final class PluginRuntimeTests: XCTestCase {
    func testExtensionCatalogDecodesTrustMetadataAndScriptCommand() throws {
        let data = """
        {
          "extensions": [
            {
              "id": "title-case-command",
              "title": "Title Case Command",
              "description": "Convert selected text to title case.",
              "version": "1.0.0",
              "kind": "textCommand",
              "author": "MacPad Pro Examples",
              "permissions": ["readSelectedText", "editSelectedText"],
              "downloadURL": "https://example.com/title-case-command.macpadproext"
            }
          ]
        }
        """.data(using: .utf8)!

        let catalog = try JSONDecoder().decode(ExtensionCatalog.self, from: data)
        let extensionItem = try XCTUnwrap(catalog.extension(withID: "title-case-command"))

        XCTAssertEqual(extensionItem.author, "MacPad Pro Examples")
        XCTAssertEqual(extensionItem.permissions, [.readSelectedText, .editSelectedText])
    }

    func testManifestDecodesScriptTextCommandPackage() throws {
        let data = """
        {
          "id": "title-case-command",
          "title": "Title Case Command",
          "description": "Convert selected text to title case.",
          "version": "1.0.0",
          "kind": "textCommand",
          "author": "MacPad Pro Examples",
          "permissions": ["readSelectedText", "editSelectedText"],
          "scriptCommand": {
            "id": "title-case-command",
            "title": "Title Case Selection",
            "scriptFile": "transform.js",
            "sourceURL": "https://example.com/transform.js",
            "sourceSHA256": "c72bb59b7f0fcad0b6dbcf30410e5e0bed6c0f4dd29d0f9d4fe682cb44970c25"
          }
        }
        """.data(using: .utf8)!

        let manifest = try JSONDecoder().decode(ExtensionPackageManifest.self, from: data)

        XCTAssertEqual(manifest.author, "MacPad Pro Examples")
        XCTAssertEqual(manifest.permissions, [.readSelectedText, .editSelectedText])
        XCTAssertEqual(manifest.scriptCommand?.scriptFile, "transform.js")
        XCTAssertEqual(manifest.scriptCommand?.sourceSHA256, "c72bb59b7f0fcad0b6dbcf30410e5e0bed6c0f4dd29d0f9d4fe682cb44970c25")
    }

    func testScriptTextCommandTransformsSelectedText() throws {
        let scriptURL = try writeScript(
            extensionID: "uppercase-command",
            script: "function transform(input) { return input.toUpperCase(); }\n"
        )
        let command = ScriptTextCommand(
            id: "uppercase-command",
            title: "Uppercase Script",
            scriptURL: scriptURL
        )

        XCTAssertEqual(try command.transform("MacPad Pro"), "MACPAD PRO")
    }

    func testRegistryLoadsActiveScriptTextCommandFromInstalledPackage() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = ExtensionPackageStore(directory: tempDirectory)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        try Data("""
        {
          "id": "uppercase-command",
          "title": "Uppercase Command",
          "description": "Uppercase selected text.",
          "version": "1.0.0",
          "kind": "textCommand",
          "permissions": ["readSelectedText", "editSelectedText"],
          "scriptCommand": {
            "id": "uppercase-command",
            "title": "Uppercase Script",
            "scriptFile": "transform.js"
          }
        }
        """.utf8).write(to: store.packageURL(for: "uppercase-command"))
        let scriptURL = store.scriptURL(for: "uppercase-command", scriptFile: "transform.js")
        try FileManager.default.createDirectory(at: scriptURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("function transform(input) { return input.toUpperCase(); }\n".utf8).write(to: scriptURL)

        let registry = ExtensionRegistry.loaded(
            installedExtensions: InstalledExtensions(installedIDs: ["uppercase-command"]),
            packageStore: store
        )
        let command = try XCTUnwrap(registry.textCommands.first { $0.id == "uppercase-command" })

        XCTAssertEqual(try command.transform("selected text"), "SELECTED TEXT")
    }

    func testPackageStoreReportsInstalledVersionAndUpdateAvailability() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = ExtensionPackageStore(directory: tempDirectory)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        try Data("""
        {
          "id": "sample-extension",
          "title": "Sample",
          "description": "Sample extension.",
          "version": "1.0.0",
          "kind": "formatter"
        }
        """.utf8).write(to: store.packageURL(for: "sample-extension"))
        let catalogEntry = DownloadableExtension(
            id: "sample-extension",
            title: "Sample",
            description: "Sample extension.",
            version: "1.1.0",
            kind: .formatter,
            downloadURL: tempDirectory.appendingPathComponent("sample-extension.macpadproext")
        )

        XCTAssertEqual(try store.installedVersion(for: "sample-extension"), "1.0.0")
        XCTAssertTrue(store.hasUpdateAvailable(for: catalogEntry))
    }

    func testPackageStoreRejectsScriptPackageWhenLocalScriptIsMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = ExtensionPackageStore(directory: tempDirectory)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        try Data("""
        {
          "id": "uppercase-command",
          "title": "Uppercase Command",
          "description": "Uppercase selected text.",
          "version": "1.0.0",
          "kind": "textCommand",
          "scriptCommand": {
            "id": "uppercase-command",
            "title": "Uppercase Script",
            "scriptFile": "transform.js",
            "sourceSHA256": "c72bb59b7f0fcad0b6dbcf30410e5e0bed6c0f4dd29d0f9d4fe682cb44970c25"
          }
        }
        """.utf8).write(to: store.packageURL(for: "uppercase-command"))
        let extensionItem = DownloadableExtension(
            id: "uppercase-command",
            title: "Uppercase Command",
            description: "Uppercase selected text.",
            version: "1.0.0",
            kind: .textCommand,
            downloadURL: tempDirectory.appendingPathComponent("uppercase-command.macpadproext")
        )

        XCTAssertThrowsError(try store.validateInstalledPackage(for: extensionItem))
    }

    func testDownloaderRejectsScriptWithWrongChecksum() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let sourceURL = tempDirectory.appendingPathComponent("source.macpadproext")
        let scriptURL = tempDirectory.appendingPathComponent("transform.js")
        let destinationDirectory = tempDirectory.appendingPathComponent("Installed", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        try Data("function transform(input) { return input.toUpperCase(); }\n".utf8).write(to: scriptURL)
        try Data("""
        {
          "id": "uppercase-command",
          "title": "Uppercase Command",
          "description": "Uppercase selected text.",
          "version": "1.0.0",
          "kind": "textCommand",
          "scriptCommand": {
            "id": "uppercase-command",
            "title": "Uppercase Script",
            "scriptFile": "transform.js",
            "sourceURL": "\(scriptURL.absoluteString)",
            "sourceSHA256": "0000000000000000000000000000000000000000000000000000000000000000"
          }
        }
        """.utf8).write(to: sourceURL)
        let extensionItem = DownloadableExtension(
            id: "uppercase-command",
            title: "Uppercase Command",
            description: "Uppercase selected text.",
            version: "1.0.0",
            kind: .textCommand,
            downloadURL: sourceURL
        )

        XCTAssertThrowsError(try ExtensionPackageDownloader().download(extensionItem, into: destinationDirectory))
    }

    private func writeScript(extensionID: String, script: String) throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = ExtensionPackageStore(directory: tempDirectory)
        let scriptURL = store.scriptURL(for: extensionID, scriptFile: "transform.js")
        try FileManager.default.createDirectory(at: scriptURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(script.utf8).write(to: scriptURL)
        addTeardownBlock { try? FileManager.default.removeItem(at: tempDirectory) }
        return scriptURL
    }
}
