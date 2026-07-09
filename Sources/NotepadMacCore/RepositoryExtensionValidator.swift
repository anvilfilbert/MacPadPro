import Foundation

public struct RepositoryExtensionValidationReport: Sendable, Equatable {
    public let validatedExtensionIDs: [String]
    public let issues: [RepositoryExtensionValidationIssue]

    public init(validatedExtensionIDs: [String], issues: [RepositoryExtensionValidationIssue]) {
        self.validatedExtensionIDs = validatedExtensionIDs
        self.issues = issues
    }
}

public enum RepositoryExtensionValidationIssue: Sendable, Equatable, CustomStringConvertible {
    case catalogDoesNotMatchBuiltIn(missingFromRepository: [String], missingFromBuiltIn: [String])
    case invalidDownloadURL(extensionID: String, url: String)
    case missingPackageDirectory(extensionID: String)
    case missingPackageManifest(extensionID: String)
    case invalidPackageManifest(extensionID: String, reason: String)
    case missingSourceDirectory(extensionID: String)
    case unreadableSourceDirectory(extensionID: String, reason: String)
    case missingSourceSwiftFile(extensionID: String)

    public var description: String {
        switch self {
        case let .catalogDoesNotMatchBuiltIn(missingFromRepository, missingFromBuiltIn):
            "Catalog mismatch. Missing from repository: \(missingFromRepository.joined(separator: ", ")). Missing from built-in catalog: \(missingFromBuiltIn.joined(separator: ", "))."
        case let .invalidDownloadURL(extensionID, url):
            "\(extensionID) has invalid download URL: \(url)."
        case let .missingPackageDirectory(extensionID):
            "\(extensionID) is missing its repository package directory."
        case let .missingPackageManifest(extensionID):
            "\(extensionID) is missing its .macpadproext manifest."
        case let .invalidPackageManifest(extensionID, reason):
            "\(extensionID) has invalid package manifest: \(reason)."
        case let .missingSourceDirectory(extensionID):
            "\(extensionID) is missing its source directory."
        case let .unreadableSourceDirectory(extensionID, reason):
            "\(extensionID) source directory could not be read: \(reason)."
        case let .missingSourceSwiftFile(extensionID):
            "\(extensionID) source directory has no Swift package file."
        }
    }
}

public struct RepositoryExtensionValidator: Sendable {
    public init() {}

    public func validate(
        repositoryRoot: URL,
        catalog: ExtensionCatalog,
        builtInCatalog: ExtensionCatalog
    ) throws -> RepositoryExtensionValidationReport {
        let repositoryIDs = Set(catalog.extensions.map(\.id))
        let builtInIDs = Set(builtInCatalog.extensions.map(\.id))
        var issues: [RepositoryExtensionValidationIssue] = []

        if repositoryIDs != builtInIDs {
            issues.append(.catalogDoesNotMatchBuiltIn(
                missingFromRepository: builtInIDs.subtracting(repositoryIDs).sorted(),
                missingFromBuiltIn: repositoryIDs.subtracting(builtInIDs).sorted()
            ))
        }

        for extensionItem in catalog.extensions {
            issues.append(contentsOf: validate(extensionItem: extensionItem, repositoryRoot: repositoryRoot))
        }

        let invalidIDs = Set(issues.compactMap(extensionID(from:)))
        let validatedIDs = catalog.extensions.map(\.id).filter { !invalidIDs.contains($0) }
        return RepositoryExtensionValidationReport(validatedExtensionIDs: validatedIDs, issues: issues)
    }

    private func validate(extensionItem: DownloadableExtension, repositoryRoot: URL) -> [RepositoryExtensionValidationIssue] {
        var issues: [RepositoryExtensionValidationIssue] = []
        let packageDirectory = repositoryRoot
            .appendingPathComponent("RepositoryExtensions", isDirectory: true)
            .appendingPathComponent(extensionItem.id, isDirectory: true)
        let packageManifestURL = packageDirectory.appendingPathComponent("\(extensionItem.id).macpadproext")
        let sourceDirectory = repositoryRoot
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("NotepadMacCore", isDirectory: true)
            .appendingPathComponent("Extensions", isDirectory: true)
            .appendingPathComponent(extensionItem.id, isDirectory: true)

        if !downloadURLMatchesRepositoryLayout(extensionItem.downloadURL, extensionID: extensionItem.id) {
            issues.append(.invalidDownloadURL(extensionID: extensionItem.id, url: extensionItem.downloadURL.absoluteString))
        }

        var isPackageDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: packageDirectory.path, isDirectory: &isPackageDirectory),
              isPackageDirectory.boolValue else {
            issues.append(.missingPackageDirectory(extensionID: extensionItem.id))
            return issues
        }

