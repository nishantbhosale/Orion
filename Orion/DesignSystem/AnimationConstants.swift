// AnimationConstants.swift — Orion Design System

import SwiftUI

enum OrionAnimation {
    // Star twinkle — 2-5s opacity sine wave
    static let twinkle = Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)

    // Shooting star — 0.6s easeIn
    static let shootingStar = Animation.easeIn(duration: 0.6)

    // Streak counter count-up — 0.8s spring
    static let streakCounter = Animation.spring(duration: 0.8)

    // Card appear — scale 0.96→1 + opacity, 0.4s spring
    static let cardAppear = Animation.spring(response: 0.4, dampingFraction: 0.7)

    // Constellation stars — 0.1s per star easeOut
    static func constellationStar(index: Int) -> Animation {
        .easeOut(duration: 0.25).delay(Double(index) * 0.06)
    }

    // Progress ring — 1.2s spring trim
    static let progressRing = Animation.spring(duration: 1.2)

    // Tab switch — 0.2s easeInOut crossfade
    static let tabSwitch = Animation.easeInOut(duration: 0.2)

    // Button press — 0.15s spring scale
    static let buttonPress = Animation.spring(response: 0.15, dampingFraction: 0.6)

    // Toast slide-in — 0.35s easeOut
    static let toastIn = Animation.easeOut(duration: 0.35)
    static let toastOut = Animation.easeIn(duration: 0.25)

    // Pulsing glow — repeating for buttons/stars
    static let pulsingGlow = Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true)
}
