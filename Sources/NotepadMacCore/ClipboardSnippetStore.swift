import Foundation

public struct ClipboardSnippet: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public var name: String
    public var content: String

    public init(id: String, name: String, content: String) {
        self.id = id
        self.name = name
        self.content = content
    }
}

public struct ClipboardSnippetStore: Codable, Sendable, Equatable {
    public private(set) var recent: [ClipboardSnippet]
    public private(set) var pinned: [ClipboardSnippet]

    public init(recent: [ClipboardSnippet], pinned: [ClipboardSnippet]) {
        self.recent = Array(recent.prefix(10))
        self.pinned = pinned
    }

    public mutating func captureRecent(_ content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        recent.removeAll { $0.content == content }
        recent.insert(
            ClipboardSnippet(id: UUID().uuidString, name: "Clipboard", content: content),
            at: 0
        )
        recent = Array(recent.prefix(10))
    }

    public mutating func pin(recentID: String, name: String) {
        guard let snippet = recent.first(where: { $0.id == recentID }) else { return }
        pinned.insert(
            ClipboardSnippet(id: UUID().uuidString, name: name, content: snippet.content),
            at: 0
        )
    }

    public mutating func renamePinned(id: String, name: String) {
        guard let index = pinned.firstIndex(where: { $0.id == id }) else { return }
        pinned[index].name = name
    }

    public mutating func deletePinned(id: String) {
        pinned.removeAll { $0.id == id }
    }
}
