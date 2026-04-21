// CosmicTabBar.swift — Components
// Custom HStack-based tab bar with star-burst Canvas particle for active tab

import SwiftUI

enum OrionTab: Int, CaseIterable {
    case home    = 0
    case study   = 1
    case gym     = 2
    case history = 3

    var title: String {
        switch self {
        case .home:    return "Home"
        case .study:   return "Study"
        case .gym:     return "Gym"
        case .history: return "History"
        }
    }

    var icon: String {
        switch self {
        case .home:    return "house.fill"
        case .study:   return "book.fill"
        case .gym:     return "dumbbell.fill"
        case .history: return "clock.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .home:    return .auroraTeal
        case .study:   return .auroraTeal
        case .gym:     return .novaOrange
        case .history: return .pulsarPurple
        }
    }
}

struct CosmicTabBar: View {
    @Binding var selectedTab: OrionTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(OrionTab.allCases, id: \.self) { tab in
                CosmicTabItem(
                    tab: tab,
                    isSelected: selectedTab == tab
                )
                .onTapGesture {
                    if selectedTab != tab {
                        HapticManager.selection()
                        withAnimation(OrionAnimation.tabSwitch) {
                            selectedTab = tab
                        }
                    }
                }
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selectedTab == tab ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            Rectangle()
                .fill(Color.nebulaDeep)
                .overlay(
                    Rectangle()
                        .fill(Color.surfaceBorder)
                        .frame(height: 1),
                    alignment: .top
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: — Individual Tab Item
private struct CosmicTabItem: View {
    let tab: OrionTab
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Star-burst particle effect behind active icon (via Canvas)
                if isSelected {
                    StarBurstCanvas(color: tab.accentColor)
                        .frame(width: 44, height: 44)
                }

                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? tab.accentColor : Color.moonGray)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(OrionAnimation.tabSwitch, value: isSelected)
            }

            if isSelected {
                Text(tab.title)
                    .font(.moonCaption(11))
                    .foregroundStyle(tab.accentColor)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}

// MARK: — Star Burst via Canvas (zero CAEmitterLayer dependency)
private struct StarBurstCanvas: View {
    let color: Color
    @State private var phase: Double = 0

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let t = timeline.date.timeIntervalSinceReferenceDate
                let numParticles = 6

                for i in 0..<numParticles {
                    let angle = (Double(i) / Double(numParticles)) * .pi * 2 + t * 1.2
                    let pulse = (sin(t * 2.5 + Double(i)) * 0.5 + 0.5)
                    let radius = 14.0 + pulse * 6.0
                    let particleX = center.x + CGFloat(cos(angle) * radius)
                    let particleY = center.y + CGFloat(sin(angle) * radius)
                    let size = CGFloat(1.5 + pulse * 1.5)

                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: particleX - size / 2,
                            y: particleY - size / 2,
                            width: size,
                            height: size
                        )),
                        with: .color(color.opacity(0.5 + pulse * 0.4))
                    )
                }
            }
        }
    }
}
