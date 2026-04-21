// OrbitProgressRing.swift — Components

import SwiftUI

struct OrbitProgressRing: View {
    let progress: Double          // 0.0 – 1.0
    let gradient: LinearGradient
    let size: CGFloat
    let lineWidth: CGFloat
    var showPercentage: Bool = true

    @State private var animatedProgress: Double = 0

    init(
        progress: Double,
        gradient: LinearGradient = .auroraGradient,
        size: CGFloat = 72,
        lineWidth: CGFloat = 7,
        showPercentage: Bool = true
    ) {
        self.progress = progress
        self.gradient = gradient
        self.size = size
        self.lineWidth = lineWidth
        self.showPercentage = showPercentage
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.dustGray.opacity(0.4), lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: CGFloat(min(animatedProgress, 1.0)))
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Center percentage
            if showPercentage {
                Text("\(Int(animatedProgress * 100))%")
                    .font(.monoData(size * 0.22))
                    .foregroundStyle(Color.starWhite)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(OrionAnimation.progressRing) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(OrionAnimation.progressRing) {
                animatedProgress = newValue
            }
        }
    }
}
