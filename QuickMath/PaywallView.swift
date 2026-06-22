import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    private let benefits: [String] = [
        "Use-history timeline and 'best vs worst value' rankings",
        "Use reminders for neglected items and category insights",
        "Cost-per-use trends over time and CSV export"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 28) {
                        // Icon + title
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.qmCard)
                                    .frame(width: 80, height: 80)
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 36))
                                    .foregroundStyle(Color.qmAccent)
                            }
                            .padding(.top, 16)

                            Text("Per Use Pro")
                                .font(.title.weight(.bold))

                            Text("$0.99 / month. Auto-renews until you cancel.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        // Benefits
                        VStack(spacing: 12) {
                            ForEach(benefits, id: \.self) { benefit in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.qmCorrect)
                                        .font(.title3)
                                    Text(benefit)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                                .qmCard(cornerRadius: 14)
                            }
                        }

                        // Purchase button
                        Button {
                            Haptics.tap()
                            Task { await store.purchase() }
                        } label: {
                            if store.purchaseInFlight {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Unlock for \(store.displayPrice)/mo")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .prominentButton()
                        .disabled(store.purchaseInFlight)

                        // Restore
                        Button("Restore Purchase") {
                            Task { await store.restore() }
                        }
                        .softButton()

                        // Disclosure
                        VStack(spacing: 8) {
                            Text("Subscription auto-renews monthly at \(store.displayPrice) unless cancelled at least 24 hours before the end of the current period. Cancel anytime in your App Store subscriptions.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 16) {
                                Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                                    .font(.caption2)
                                    .foregroundStyle(Color.qmAccent)
                                Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/peruse-site/privacy.html")!)
                                    .font(.caption2)
                                    .foregroundStyle(Color.qmAccent)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onChange(of: store.isPro) { _, newValue in
            if newValue { dismiss() }
        }
    }
}
