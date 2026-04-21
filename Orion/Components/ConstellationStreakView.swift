// ConstellationStreakView.swift — Components
// Canvas-based constellation grid with sequenced star animation

import SwiftUI

struct ConstellationStreakView: View {
    let streakDays: Int           // current streak length
    let habitLogs: [HabitLog]     // for coloring (study/gym/both)
    var maxDays: Int = 30         // how many days to show in the grid

    @State private var visibleStars: Set<Int> = []

    private let columns: Int = 10
    private let starSpacing: CGFloat = 28

    var body: some View {
        let rows = Int(ceil(Double(maxDays) / Double(columns)))
        let gridWidth = CGFloat(columns) * starSpacing
        let gridHeight = CGFloat(rows) * starSpacing

        Canvas { context, size in
            let offsetX = (size.width - gridWidth) / 2
            let offsetY = (size.height - gridHeight) / 2

            // Draw connecting lines first (below dots)
            var prevCenter: CGPoint? = nil
            for i in 0..<maxDays {
                guard visibleStars.contains(i) else { prevCenter = nil; continue }
                let col = i % columns
                let row = i / columns
                let center = CGPoint(
                    x: offsetX + CGFloat(col) * starSpacing + starSpacing / 2,
                    y: offsetY + CGFloat(row) * starSpacing + starSpacing / 2
                )

                if let prev = prevCenter, i < streakDays {
                    var linePath = Path()
                    linePath.move(to: prev)
                    linePath.addLine(to: center)
                    context.stroke(
                        linePath,
                        with: .color(Color.moonGray.opacity(0.25)),
                        lineWidth: 1
                    )
                }
                prevCenter = i < streakDays ? center : nil
            }

            // Draw dots on top
            for i in 0..<maxDays {
                guard visibleStars.contains(i) else { continue }
                let col = i % columns
                let row = i / columns
                let center = CGPoint(
                    x: offsetX + CGFloat(col) * starSpacing + starSpacing / 2,
                    y: offsetY + CGFloat(row) * starSpacing + starSpacing / 2
                )

                let isCompleted = i < streakDays
                let isToday    = i == streakDays - 1

                // Determine dot color
                let dotColor = habitColor(for: i)

                if isToday {
                    // Glowing gold pulse dot for today
                    context.fill(
                        Path(ellipseIn: CGRect(x: center.x - 8, y: center.y - 8, width: 16, height: 16)),
                        with: .color(Color.streakGold.opacity(0.2))
                    )
                    context.fill(
                        Path(ellipseIn: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8)),
                        with: .color(Color.streakGold)
                    )
                } else if isCompleted {
                    context.fill(
                        Path(ellipseIn: CGRect(x: center.x - 3.5, y: center.y - 3.5, width: 7, height: 7)),
                        with: .color(dotColor)
                    )
                } else {
                    // Future/incomplete: dim dust dot
                    context.fill(
                        Path(ellipseIn: CGRect(x: center.x - 2, y: center.y - 2, width: 4, height: 4)),
                        with: .color(Color.dustGray.opacity(0.5))
                    )
                }
            }
        }
        .frame(width: gridWidth + starSpacing, height: gridHeight + starSpacing)
        .onAppear {
            animateStarsIn()
        }
        .onChange(of: streakDays) { _, _ in
            visibleStars.removeAll()
            animateStarsIn()
        }
    }

    private func animateStarsIn() {
        for i in 0..<maxDays {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.04) {
                withAnimation(OrionAnimation.constellationStar(index: i)) {
                    _ = visibleStars.insert(i)
                }
            }
        }
    }

    private func habitColor(for dayIndex: Int) -> Color {
        guard dayIndex < habitLogs.count else { return .auroraTeal }
        let log = habitLogs[dayIndex]
        if log.hasStudy && log.hasGym { return .streakGold }
        if log.hasGym   { return .novaOrange }
        return .auroraTeal
    }
}
