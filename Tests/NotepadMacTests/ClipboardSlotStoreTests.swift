import XCTest
@testable import NotepadMacCore

final class ClipboardSlotStoreTests: XCTestCase {
    func testStoreSavesAndReadsTenClipboardSlots() {
        var store = ClipboardSlotStore(slotCount: 10)

        store.save("first", to: 1)
        store.save("tenth", to: 10)

        XCTAssertEqual(store.content(in: 1), "first")
        XCTAssertEqual(store.content(in: 10), "tenth")
        XCTAssertNil(store.content(in: 2))
    }

    func testStoreIgnoresSlotsOutsideDeclaredRange() {
        var store = ClipboardSlotStore(slotCount: 10)

        store.save("zero", to: 0)
        store.save("eleven", to: 11)

        XCTAssertNil(store.content(in: 0))
        XCTAssertNil(store.content(in: 11))
        XCTAssertTrue(store.slots.allSatisfy { $0.content == nil })
    }

    func testStoreCanClearSingleSlotAndAllSlots() {
        var store = ClipboardSlotStore(slotCount: 10)
        store.save("first", to: 1)
        store.save("second", to: 2)

        store.clear(slot: 1)

        XCTAssertNil(store.content(in: 1))
        XCTAssertEqual(store.content(in: 2), "second")

        store.clearAll()

        XCTAssertTrue(store.slots.allSatisfy { $0.content == nil })
    }

    func testStoreRoundTripsThroughJson() throws {
        var store = ClipboardSlotStore(slotCount: 10)
        store.save("saved clipboard", to: 4)

        let data = try JSONEncoder().encode(store)
        let decoded = try JSONDecoder().decode(ClipboardSlotStore.self, from: data)

        XCTAssertEqual(decoded.slotCount, 10)
        XCTAssertEqual(decoded.content(in: 4), "saved clipboard")
    }
}