        guard FileManager.default.fileExists(atPath: packageManifestURL.path) else {
            issues.append(.missingPackageManifest(extensionID: extensionItem.id))
            return issues
        }

        issues.append(contentsOf: validatePackageManifest(
            extensionItem: extensionItem,
            manifestURL: packageManifestURL,
            packageDirectory: packageDirectory
        ))

        var isSourceDirectory: ObjCBool = false
        if !FileManager.default.fileExists(atPath: sourceDirectory.path, isDirectory: &isSourceDirectory) || !isSourceDirectory.boolValue {
            issues.append(.missingSourceDirectory(extensionID: extensionItem.id))
        } else {
            do {
                if try !sourceDirectoryContainsSwiftFile(sourceDirectory) {
                    issues.append(.missingSourceSwiftFile(extensionID: extensionItem.id))
                }
            } catch {
                issues.append(.unreadableSourceDirectory(extensionID: extensionItem.id, reason: error.localizedDescription))
            }
        }

        return issues
    }

    private func downloadURLMatchesRepositoryLayout(_ url: URL, extensionID: String) -> Bool {
        url.scheme == "https"
            && url.host == "raw.githubusercontent.com"
            && url.path == "/anvilfilbert/MacPadPro/main/RepositoryExtensions/\(extensionID)/\(extensionID).macpadproext"
    }

    private func validatePackageManifest(
        extensionItem: DownloadableExtension,
        manifestURL: URL,
        packageDirectory: URL
    ) -> [RepositoryExtensionValidationIssue] {
        do {
            let manifestData = try Data(contentsOf: manifestURL)
            let manifest = try JSONDecoder().decode(ExtensionPackageManifest.self, from: manifestData)
            try manifest.validate(matches: extensionItem)
            return validateRepositoryScriptFiles(manifest: manifest, packageDirectory: packageDirectory)
        } catch {
            return [.invalidPackageManifest(extensionID: extensionItem.id, reason: error.localizedDescription)]
        }
    }

    private func validateRepositoryScriptFiles(
        manifest: ExtensionPackageManifest,
        packageDirectory: URL
    ) -> [RepositoryExtensionValidationIssue] {
        guard let scriptCommand = manifest.scriptCommand else { return [] }
        let scriptURL = packageDirectory.appendingPathComponent(scriptCommand.scriptFile)
        guard FileManager.default.fileExists(atPath: scriptURL.path) else {
            return [.invalidPackageManifest(
                extensionID: manifest.id,
                reason: ExtensionPackageDownloadError.scriptFileMissing(scriptFile: scriptCommand.scriptFile).localizedDescription
            )]
        }
        guard let expectedSHA256 = scriptCommand.sourceSHA256 else { return [] }
        do {
            let scriptData = try Data(contentsOf: scriptURL)
            let actualSHA256 = sha256Hex(for: scriptData)
            guard actualSHA256.caseInsensitiveCompare(expectedSHA256) == .orderedSame else {
                return [.invalidPackageManifest(
                    extensionID: manifest.id,
                    reason: ExtensionPackageDownloadError.scriptChecksumMismatch(
                        expectedSHA256: expectedSHA256,
                        actualSHA256: actualSHA256,
                        scriptFile: scriptCommand.scriptFile
                    ).localizedDescription
                )]
            }
            return []
        } catch {
            return [.invalidPackageManifest(extensionID: manifest.id, reason: error.localizedDescription)]
        }
    }

    private func sourceDirectoryContainsSwiftFile(_ sourceDirectory: URL) throws -> Bool {
        let files = try FileManager.default.contentsOfDirectory(at: sourceDirectory, includingPropertiesForKeys: nil)
        return files.contains { $0.pathExtension == "swift" }
    }

    private func extensionID(from issue: RepositoryExtensionValidationIssue) -> String? {
        switch issue {
        case .catalogDoesNotMatchBuiltIn:
            nil
        case let .invalidDownloadURL(extensionID, _),
             let .missingPackageDirectory(extensionID),
             let .missingPackageManifest(extensionID),
             let .invalidPackageManifest(extensionID, _),
             let .missingSourceDirectory(extensionID),
             let .unreadableSourceDirectory(extensionID, _),
             let .missingSourceSwiftFile(extensionID):
            extensionID
        }
    }
}
