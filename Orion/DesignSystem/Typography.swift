// Typography.swift — Orion Design System

import SwiftUI

extension Font {
    // MARK: — Display
    static func cosmicTitle(_ size: CGFloat = 34) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    // MARK: — Headings
    static func orbitHeading(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    // MARK: — Body
    static func starBody(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    // MARK: — Caption
    static func moonCaption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    // MARK: — Monospace / Data
    static func monoData(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }

    // MARK: — Streak Counter (extra large)
    static func streakCounter(_ size: CGFloat = 64) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }
}

// MARK: — View Modifier for scaled fonts
struct ScaledFont: ViewModifier {
    var font: Font

    func body(content: Content) -> some View {
        content
            .font(font)
            .dynamicTypeSize(.small ... .accessibility3)
    }
}

extension View {
    func scaledFont(_ font: Font) -> some View {
        modifier(ScaledFont(font: font))
    }
}
