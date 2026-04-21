// EmptyStateView.swift — Components

import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let subtitle: String
    var accentColor: Color = .auroraTeal

    @State private var appeared = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Glowing icon
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.08))
                    .frame(width: 100, height: 100)

                Image(systemName: systemImage)
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(accentColor.opacity(0.7))
            }
            .scaleEffect(appeared ? 1.0 : 0.7)
            .opacity(appeared ? 1.0 : 0)

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.orbitHeading())
                    .foregroundStyle(Color.starWhite)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.starBody())
                    .foregroundStyle(Color.moonGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
            .opacity(appeared ? 1.0 : 0)
            .offset(y: appeared ? 0 : 12)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(OrionAnimation.cardAppear.delay(0.1)) {
                appeared = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}
