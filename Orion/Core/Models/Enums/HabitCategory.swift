// HabitCategory.swift — Core/Models/Enums

import SwiftUI

enum HabitCategory: String, Codable, CaseIterable {
    case study = "study"
    case gym   = "gym"

    var displayName: String {
        switch self {
        case .study: return "Study"
        case .gym:   return "Gym"
        }
    }

    var systemImage: String {
        switch self {
        case .study: return "book.fill"
        case .gym:   return "dumbbell.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .study: return .auroraTeal
        case .gym:   return .novaOrange
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .study: return .auroraGradient
        case .gym:   return .novaGradient
        }
    }
}
