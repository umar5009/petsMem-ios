import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Pet.createdAt) private var pets: [Pet]
    @Query(sort: \MemoryEntry.date, order: .reverse) private var memories: [MemoryEntry]
    @State private var confirmDelete = false
    @State private var exportURL: URL?
    @State private var restoreMessage: String?
    @State private var errorMessage: String?
    @AppStorage("pawmoir.icloud.enabled") private var iCloudSync = false

    var body: some View {
        List {
            Section {
                Text("Photos are read on this device. Pawmoir does not upload your library. A caption or a print uses only the photos you pick.")
                    .font(PawFont.body(.subheadline))
                    .foregroundStyle(PawColor.textSecondary)
                    .listRowBackground(PawColor.surface)
            }
            Section("Subscription") {
                LabeledContent("Plan", value: dependencies.entitlements.isPremium ? "Premium" : "Free")
                Button("Restore purchases") {
                    Task {
                        let found = await dependencies.entitlements.restorePurchases()
                        restoreMessage = found
                            ? "Premium is on for this iPhone."
                            : "No subscription was found on this iPhone."
                    }
                }
                .frame(minHeight: 44)
            }
            .listRowBackground(PawColor.surface)
            Section("Reminders") {
                Button("Schedule reminders") {
                    Task { await scheduleReminders() }
                }
                .frame(minHeight: 44)
                Text("At most \(NotificationPlanner.weeklyCap) a week. A memorial pet only gets a quiet note.")
                    .font(PawFont.body(.footnote))
                    .foregroundStyle(PawColor.textSecondary)
            }
            .listRowBackground(PawColor.surface)
            Section("iCloud") {
                Toggle("Sync this diary", isOn: $iCloudSync)
                    .disabled(!dependencies.entitlements.isPremium)
                Text("Premium only. Quit and reopen Pawmoir after turning this on. If iCloud isn't available, the diary stays on this iPhone.")
                    .font(PawFont.body(.footnote))
                    .foregroundStyle(PawColor.textSecondary)
            }
            .listRowBackground(PawColor.surface)
            Section("Your data") {
                Button("Export my data") { export() }
                    .frame(minHeight: 44)
                if let exportURL {
                    ShareLink(item: exportURL) {
                        Label("Share export", systemImage: "square.and.arrow.up")
                    }
                    .frame(minHeight: 44)
                }
                Button("Delete all data", role: .destructive) {
                    confirmDelete = true
                }
                .frame(minHeight: 44)
            }
            .listRowBackground(PawColor.surface)
            Section("Legal") {
                Link("Privacy Policy", destination: LegalLinks.privacy)
                Link("Terms of Use", destination: LegalLinks.terms)
                Text("Account deletion on a server arrives with sign-in. Delete all data removes what is stored on this iPhone.")
                    .font(PawFont.body(.footnote))
                    .foregroundStyle(PawColor.textSecondary)
            }
            .listRowBackground(PawColor.surface)
            Section {
                LabeledContent("Version", value: version)
            }
            .listRowBackground(PawColor.surface)
        }
        .scrollContentBackground(.hidden)
        .background(PawColor.background)
        .navigationTitle("Settings")
        .confirmationDialog(
            "Delete everything stored on this iPhone?",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button("Delete all data", role: .destructive) { wipe() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Pets, memories, and the local subscription flag are removed. This does not contact Apple.")
        }
        .alert("Purchases", isPresented: Binding(
            get: { restoreMessage != nil },
            set: { if !$0 { restoreMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreMessage ?? "")
        }
        .alert("Couldn't finish", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }

    private func export() {
        do {
            exportURL = try DataStore.exportFile(pets: pets, memories: memories)
            dependencies.analytics.track(AnalyticsEvent(.dataExported))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func scheduleReminders() async {
        let allowed = await dependencies.notifications.requestAuthorization()
        guard allowed else {
            errorMessage = "Notifications are off. You can turn them on in Settings."
            return
        }
        let pets = pets.map { ($0.name, $0.birthday, $0.gotchaDay, $0.isMemorial) }
        let planned = NotificationPlanner.plan(pets: pets, now: .now, alreadyThisWeek: 0)
        await dependencies.notifications.replacePending(planned)
        restoreMessage = planned.isEmpty
            ? "Nothing to schedule yet. Add a birthday or a gotcha day."
            : "Scheduled \(planned.count) reminder\(planned.count == 1 ? "" : "s")."
    }

    private func wipe() {
        do {
            try DataStore.deleteAll(
                in: modelContext,
                entitlements: dependencies.entitlements,
                onboarding: dependencies.onboardingStore
            )
            dependencies.analytics.track(AnalyticsEvent(.dataDeleted))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
