// RestTimerOverlay.swift — Features/Gym/Components
import SwiftUI

struct RestTimerOverlay: View {
    @Environment(RestTimerManager.self) private var restTimer
    
    var body: some View {
        if restTimer.isActive || restTimer.isFinished {
            overlayContent
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: restTimer.isActive)
        }
    }
    
    private var overlayContent: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Spacer()
                
                HStack(spacing: Spacing.lg) {
                    // Ring
                    ZStack {
                        Circle()
                            .stroke(Color.novaOrange.opacity(0.2), lineWidth: 4)
                        Circle()
                            .trim(from: 0, to: restTimer.progress)
                            .stroke(restTimer.isFinished ? Color.streakGold : Color.novaOrange,
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: restTimer.progress)
                    }
                    .frame(width: 44, height: 44)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(restTimer.isFinished ? "Rest Over!" : "Rest Timer")
                            .font(.orbitHeading(14))
                            .foregroundStyle(Color.starWhite)
                        Text(restTimer.isFinished ? "Time for your next set 💪" : DateHelper.formatSeconds(restTimer.timeRemaining))
                            .font(.monoData(20))
                            .foregroundStyle(restTimer.isFinished ? Color.streakGold : Color.novaOrange)
                    }
                    
                    Spacer()
                    
                    Button {
                        HapticManager.impact(.medium)
                        restTimer.stop()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.moonGray)
                    }
                }
                .padding(Spacing.md)
                .background(.ultraThinMaterial)
                .background(Color.nebulaDeep.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .strokeBorder(
                            restTimer.isFinished ? Color.streakGold.opacity(0.4) : Color.novaOrange.opacity(0.3),
                            lineWidth: 1
                        )
                )
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, 96) // above tab bar
                .shadow(color: Color.novaOrange.opacity(0.2), radius: 12, y: 4)
            }
        }
    }
}

// MARK: — Start Rest Timer Button
struct StartRestTimerButton: View {
    let seconds: Int
    @Environment(RestTimerManager.self) private var restTimer
    
    var body: some View {
        Button {
            HapticManager.impact(.light)
            restTimer.start(seconds: seconds)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                Text(DateHelper.formatSeconds(seconds))
            }
            .font(.moonCaption(12))
            .foregroundStyle(restTimer.isActive ? Color.moonGray : Color.novaOrange)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.novaOrange.opacity(0.1))
            .clipShape(Capsule())
        }
        .disabled(restTimer.isActive)
    }
}
