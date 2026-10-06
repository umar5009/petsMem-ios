import SwiftUI

struct RootView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if dependencies.onboardingStore.hasCompleted {
                MainTabView()
            } else {
                OnboardingFlow()
            }
        }
        .background(PawColor.background.ignoresSafeArea())
        .task {
            _ = await dependencies.entitlements.restorePurchases()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                LibraryScanCoordinator.schedule()
            }
        }
    }
}
