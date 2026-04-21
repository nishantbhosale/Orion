// PulsingStarButton.swift — Components

import SwiftUI

struct PulsingStarButton: View {
    let title: String
    let systemImage: String
    let gradient: LinearGradient
    let action: () -> Void
    var isLoading: Bool = false

    @State private var isPressed = false
    @State private var glowPulse = false

    var body: some View {
        Button(action: {
            HapticManager.impact(.medium)
            action()
        }) {
            HStack(spacing: Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(.starWhite)
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.orbitHeading(17))
                    .fontWeight(.semibold)
            }
            .foregroundStyle(Color.starWhite)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .shadow(
                color: glowPulse ? Color.auroraTeal.opacity(0.5) : Color.auroraTeal.opacity(0.2),
                radius: glowPulse ? 16 : 8,
                x: 0, y: 4
            )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(OrionAnimation.buttonPress) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(OrionAnimation.buttonPress) { isPressed = false }
                }
        )
        .onAppear {
            withAnimation(OrionAnimation.pulsingGlow.repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
        .disabled(isLoading)
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to \(title.lowercased())")
    }
}
