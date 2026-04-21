// ShootingStarToast.swift — Components

import SwiftUI

struct ShootingStarToast: View {
    let message: String
    @Binding var isShowing: Bool

    @State private var offset: CGFloat = -200
    @State private var opacity: Double = 0

    var body: some View {
        VStack {
            if isShowing {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(Color.streakGold)
                        .font(.system(size: 16))

                    Text(message)
                        .font(.starBody(15))
                        .foregroundStyle(Color.starWhite)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm + 2)
                .background(
                    Capsule()
                        .fill(Color.nebulaCard)
                        .shadow(color: Color.auroraTeal.opacity(0.3), radius: 12)
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.surfaceBorder, lineWidth: 1)
                        )
                )
                .offset(y: offset)
                .opacity(opacity)
                .onAppear {
                    // Slide in
                    withAnimation(OrionAnimation.toastIn) {
                        offset = 0
                        opacity = 1.0
                    }
                    // Auto-dismiss after 2.5s
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(OrionAnimation.toastOut) {
                            offset = -200
                            opacity = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isShowing = false
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(.top, Spacing.md)
        .allowsHitTesting(false)
    }
}

// MARK: — Toast Modifier
extension View {
    func shootingStarToast(message: String, isShowing: Binding<Bool>) -> some View {
        ZStack(alignment: .top) {
            self
            ShootingStarToast(message: message, isShowing: isShowing)
        }
    }
}
