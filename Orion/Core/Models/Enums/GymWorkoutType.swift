// GymWorkoutType.swift — Core/Models/Enums

import SwiftUI

enum GymWorkoutType: String, CaseIterable, Codable, Identifiable {
    case push      = "push"
    case pull      = "pull"
    case legs      = "legs"
    case fullBody  = "full_body"
    case cardio    = "cardio"
    case rest      = "rest"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .push:     return "Push"
        case .pull:     return "Pull"
        case .legs:     return "Legs"
        case .fullBody: return "Full Body"
        case .cardio:   return "Cardio"
        case .rest:     return "Rest"
        }
    }

    var systemImage: String {
        switch self {
        case .push:     return "figure.strengthtraining.traditional"
        case .pull:     return "figure.rowing"
        case .legs:     return "figure.run"
        case .fullBody: return "figure.mixed.cardio"
        case .cardio:   return "heart.circle.fill"
        case .rest:     return "moon.zzz.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .push:     return .novaOrange
        case .pull:     return .auroraTeal
        case .legs:     return .pulsarPurple
        case .fullBody: return .streakGold
        case .cardio:   return .hotPink
        case .rest:     return .moonGray
        }
    }

    /// Smart exercise suggestions per workout type
    var exerciseSuggestions: [String] {
        switch self {
        case .push:
            return ["Bench Press", "Overhead Press", "Incline Dumbbell Press", "Tricep Dips",
                    "Cable Flyes", "Lateral Raises", "Tricep Pushdown", "Chest Dips"]
        case .pull:
            return ["Pull-Ups", "Barbell Row", "Lat Pulldown", "Seated Cable Row",
                    "Face Pulls", "Bicep Curls", "Hammer Curls", "Shrugs"]
        case .legs:
            return ["Squats", "Romanian Deadlift", "Leg Press", "Lunges",
                    "Leg Extensions", "Leg Curls", "Calf Raises", "Hip Thrusts"]
        case .fullBody:
            return ["Deadlift", "Clean & Press", "Burpees", "Kettlebell Swings",
                    "Thrusters", "Pull-Ups", "Push-Ups", "Goblet Squats"]
        case .cardio:
            return ["Running", "Cycling", "Jump Rope", "Rowing Machine",
                    "Stair Climber", "Swimming", "HIIT Intervals", "Elliptical"]
        case .rest:
            return ["Stretching", "Foam Rolling", "Meditation", "Light Walk", "Yoga"]
        }
    }
}
