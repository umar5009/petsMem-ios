import UIKit

/// Tab bar uses the warm background. Large navigation titles stay on the system
/// font; a custom bar appearance was hiding them.
enum InterfaceAppearance {
    static func apply() {
        // Leave the navigation bar on the system appearance. A fully custom
        // opaque bar was hiding large titles on the current iOS.
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(named: "Background")
        tab.shadowColor = UIColor(named: "Separator")
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }
}
