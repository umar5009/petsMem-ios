import SwiftUI

/// SF Pro Rounded for headings, SF Pro for body. Text styles follow Dynamic Type.
enum PawFont {
    static func display(_ style: Font.TextStyle = .largeTitle) -> Font {
        .system(style, design: .rounded, weight: .bold)
    }

    static func title(_ style: Font.TextStyle = .title2) -> Font {
        .system(style, design: .rounded, weight: .semibold)
    }

    static func body(_ style: Font.TextStyle = .body, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .default, weight: weight)
    }
}
