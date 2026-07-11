import Foundation

public enum ExtensionRepository {
    public static let macPadProGitHubCatalogURL = URL(
        string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/catalog.json"
    )!
}

public struct ExtensionRepositoryCatalogLoader {
    public init() {}

    public func loadCatalog(from url: URL = ExtensionRepository.macPadProGitHubCatalogURL) throws -> ExtensionCatalog {
        let catalogData = try Data(contentsOf: url)
        return try JSONDecoder().decode(ExtensionCatalog.self, from: catalogData)
    }
}

public struct ExtensionPackageStore {
    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public func packageURL(for extensionID: String) -> URL {
        directory.appendingPathComponent("\(extensionID).macpadproext")
    }

    public func scriptURL(for extensionID: String, scriptFile: String) -> URL {
        directory
            .appendingPathComponent(extensionID, isDirectory: true)
            .appendingPathComponent(scriptFile)
    }

    public func resourceURL(for extensionID: String, resourceFile: String) -> URL {
        directory
            .appendingPathComponent(extensionID, isDirectory: true)
            .appendingPathComponent(resourceFile)
    }

    public func resourceDirectoryURL(for extensionID: String) -> URL {
        directory.appendingPathComponent(extensionID, isDirectory: true)
    }

    public func hasPackage(for extensionID: String) -> Bool {
        FileManager.default.fileExists(atPath: packageURL(for: extensionID).path)
    }

    public func hasValidatedPackage(for extensionItem: DownloadableExtension) -> Bool {
        do {
            try validateInstalledPackage(for: extensionItem)
            return true
        } catch {
            return false
        }
    }

    public func validateInstalledPackage(for extensionItem: DownloadableExtension) throws {
        let manifest = try installedManifest(for: extensionItem.id)
        let validator = ExtensionPackageValidator()
        try validator.validateManifest(manifest, matches: extensionItem)
        try validateInstalledScript(for: manifest, validator: validator)
        try validateInstalledResources(for: manifest, validator: validator)
    }

    public func installedManifest(for extensionID: String) throws -> ExtensionPackageManifest {
        let packageData = try Data(contentsOf: packageURL(for: extensionID))
        return try JSONDecoder().decode(ExtensionPackageManifest.self, from: packageData)
    }

    public func installedVersion(for extensionID: String) throws -> String {
        try installedManifest(for: extensionID).version
    }

    public func hasUpdateAvailable(for extensionItem: DownloadableExtension) -> Bool {
        guard let installedVersion = try? installedVersion(for: extensionItem.id) else { return false }
        return compareVersionStrings(installedVersion, extensionItem.version) == .orderedAscending
    }

    public func scriptCommands(for installedExtensions: InstalledExtensions) -> [ScriptTextCommand] {
        installedExtensions.installedIDs
            .sorted()
            .filter(installedExtensions.isActive)
            .compactMap { extensionID in
                guard let manifest = try? installedManifest(for: extensionID),
                      manifest.kind == .textCommand,
                      let scriptCommand = manifest.scriptCommand else { return nil }
                let scriptURL = scriptURL(for: manifest.id, scriptFile: scriptCommand.scriptFile)
                guard FileManager.default.fileExists(atPath: scriptURL.path) else { return nil }
                return ScriptTextCommand(id: scriptCommand.id, title: scriptCommand.title, scriptURL: scriptURL)
            }
    }

    public func themes(for installedExtensions: InstalledExtensions) -> [EditorTheme] {
        installedExtensions.installedIDs
            .sorted()
            .filter(installedExtensions.isActive)
            .flatMap { extensionID in
                guard let manifest = try? installedManifest(for: extensionID),
                      manifest.kind == .theme,
                      let themeResource = manifest.themeResource else { return [EditorTheme]() }
                let validator = ExtensionPackageValidator()
                guard (try? validateInstalledResources(for: manifest, validator: validator)) != nil else {
                    return [EditorTheme]()
                }
                let themeURL = resourceURL(for: manifest.id, resourceFile: themeResource.file)
                return (try? ThemePackageLoader().loadThemes(from: themeURL)) ?? []
            }
    }

    private func validateInstalledScript(for manifest: ExtensionPackageManifest, validator: ExtensionPackageValidator) throws {
        guard let scriptCommand = manifest.scriptCommand else { return }
        let scriptURL = scriptURL(for: manifest.id, scriptFile: scriptCommand.scriptFile)
        try validator.validateScriptFile(scriptURL, scriptCommand: scriptCommand)
    }

    private func validateInstalledResources(for manifest: ExtensionPackageManifest, validator: ExtensionPackageValidator) throws {
        for resource in manifest.resources {
            let resourceURL = resourceURL(for: manifest.id, resourceFile: resource.file)
            try validator.validateResourceFile(resourceURL, resource: resource)
        }
    }
}

public struct ExtensionPackageDownloader {
    public init() {}

    @discardableResult
    public func download(_ extensionItem: DownloadableExtension, into directory: URL) throws -> URL {
        let packageData = try Data(contentsOf: extensionItem.downloadURL)
        let manifest = try JSONDecoder().decode(ExtensionPackageManifest.self, from: packageData)
        let validator = ExtensionPackageValidator()
        try validator.validateManifest(manifest, matches: extensionItem)

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = ExtensionPackageStore(directory: directory)
        if let scriptCommand = manifest.scriptCommand,
           let sourceURL = scriptCommand.sourceURL {
            let scriptData = try Data(contentsOf: sourceURL)
            try validator.validateScriptData(scriptData, scriptCommand: scriptCommand)
            let scriptDestinationURL = store.scriptURL(for: extensionItem.id, scriptFile: scriptCommand.scriptFile)
            try FileManager.default.createDirectory(at: scriptDestinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try scriptData.write(to: scriptDestinationURL, options: .atomic)
        }
        for resource in manifest.resources {
            let resourceData = try Data(contentsOf: resource.sourceURL)
            try validator.validateResourceData(resourceData, resource: resource)
            let resourceDestinationURL = store.resourceURL(for: extensionItem.id, resourceFile: resource.file)
            try FileManager.default.createDirectory(at: resourceDestinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try resourceData.write(to: resourceDestinationURL, options: .atomic)
        }
        let destinationURL = store.packageURL(for: extensionItem.id)
        try packageData.write(to: destinationURL, options: .atomic)
        return destinationURL
    }
}
