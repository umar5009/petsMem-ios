import SwiftUI
import UIKit

@MainActor
@main
struct PawmoirApp: App {
    @State private var bootstrap: AppBootstrap

    init() {
        InterfaceAppearance.apply()
        if LaunchArguments.isUITesting {
            UIView.setAnimationsEnabled(false)
        }
        do {
            _bootstrap = State(initialValue: .ready(try AppDependencies.live()))
        } catch {
            _bootstrap = State(initialValue: .failed(error.localizedDescription))
        }
    }

    var body: some Scene {
        WindowGroup {
            switch bootstrap {
            case .ready(let dependencies):
                RootView()
                    .environment(dependencies)
                    .modelContainer(dependencies.modelContainer)
                    .tint(PawColor.primary)
            case .failed(let message):
                LaunchFailureView(message: message)
            }
        }
    }
}

enum AppBootstrap {
    case ready(AppDependencies)
    case failed(String)
}

struct LaunchFailureView: View {
    var message: String

    var body: some View {
        EmptyStateView(
            systemImage: "exclamationmark.triangle",
            title: "Pawmoir couldn't open",
            message: message
        )
        .background(PawColor.background.ignoresSafeArea())
    }
}
