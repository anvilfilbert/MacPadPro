import Foundation

enum ClipboardSlotsExtensionPackage {
    static let id = "clipboard-slots"

    static let catalogEntry = DownloadableExtension(
        id: id,
        title: "Clipboard Slots",
        description: "Save and reuse text clipboard content across 10 named slots.",
        version: "1.0.0",
        kind: .clipboard,
        downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/clipboard-slots/clipboard-slots.macpadproext")!
    )

    static let clipboards: [ClipboardExtension] = [
        ClipboardExtension(
            id: id,
            title: "Clipboard Slots",
            slotCount: 10
        )
    ]
}
