import Foundation

enum AISummarizerExtensionPackage {
    static let id = "ai-summarizer"

    static let catalogEntry = DownloadableExtension(
        id: id,
        title: "AI Summarizer",
        description: "Send selected text to a configured agent and summarize it.",
        version: "1.0.0",
        kind: .aiTextTask,
        downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/ai-summarizer/ai-summarizer.macpadproext")!
    )

    static let textTasks: [AITextTask] = [.summarizer]
}
