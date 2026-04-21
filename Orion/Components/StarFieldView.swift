// StarFieldView.swift — Components
// Canvas-based animated star field with twinkling, shooting stars, and nebula glows

import SwiftUI

// MARK: — Star Model (seeded for stable positions)
private struct Star {
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let baseOpacity: Double
    let twinklePeriod: Double  // 2–5 seconds per star
    let phaseOffset: Double    // so stars don't pulse in sync
}

private struct ShootingStar {
    var isVisible: Bool = false
    var startX: CGFloat = 0
    var startY: CGFloat = 0
    var endX: CGFloat = 0
    var endY: CGFloat = 0
    var progress: CGFloat = 0
}

struct StarFieldView: View {
    private let stars: [Star]
    @State private var shootingStars: [ShootingStar] = Array(repeating: ShootingStar(), count: 4)
    @State private var shootingStarTimer: Timer?

    init() {
        // Seeded random for stable positions
        var rng = SeededRNG(seed: 42)
        self.stars = (0..<200).map { _ in
            Star(
                x: CGFloat(rng.next()),
                y: CGFloat(rng.next()),
                size: 0.5 + CGFloat(rng.next()) * 2.0,
                baseOpacity: 0.2 + rng.next() * 0.8,
                twinklePeriod: 2.0 + rng.next() * 3.0,
                phaseOffset: rng.next() * .pi * 2
            )
        }
    }

    var body: some View {
        ZStack {
            // Cosmic black base
            Color.cosmicBlack.ignoresSafeArea()

            // Nebula glow blobs
            nebulaGlows

            // Animated star field
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    for star in stars {
                        let phase = time / star.twinklePeriod + star.phaseOffset
                        let opacity = star.baseOpacity * (0.4 + 0.6 * (sin(phase) * 0.5 + 0.5))
                        let center = CGPoint(x: star.x * size.width, y: star.y * size.height)
                        context.fill(
                            Path(ellipseIn: CGRect(
                                x: center.x - star.size / 2,
                                y: center.y - star.size / 2,
                                width: star.size,
                                height: star.size
                            )),
                            with: .color(.starWhite.opacity(opacity))
                        )
                    }
                }
            }

            // Shooting stars overlay
            GeometryReader { geo in
                ForEach(shootingStars.indices, id: \.self) { index in
                    if shootingStars[index].isVisible {
                        ShootingStarView(star: shootingStars[index])
                    }
                }
                .onAppear {
                    startShootingStarCycle(in: geo.size)
                }
                .onDisappear {
                    shootingStarTimer?.invalidate()
                    shootingStarTimer = nil
                }
            }
        }
    }

    // MARK: — Nebula Glow Blobs
    private var nebulaGlows: some View {
        ZStack {
            // Top-left teal glow
            RadialGradient(
                colors: [Color.auroraTeal.opacity(0.07), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 300
            )

            // Bottom-right purple glow
            RadialGradient(
                colors: [Color.pulsarPurple.opacity(0.06), .clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 280
            )

            // Center deep blue glow
            RadialGradient(
                colors: [Color(hex: "#1a1a4e").opacity(0.08), .clear],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
        }
        .ignoresSafeArea()
    }

    // MARK: — Shooting Star Logic
    private func startShootingStarCycle(in size: CGSize) {
        func scheduleNext() {
            let delay = Double.random(in: 8...15)
            shootingStarTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
                Task { @MainActor in
                    launchShootingStar(in: size)
                    scheduleNext()
                }
            }
        }
        scheduleNext()
        // Also launch one immediately after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            launchShootingStar(in: size)
        }
    }

    @MainActor
    private func launchShootingStar(in size: CGSize) {
        let index = shootingStars.indices.first(where: { !shootingStars[$0].isVisible }) ?? 0
        let startX = CGFloat.random(in: 0...size.width * 0.6)
        let startY = CGFloat.random(in: 0...size.height * 0.4)
        let length = CGFloat.random(in: 120...220)
        let angle = CGFloat.random(in: 20...60) * .pi / 180

        shootingStars[index] = ShootingStar(
            isVisible: true,
            startX: startX,
            startY: startY,
            endX: startX + length * cos(angle),
            endY: startY + length * sin(angle),
            progress: 0
        )

        withAnimation(.easeIn(duration: 0.6)) {
            shootingStars[index].progress = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            shootingStars[index].isVisible = false
            shootingStars[index].progress  = 0
        }
    }
}

// MARK: — Shooting Star View
private struct ShootingStarView: View {
    let star: ShootingStar

    var body: some View {
        let dx = star.endX - star.startX
        let dy = star.endY - star.startY
        let length = sqrt(dx * dx + dy * dy)
        let angle = atan2(dy, dx)

        Capsule()
            .fill(
                LinearGradient(
                    colors: [.white, Color.auroraTeal.opacity(0.6), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: length * star.progress, height: 1.5)
            .position(x: star.startX + dx * star.progress / 2,
                      y: star.startY + dy * star.progress / 2)
            .rotationEffect(.radians(angle))
            .opacity(star.progress > 0.8 ? (1.0 - star.progress) * 5 : 1.0)
    }
}

// MARK: — Seeded RNG (for stable star positions across redraws)
private struct SeededRNG {
    private var state: UInt64

    init(seed: UInt64) { self.state = seed }

    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        let result = (state >> 33) ^ state
        return Double(result) / Double(UInt64.max)
    }
}
