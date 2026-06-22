import SwiftUI

/// The primary action screen — full item list with quick-use buttons.
struct GridView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showAddItem = false
    @State private var selectedCategory: String = "All"
    @State private var selectedItem: TrackedItem? = nil
    @State private var showPaywall = false

    private var categories: [String] {
        ["All"] + appModel.categories
    }

    private var filteredItems: [TrackedItem] {
        let active = appModel.items.filter { !$0.isRetired }
        if selectedCategory == "All" { return active }
        return active.filter { $0.category == selectedCategory }
    }

    private let currencyCode: String = Locale.current.currency?.identifier ?? "USD"

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                VStack(spacing: 0) {
                    // Category filter
                    if appModel.categories.count > 1 {
                        categoryPicker
                    }

                    if filteredItems.isEmpty {
                        Spacer()
                        emptyState
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(filteredItems) { item in
                                    quickUseRow(item)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                }
            }
            .navigationTitle("Log a Use")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showAddItem = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.qmAccent)
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                AddItemSheet()
                    .environmentObject(appModel)
            }
            .sheet(item: $selectedItem) { item in
                ItemDetailSheet(item: item)
                    .environmentObject(appModel)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(store)
            }
        }
    }

    // MARK: - Category picker

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    Button {
                        Haptics.tap()
                        selectedCategory = cat
                    } label: {
                        Text(cat)
                            .font(.subheadline.weight(selectedCategory == cat ? .semibold : .regular))
                            .foregroundStyle(selectedCategory == cat ? .white : Color.qmAccent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                selectedCategory == cat ? Color.qmAccent : Color.qmCard,
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Quick-use row

    private func quickUseRow(_ item: TrackedItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                let count = appModel.useCount(for: item)
                let cpu = appModel.costPerUse(for: item)
                HStack(spacing: 6) {
                    Text("\(count) use\(count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let cpu {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(cpu, format: .currency(code: currencyCode))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.qmAccent)
                        Text("/use")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Detail button
            Button {
                Haptics.tap()
                selectedItem = item
            } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            // Quick +1 use
            Button {
                Haptics.success()
                appModel.logUse(for: item)
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.qmAccent)
                        .frame(width: 38, height: 38)
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
        }
        .qmCard()
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "tag.slash")
                .font(.system(size: 44))
                .foregroundStyle(Color.qmAccent.opacity(0.35))
            Text(selectedCategory == "All" ? "No items yet" : "No \(selectedCategory) items")
                .font(.headline)
            Text("Add items from the home screen and log each use here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}
