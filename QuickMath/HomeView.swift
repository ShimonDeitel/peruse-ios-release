import SwiftUI
import SwiftData

struct HomeView: View {
    var forceScreen: String? = nil

    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showAddItem = false
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showInsights = false
    @State private var selectedItem: TrackedItem? = nil

    var activeItems: [TrackedItem] {
        appModel.items.filter { !$0.isRetired }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        // Summary row
                        summaryRow

                        // Items list
                        if activeItems.isEmpty {
                            emptyState
                        } else {
                            itemsGrid
                        }

                        // Pro tile
                        proTile
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Per Use")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Haptics.tap()
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.qmAccent)
                    }
                }
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
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(appModel)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showInsights) {
                InsightsView()
                    .environmentObject(appModel)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(store)
            }
            .sheet(item: $selectedItem) { item in
                ItemDetailSheet(item: item)
                    .environmentObject(appModel)
                    .environmentObject(store)
            }
        }
        .onAppear {
            if let force = forceScreen {
                switch force {
                case "insights": showInsights = true
                case "paywall": showPaywall = true
                default: break
                }
            }
        }
    }

    // MARK: - Summary row

    private var summaryRow: some View {
        HStack(spacing: 12) {
            MetricTile(
                value: "\(activeItems.count)",
                label: "Items Tracked"
            )
            MetricTile(
                value: "\(appModel.useEvents.count)",
                label: "Total Uses"
            )
        }
    }

    // MARK: - Items grid

    private var itemsGrid: some View {
        LazyVStack(spacing: 12) {
            ForEach(activeItems) { item in
                ItemRowView(item: item)
                    .environmentObject(appModel)
                    .onTapGesture {
                        Haptics.tap()
                        selectedItem = item
                    }
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tag")
                .font(.system(size: 52))
                .foregroundStyle(Color.qmAccent.opacity(0.4))
            Text("Track your first item")
                .font(.title3.weight(.semibold))
            Text("Add something you bought and tap to log each use. Watch the cost-per-use drop.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Add Item") {
                Haptics.tap()
                showAddItem = true
            }
            .prominentButton()
        }
        .padding(.vertical, 48)
    }

    // MARK: - Pro tile

    private var proTile: some View {
        Button {
            Haptics.tap()
            if store.isPro {
                showInsights = true
            } else {
                showPaywall = true
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: store.isPro ? "chart.line.uptrend.xyaxis" : "lock.fill")
                    .font(.title3)
                    .foregroundStyle(Color.qmAccent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.isPro ? "Insights" : "Per Use Pro")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(store.isPro ? "Rankings, trends, export" : "Unlock history, rankings & trends")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            .qmCard()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Item Row View

struct ItemRowView: View {
    let item: TrackedItem
    @EnvironmentObject var appModel: AppModel

    private var useCount: Int { appModel.useCount(for: item) }
    private var costPerUse: Double? { appModel.costPerUse(for: item) }

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                Circle()
                    .fill(Color.qmCard2)
                    .frame(width: 44, height: 44)
                Image(systemName: iconForCategory(item.category))
                    .font(.system(size: 18))
                    .foregroundStyle(Color.qmAccent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(item.price, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text("\(useCount) use\(useCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                if let cpu = costPerUse {
                    Text(cpu, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.qmAccent)
                    Text("per use")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No uses yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .qmCard()
    }

    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "clothing": return "tshirt"
        case "electronics": return "laptopcomputer"
        case "kitchen": return "fork.knife"
        case "sports": return "figure.run"
        case "books": return "book"
        case "tools": return "wrench.and.screwdriver"
        case "home": return "house"
        case "transport": return "car"
        default: return "tag"
        }
    }
}

// MARK: - Add Item Sheet

struct AddItemSheet: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var priceText = ""
    @State private var purchaseDate = Date()
    @State private var category = "General"

    let categories = ["General", "Clothing", "Electronics", "Kitchen", "Sports", "Books", "Tools", "Home", "Transport"]

    private var price: Double { Double(priceText) ?? 0 }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && price > 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                Form {
                    Section("Item Details") {
                        TextField("Name (e.g. Running Shoes)", text: $name)
                        HStack {
                            Text("$")
                            TextField("Price paid", text: $priceText)
                                .keyboardType(.decimalPad)
                        }
                        DatePicker("Purchase date", selection: $purchaseDate, displayedComponents: .date)
                    }
                    Section("Category") {
                        Picker("Category", selection: $category) {
                            ForEach(categories, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard canSave else { return }
                        Haptics.success()
                        appModel.addItem(name: name.trimmingCharacters(in: .whitespaces), price: price, purchaseDate: purchaseDate, category: category)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}

// MARK: - Item Detail Sheet

struct ItemDetailSheet: View {
    let item: TrackedItem
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var showRetireConfirm = false
    @State private var showDeleteConfirm = false

    private var useCount: Int { appModel.useCount(for: item) }
    private var costPerUse: Double? { appModel.costPerUse(for: item) }
    private var recentEvents: [UseEvent] { Array(appModel.events(for: item).prefix(5)) }
    private let currencyCode: String = Locale.current.currency?.identifier ?? "USD"

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        // Stats row
                        HStack(spacing: 12) {
                            MetricTile(
                                value: item.price.formatted(.currency(code: currencyCode)),
                                label: "Paid"
                            )
                            MetricTile(
                                value: "\(useCount)",
                                label: "Uses"
                            )
                            if let cpu = costPerUse {
                                MetricTile(
                                    value: cpu.formatted(.currency(code: currencyCode)),
                                    label: "Per Use"
                                )
                            }
                        }

                        // Log use button
                        Button {
                            Haptics.success()
                            appModel.logUse(for: item)
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Log a Use")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .prominentButton()

                        // Recent uses (Pro or teaser)
                        if store.isPro && !recentEvents.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Recent Uses")
                                    .font(.headline)
                                    .padding(.horizontal, 4)
                                ForEach(recentEvents) { event in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.qmCorrect)
                                        Text(event.date, style: .date)
                                            .font(.subheadline)
                                        Spacer()
                                        Text(event.date, style: .time)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .qmCard(cornerRadius: 12)
                                }
                            }
                        }

                        // Actions
                        VStack(spacing: 8) {
                            Button("Retire Item") {
                                showRetireConfirm = true
                            }
                            .softButton()
                            .confirmationDialog("Retire this item?", isPresented: $showRetireConfirm, titleVisibility: .visible) {
                                Button("Retire", role: .destructive) {
                                    appModel.retireItem(item)
                                    dismiss()
                                }
                                Button("Cancel", role: .cancel) {}
                            }

                            Button("Delete Item", role: .destructive) {
                                showDeleteConfirm = true
                            }
                            .foregroundStyle(Color.qmWrong)
                            .confirmationDialog("Delete this item and all its use history?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                                Button("Delete", role: .destructive) {
                                    appModel.deleteItem(item)
                                    dismiss()
                                }
                                Button("Cancel", role: .cancel) {}
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
