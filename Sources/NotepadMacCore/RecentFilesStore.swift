import Foundation

public struct RecentFilesStore: Codable, Sendable, Equatable {
    public private(set) var paths: [String]

    public init(paths: [String]) {
        self.paths = Array(Self.unique(paths).prefix(5))
    }

    public mutating func record(path: String) {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        paths.removeAll { $0 == trimmed }
        paths.insert(trimmed, at: 0)
        paths = Array(paths.prefix(5))
    }

    public mutating func remove(path: String) {
        paths.removeAll { $0 == path }
    }

    private static func unique(_ paths: [String]) -> [String] {
        var seen = Set<String>()
        return paths.filter { path in
            guard !seen.contains(path) else { return false }
            seen.insert(path)
            return true
        }
    }
}
