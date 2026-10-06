import UIKit

/// Soft taps on the actions people feel: continue, save, start trial.
enum Haptics {
    static func tap() {
        guard allowsFeedback else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    static func success() {
        guard allowsFeedback else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private static var allowsFeedback: Bool {
        !LaunchArguments.isUITesting
    }
}
