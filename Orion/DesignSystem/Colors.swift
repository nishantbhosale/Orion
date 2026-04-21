// Colors.swift — Orion Design System
// Deep Space color palette

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Color {
    // MARK: — Background Layers
    static let cosmicBlack     = Color(hex: "#050508")
    static let nebulaDeep      = Color(hex: "#080B14")
    static let nebulaCard      = Color(hex: "#0D1220")
    static let nebulaCardHover = Color(hex: "#111827")
    static let surfaceBorder   = Color(white: 1.0, opacity: 0.06)

    // MARK: — Text Hierarchy
    static let starWhite       = Color(hex: "#F0F4FF")
    static let moonGray        = Color(hex: "#8B92A9")
    static let dustGray        = Color(hex: "#3E4458")

    // MARK: — Accent Colors
    static let auroraTeal      = Color(hex: "#4ECDC4")
    static let novaOrange      = Color(hex: "#FF6B35")
    static let streakGold      = Color(hex: "#FFD166")
    static let pulsarPurple    = Color(hex: "#A78BFA")
    static let hotPink         = Color(hex: "#FF3CAC")
}

extension LinearGradient {
    // MARK: — Gradient Definitions
    static let auroraGradient = LinearGradient(
        colors: [Color.auroraTeal.opacity(0.8), Color.pulsarPurple.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let novaGradient = LinearGradient(
        colors: [Color.novaOrange.opacity(0.8), Color.hotPink.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let streakGradient = LinearGradient(
        colors: [Color.streakGold, Color.novaOrange],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let cosmicBackground = LinearGradient(
        colors: [Color.cosmicBlack, Color.nebulaDeep],
        startPoint: .top,
        endPoint: .bottom
    )
}
