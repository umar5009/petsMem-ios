import Foundation

enum LaunchArguments {
    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-testing")
    }

    /// Skips onboarding and inserts a sample pet so the tab shell can be reviewed.
    static var seedsPreviewData: Bool {
        ProcessInfo.processInfo.arguments.contains("-preview-data")
    }
}
