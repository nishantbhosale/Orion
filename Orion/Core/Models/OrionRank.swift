// OrionRank.swift — Core/Models
import SwiftUI

enum OrionRank: Int, CaseIterable, Comparable {
    case stargazer    = 0
    case wanderer     = 1
    case explorer     = 2
    case navigator    = 3
    case pioneer      = 4
    case sentinel     = 5
    case luminary     = 6
    case cosmosbound  = 7
    case voidwalker   = 8
    case orion        = 9

    static let xpThresholds: [Int] = [
        0, 500, 1_500, 3_500, 7_000,
        13_000, 22_000, 35_000, 55_000, 85_000
    ]

    static func rank(for xp: Int) -> OrionRank {
        var current = OrionRank.stargazer
        for rank in OrionRank.allCases {
            if xp >= xpThresholds[rank.rawValue] { current = rank }
            else { break }
        }
        return current
    }

    func nextRank() -> OrionRank? {
        OrionRank(rawValue: rawValue + 1)
    }

    func xpForThisRank() -> Int {
        OrionRank.xpThresholds[rawValue]
    }

    func xpForNextRank() -> Int? {
        guard let next = nextRank() else { return nil }
        return OrionRank.xpThresholds[next.rawValue]
    }

    func xpToNextRank(currentXP: Int) -> Int? {
        guard let nextThreshold = xpForNextRank() else { return nil }
        return max(0, nextThreshold - currentXP)
    }

    /// 0.0 → 1.0 progress from this rank's threshold to the next
    func progressFraction(currentXP: Int) -> Double {
        guard let nextThreshold = xpForNextRank() else { return 1.0 }
        let thisThreshold = xpForThisRank()
        let span = nextThreshold - thisThreshold
        guard span > 0 else { return 1.0 }
        return min(1.0, Double(currentXP - thisThreshold) / Double(span))
    }

    var displayName: String {
        switch self {
        case .stargazer:   return "Stargazer"
        case .wanderer:    return "Wanderer"
        case .explorer:    return "Explorer"
        case .navigator:   return "Navigator"
        case .pioneer:     return "Pioneer"
        case .sentinel:    return "Sentinel"
        case .luminary:    return "Luminary"
        case .cosmosbound: return "Cosmosbound"
        case .voidwalker:  return "Voidwalker"
        case .orion:       return "Orion"
        }
    }

    var flavorText: String {
        switch self {
        case .stargazer:   return "You look up and wonder."
        case .wanderer:    return "The first steps are taken."
        case .explorer:    return "The cosmos stretches before you."
        case .navigator:   return "You chart your own course."
        case .pioneer:     return "Where you go, others follow."
        case .sentinel:    return "Steadfast beneath the stars."
        case .luminary:    return "A light in the deep."
        case .cosmosbound: return "The void calls your name."
        case .voidwalker:  return "Between the stars, you are at home."
        case .orion:       return "You have reached the stars. ✦"
        }
    }

    var accentColor: Color {
        switch self {
        case .stargazer, .wanderer:          return .moonGray
        case .explorer, .navigator:          return .auroraTeal
        case .pioneer, .sentinel:            return .streakGold
        case .luminary, .cosmosbound:        return .pulsarPurple
        case .voidwalker, .orion:            return .starWhite
        }
    }

    var symbolName: String {
        switch self {
        case .stargazer:   return "star"
        case .wanderer:    return "wind"
        case .explorer:    return "binoculars.fill"
        case .navigator:   return "map.fill"
        case .pioneer:     return "flag.fill"
        case .sentinel:    return "shield.fill"
        case .luminary:    return "lightbulb.fill"
        case .cosmosbound: return "airplane"
        case .voidwalker:  return "moon.fill"
        case .orion:       return "sparkles"
        }
    }

    static func < (lhs: OrionRank, rhs: OrionRank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
