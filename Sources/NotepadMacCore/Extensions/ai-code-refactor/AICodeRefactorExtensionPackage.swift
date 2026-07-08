import Foundation

enum AICodeRefactorExtensionPackage {
    static let id = "ai-code-refactor"

    static let catalogEntry = DownloadableExtension(
        id: id,
        title: "AI Code Refactor Assistant",
        description: "Suggest safer refactors for selected code through a configured agent.",
        version: "1.0.0",
        kind: .aiTextTask,
        downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/ai-code-refactor/ai-code-refactor.macpadproext")!
    )

    static let textTasks: [AITextTask] = [.codeRefactor]
}
