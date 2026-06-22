import SwiftUI
import Charts

/// Pro feature: history, rankings, trends, neglected items, CSV export.
struct InsightsView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: InsightsTab = .rankings

    private let currencyCode: String = Locale.current.currency?.identifier ?? "USD"

    enum InsightsTab: String, CaseIterable, Identifiable {
        case rankings = "Rankings"
        case neglected = "Neglected"
        case export = "Export"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                VStack(spacing: 0) {
                    Picker("Tab", selection: $selectedTab) {
                        ForEach(InsightsTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    ScrollView {
                        VStack(spacing: 16) {
                            switch selectedTab {
                            case .rankings: rankingsView
                            case .neglected: neglectedView
                            case .export: exportView
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Rankings

    private var rankingsView: some View {
        VStack(spacing: 16) {
            if appModel.bestValueItems.isEmpty {
                emptyState(message: "Log uses to see value rankings.")
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Best Value")
                        .font(.headline)
                    ForEach(Array(appModel.bestValueItems.prefix(5).enumerated()), id: \.element.id) { idx, item in
                        rankRow(item: item, rank: idx + 1, isBest: true)
                    }
                }

                if !appModel.worstValueItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Needs More Uses")
                            .font(.headline)
                        ForEach(Array(appModel.worstValueItems.prefix(5).enumerated()), id: \.element.id) { idx, item in
                            rankRow(item: item, rank: idx + 1, isBest: false)
                        }
                    }
                }

                // Use-count chart
                if appModel.bestValueItems.count >= 2 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Uses by Item")
                            .font(.headline)
                        Chart {
                            ForEach(Array(appModel.items.filter { !$0.isRetired }.prefix(8).enumerated()), id: \.element.id) { _, item in
                                BarMark(
                                    x: .value("Uses", appModel.useCount(for: item)),
                                    y: .value("Item", item.name)
                                )
                                .foregroundStyle(Color.qmAccent)
                                .cornerRadius(4)
                            }
                        }
                        .frame(height: CGFloat(min(appModel.items.filter { !$0.isRetired }.count, 8)) * 36 + 20)
                        .chartXAxis {
                            AxisMarks(values: .automatic) { value in
                                AxisValueLabel()
                            }
                        }
                    }
                    .qmCard()
                }
            }
        }
    }

    private func rankRow(item: TrackedItem, rank: Int, isBest: Bool) -> some View {
        HStack(spacing: 12) {
            Text("#\(rank)")
                .font(.caption.weight(.bold))
                .foregroundStyle(isBest ? Color.qmCorrect : Color.qmWrong)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text("\(appModel.useCount(for: item)) uses · paid \(item.price.formatted(.currency(code: currencyCode)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let cpu = appModel.costPerUse(for: item) {
                VStack(alignment: .trailing, spacing: 1) {
                    Text(cpu, format: .currency(code: currencyCode))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isBest ? Color.qmCorrect : Color.qmWrong)
                    Text("per use")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .qmCard(cornerRadius: 14)
    }

    // MARK: - Neglected

    private var neglectedView: some View {
        VStack(spacing: 12) {
            if appModel.neglectedItems.isEmpty {
                emptyState(message: "Great! No items neglected for more than 7 days.")
            } else {
                Text("Items unused for 7+ days")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(appModel.neglectedItems) { item in
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.qmWrong)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.subheadline.weight(.medium))
                            if let last = appModel.lastUsed(for: item) {
                                Text("Last used \(last, style: .relative) ago")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Never used")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(item.price, format: .currency(code: currencyCode))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .qmCard(cornerRadius: 14)
                }
            }
        }
    }

    // MARK: - Export

    private var exportView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.qmAccent)
                Text("Export your data as CSV to review in Numbers or Excel.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            Button {
                exportCSV()
            } label: {
                HStack {
                    Image(systemName: "doc.text")
                    Text("Export CSV")
                }
                .frame(maxWidth: .infinity)
            }
            .prominentButton()

            Text("Includes item name, price, uses, cost-per-use and last used date.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .qmCard()
    }

    private func exportCSV() {
        var csv = "Name,Category,Price,Uses,Cost Per Use,Last Used\n"
        for item in appModel.items {
            let count = appModel.useCount(for: item)
            let cpu = appModel.costPerUse(for: item).map { String(format: "%.2f", $0) } ?? ""
            let last = appModel.lastUsed(for: item).map { DateFormatter.localizedString(from: $0, dateStyle: .short, timeStyle: .none) } ?? ""
            csv += "\"\(item.name)\",\"\(item.category)\",\(String(format: "%.2f", item.price)),\(count),\(cpu),\(last)\n"
        }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("peruse_export.csv")
        try? csv.write(to: tempURL, atomically: true, encoding: .utf8)
        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
        Haptics.success()
    }

    // MARK: - Helper

    private func emptyState(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 40))
                .foregroundStyle(Color.qmAccent.opacity(0.3))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 32)
    }
}
