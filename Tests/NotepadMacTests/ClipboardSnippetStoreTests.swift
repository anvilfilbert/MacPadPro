import XCTest
@testable import NotepadMacCore

final class ClipboardSnippetStoreTests: XCTestCase {
    func testCapturesRecentClipboardTextAndLimitsHistory() {
        var store = ClipboardSnippetStore(recent: [], pinned: [])

        for index in 1...12 {
            store.captureRecent("clip \(index)")
        }

        XCTAssertEqual(store.recent.count, 10)
        XCTAssertEqual(store.recent.first?.content, "clip 12")
        XCTAssertEqual(store.recent.last?.content, "clip 3")
    }

    func testPinsNamesRenamesAndDeletesSnippets() throws {
        var store = ClipboardSnippetStore(recent: [], pinned: [])
        store.captureRecent("deploy command")
        let recent = try XCTUnwrap(store.recent.first)

        store.pin(recentID: recent.id, name: "Deploy")

        XCTAssertEqual(store.pinned.first?.name, "Deploy")
        XCTAssertEqual(store.pinned.first?.content, "deploy command")

        let pinned = try XCTUnwrap(store.pinned.first)
        store.renamePinned(id: pinned.id, name: "Deploy prod")
        XCTAssertEqual(store.pinned.first?.name, "Deploy prod")

        store.deletePinned(id: pinned.id)
        XCTAssertTrue(store.pinned.isEmpty)
    }
}
