import Foundation
import SwiftData
import SwiftUI

// MARK: - SwiftData Models

@Model
final class TrackedItem {
    var id: UUID
    var name: String
    var price: Double
    var purchaseDate: Date
    var category: String
    var isRetired: Bool

    init(id: UUID = UUID(), name: String, price: Double, purchaseDate: Date = Date(), category: String = "General", isRetired: Bool = false) {
        self.id = id
        self.name = name
        self.price = price
        self.purchaseDate = purchaseDate
        self.category = category
        self.isRetired = isRetired
    }
}

@Model
final class UseEvent {
    var id: UUID
    var itemID: UUID
    var date: Date

    init(id: UUID = UUID(), itemID: UUID, date: Date = Date()) {
        self.id = id
        self.itemID = itemID
        self.date = date
    }
}

// MARK: - AppModel

@MainActor
final class AppModel: ObservableObject {
    let container: ModelContainer
    weak var store: Store?

    @Published private(set) var items: [TrackedItem] = []
    @Published private(set) var useEvents: [UseEvent] = []

    init(container: ModelContainer) {
        self.container = container
        reload()
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema([TrackedItem.self, UseEvent.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return (try? ModelContainer(for: schema, configurations: [fallback])) ?? {
                fatalError("Cannot create ModelContainer: \(error)")
            }()
        }
    }

    func reload() {
        let context = container.mainContext
        let itemDescriptor = FetchDescriptor<TrackedItem>(sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)])
        let eventDescriptor = FetchDescriptor<UseEvent>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        items = (try? context.fetch(itemDescriptor)) ?? []
        useEvents = (try? context.fetch(eventDescriptor)) ?? []
    }

    func refresh() { reload() }

    // MARK: - Item operations

    func addItem(name: String, price: Double, purchaseDate: Date, category: String) {
        let context = container.mainContext
        let item = TrackedItem(name: name, price: price, purchaseDate: purchaseDate, category: category)
        context.insert(item)
        try? context.save()
        reload()
    }

    func logUse(for item: TrackedItem) {
        let context = container.mainContext
        let event = UseEvent(itemID: item.id, date: Date())
        context.insert(event)
        try? context.save()
        reload()
    }

    func retireItem(_ item: TrackedItem) {
        item.isRetired = true
        try? container.mainContext.save()
        reload()
    }

    func deleteItem(_ item: TrackedItem) {
        let context = container.mainContext
        // Delete associated use events
        let itemID = item.id
        let toDelete = useEvents.filter { $0.itemID == itemID }
        for event in toDelete { context.delete(event) }
        context.delete(item)
        try? context.save()
        reload()
    }

    func deleteAllData() {
        let context = container.mainContext
        for event in useEvents { context.delete(event) }
        for item in items { context.delete(item) }
        try? context.save()
        reload()
    }

    // MARK: - Stats helpers

    func useCount(for item: TrackedItem) -> Int {
        useEvents.filter { $0.itemID == item.id }.count
    }

    func costPerUse(for item: TrackedItem) -> Double? {
        let count = useCount(for: item)
        guard count > 0 else { return nil }
        return item.price / Double(count)
    }

    func lastUsed(for item: TrackedItem) -> Date? {
        useEvents
            .filter { $0.itemID == item.id }
            .sorted { $0.date > $1.date }
            .first?.date
    }

    func events(for item: TrackedItem) -> [UseEvent] {
        useEvents
            .filter { $0.itemID == item.id }
            .sorted { $0.date > $1.date }
    }

    // Best/worst value (cost per use)
    var bestValueItems: [TrackedItem] {
        items.filter { !$0.isRetired && useCount(for: $0) > 0 }
            .sorted { (costPerUse(for: $0) ?? .infinity) < (costPerUse(for: $1) ?? .infinity) }
    }

    var worstValueItems: [TrackedItem] {
        items.filter { !$0.isRetired && useCount(for: $0) > 0 }
            .sorted { (costPerUse(for: $0) ?? 0) > (costPerUse(for: $1) ?? 0) }
    }

    var neglectedItems: [TrackedItem] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return items.filter { item in
            guard !item.isRetired else { return false }
            if let last = lastUsed(for: item) {
                return last < cutoff
            }
            return useCount(for: item) == 0
        }
    }

    var categories: [String] {
        Array(Set(items.map { $0.category })).sorted()
    }
}
