import Foundation

enum AISmartSearchExtensionPackage {
    static let id = "ai-smart-search"

    static let catalogEntry = DownloadableExtension(
        id: id,
        title: "AI Smart Search",
        description: "Search open documents semantically through a configured agent.",
        version: "1.0.0",
        kind: .aiSmartSearch,
        downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/ai-smart-search/ai-smart-search.macpadproext")!
    )

    static let smartSearches: [AISmartSearchExtension] = [
        AISmartSearchExtension(id: id, title: "AI Smart Search")
    ]
}
