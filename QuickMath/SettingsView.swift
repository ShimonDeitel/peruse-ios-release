import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @AppStorage("quickmath.theme") private var themeRaw = AppTheme.system.rawValue
    @State private var showPaywall = false
    @State private var showDeleteConfirm = false

    private var theme: AppTheme {
        get { AppTheme(rawValue: themeRaw) ?? .system }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                Form {
                    // Pro status
                    Section("Per Use Pro") {
                        if store.isPro {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.qmCorrect)
                                Text("Pro is active")
                                    .font(.subheadline.weight(.medium))
                            }
                            Link("Manage Subscription",
                                 destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                                .foregroundStyle(Color.qmAccent)
                        } else {
                            Button("Unlock Per Use Pro") {
                                Haptics.tap()
                                showPaywall = true
                            }
                            .foregroundStyle(Color.qmAccent)

                            Button("Restore Purchase") {
                                Task { await store.restore() }
                            }
                            .foregroundStyle(.secondary)
                        }
                    }

                    // Appearance
                    Section("Appearance") {
                        Picker("Theme", selection: $themeRaw) {
                            ForEach(AppTheme.allCases) { t in
                                Text(t.label).tag(t.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Legal
                    Section("Legal") {
                        Link("Privacy Policy",
                             destination: URL(string: "https://shimondeitel.github.io/peruse-site/privacy.html")!)
                            .foregroundStyle(Color.qmAccent)
                        Link("Terms of Use",
                             destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            .foregroundStyle(Color.qmAccent)
                    }

                    // Data
                    Section("Data") {
                        Button("Delete All Data", role: .destructive) {
                            showDeleteConfirm = true
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(store)
            }
            .confirmationDialog(
                "Delete all items and use history? This cannot be undone.",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) {
                    Haptics.warning()
                    appModel.deleteAllData()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
