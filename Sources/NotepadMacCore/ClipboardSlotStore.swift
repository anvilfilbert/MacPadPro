import Foundation

public struct ClipboardSlot: Codable, Sendable, Equatable {
    public let number: Int
    public var content: String?

    public init(number: Int, content: String? = nil) {
        self.number = number
        self.content = content
    }
}

public struct ClipboardSlotStore: Codable, Sendable, Equatable {
    public let slotCount: Int
    public private(set) var slots: [ClipboardSlot]

    public init(slotCount: Int = 10, slots: [ClipboardSlot]? = nil) {
        let boundedSlotCount = min(max(slotCount, 1), 10)
        self.slotCount = boundedSlotCount

        let suppliedSlotsByNumber = Dictionary(
            uniqueKeysWithValues: (slots ?? []).map { ($0.number, $0) }
        )
        self.slots = (1...boundedSlotCount).map { number in
            suppliedSlotsByNumber[number] ?? ClipboardSlot(number: number)
        }
    }

    public func content(in slot: Int) -> String? {
        slots.first { $0.number == slot }?.content
    }

    public mutating func save(_ content: String, to slot: Int) {
        guard let index = slots.firstIndex(where: { $0.number == slot }) else { return }
        slots[index].content = content
    }

    public mutating func clear(slot: Int) {
        guard let index = slots.firstIndex(where: { $0.number == slot }) else { return }
        slots[index].content = nil
    }

    public mutating func clearAll() {
        for index in slots.indices {
            slots[index].content = nil
        }
    }
}
