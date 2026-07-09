import XCTest
@testable import NotepadMacCore

final class RecentFilesStoreTests: XCTestCase {
    func testRecordsNewestFilesFirstAndLimitsToFive() {
        var store = RecentFilesStore(paths: [])

        for index in 1...7 {
            store.record(path: "/tmp/file-\(index).txt")
        }

        XCTAssertEqual(store.paths, [
            "/tmp/file-7.txt",
            "/tmp/file-6.txt",
            "/tmp/file-5.txt",
            "/tmp/file-4.txt",
            "/tmp/file-3.txt"
        ])
    }

    func testRecordingExistingPathMovesItToTop() {
        var store = RecentFilesStore(paths: [
            "/tmp/a.txt",
            "/tmp/b.txt",
            "/tmp/c.txt"
        ])

        store.record(path: "/tmp/b.txt")

        XCTAssertEqual(store.paths, [
            "/tmp/b.txt",
            "/tmp/a.txt",
            "/tmp/c.txt"
        ])
    }
}
