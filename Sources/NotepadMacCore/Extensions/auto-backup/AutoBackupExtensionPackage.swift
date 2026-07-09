import Foundation

enum AutoBackupExtensionPackage {
    static let id = "auto-backup"

    static let catalogEntry = DownloadableExtension(
        id: id,
        title: "Auto Backup / Versions",
        description: "Create optional local timestamped editing snapshots and browse version history.",
        version: "1.0.0",
        kind: .autoBackup,
        downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/auto-backup/auto-backup.macpadproext")!
    )

    static let actions: [ExtensionMenuAction] = [
        ExtensionMenuAction(id: id, title: "Version History", opensDetachedWindow: true, isResizable: true, isClosable: true)
    ]
}
