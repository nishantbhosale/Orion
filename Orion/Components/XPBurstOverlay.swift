// XPBurstOverlay.swift — Components
// Floating "+15 XP ✦" label that rises and fades after every XP award.

import SwiftUI

// MARK: — View Modifier
struct XPBurstModifier: ViewModifier {
    @State private var bursts: [XPBurst] = []

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                ZStack {
                    ForEach(bursts) { burst in
                        XPBurstLabel(burst: burst)
                    }
                }
                // Sits above tab bar (~80pt) so it's visible
                .padding(.bottom, 90)
                .allowsHitTesting(false)
            }
            .onReceive(NotificationCenter.default.publisher(for: .xpAwarded)) { note in
                let points = note.userInfo?["points"] as? Int ?? 0
                guard points > 0 else { return }
                let burst = XPBurst(points: points)
                bursts.append(burst)
                // Auto-remove after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    bursts.removeAll { $0.id == burst.id }
                }
            }
    }
}

// MARK: — Single Burst Label
private struct XPBurstLabel: View {
    let burst: XPBurst
    @State private var opacity: Double = 0
    @State private var offset: CGFloat = 0

    var body: some View {
        Text("+\(burst.points) XP ✦")
            .font(.system(.subheadline, design: .rounded).weight(.bold))
            .foregroundStyle(Color.streakGold)
            .shadow(color: Color.streakGold.opacity(0.6), radius: 6)
            .opacity(opacity)
            .offset(y: offset)
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    opacity = 1
                    offset  = -40
                }
                withAnimation(.easeIn(duration: 0.4).delay(0.8)) {
                    opacity = 0
                }
            }
    }
}

// MARK: — Burst Model
private struct XPBurst: Identifiable {
    let id = UUID()
    let points: Int
}

// MARK: — Extension
extension View {
    func xpBurstOverlay() -> some View {
        modifier(XPBurstModifier())
    }
}
