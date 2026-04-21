// NebulaCardView.swift — Components

import SwiftUI

struct NebulaCardView<Content: View>: View {
    let content: Content
    var accentColor: Color = .clear
    var showAccentLine: Bool = false
    @State private var appeared = false

    init(
        accentColor: Color = .clear,
        showAccentLine: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.accentColor = accentColor
        self.showAccentLine = showAccentLine
    }

    var body: some View {
        HStack(spacing: 0) {
            // Optional left accent border line
            if showAccentLine {
                Rectangle()
                    .fill(accentColor)
                    .frame(width: 3)
                    .clipShape(RoundedRectangle(cornerRadius: 1.5))
            }

            content
                .padding(Spacing.md)
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.nebulaCard)
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .strokeBorder(Color.surfaceBorder, lineWidth: 1)
        )
        .scaleEffect(appeared ? 1.0 : 0.96)
        .opacity(appeared ? 1.0 : 0)
        .onAppear {
            withAnimation(OrionAnimation.cardAppear) {
                appeared = true
            }
        }
    }
}
