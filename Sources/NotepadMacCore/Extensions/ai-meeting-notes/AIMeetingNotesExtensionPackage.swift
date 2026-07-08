import Foundation

enum AIMeetingNotesExtensionPackage {
    static let id = "ai-meeting-notes"

    static let catalogEntry = DownloadableExtension(
        id: id,
        title: "AI Meeting Notes Cleaner",
        description: "Clean selected meeting notes into summary, decisions, actions, and open questions.",
        version: "1.0.0",
        kind: .aiTextTask,
        downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/ai-meeting-notes/ai-meeting-notes.macpadproext")!
    )

    static let textTasks: [AITextTask] = [.meetingNotesCleaner]
}
