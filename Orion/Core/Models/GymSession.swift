// GymSession.swift — Core/Models
// Uses JSON-encoded Data for exercises + @Transient computed property

import Foundation
import SwiftData

// MARK: — ExerciseEntry (Codable struct, not a @Model)
struct ExerciseEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var sets: Int
    var reps: Int?
    var weightKg: Double?
    var durationSeconds: Int?   // for timed exercises like planks
    var muscleGroup: MuscleGroup?   // NEW — Phase 5 (Volume)
    var restSeconds: Int = 90       // NEW — Phase 3 (Rest Timer)

    /// Summary string e.g. "Bench Press 4×8 @ 80kg"
    var summary: String {
        var parts = ["\(name)"]
        if let reps {
            parts[0] += " \(sets)×\(reps)"
        } else if let duration = durationSeconds {
            let mins = duration / 60
            let secs = duration % 60
            parts[0] += " \(sets)×\(mins > 0 ? "\(mins)m" : "")\(secs > 0 ? "\(secs)s" : "")"
        }
        if let weight = weightKg, weight > 0 {
            parts.append("@ \(String(format: "%.1f", weight))kg")
        }
        return parts.joined(separator: " ")
    }
}

enum MuscleGroup: String, CaseIterable, Codable {
    case chest, back, shoulders, legs, arms, core, fullBody, cardio

    var displayName: String { rawValue.capitalized }
    
    var systemImage: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rower"
        case .shoulders: return "figure.arms.open"
        case .legs: return "figure.run"
        case .arms: return "figure.flexibility"
        case .core: return "figure.core.training"
        case .fullBody: return "figure.mixed.cardio"
        case .cardio: return "heart.fill"
        }
    }
}

// MARK: — GymSession SwiftData Model
@Model
final class GymSession {
    var id: UUID
    var date: Date
    var workoutType: GymWorkoutType   // ✅ Typed enum, not String
    var exercisesData: Data           // ✅ JSON-encoded [ExerciseEntry]
    var durationMinutes: Int
    var notes: String?
    var createdAt: Date

    // ✅ @Transient prevents SwiftData from treating this as a persistent column
    @Transient var exercises: [ExerciseEntry] {
        get {
            (try? JSONDecoder().decode([ExerciseEntry].self, from: exercisesData)) ?? []
        }
        set {
            exercisesData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    init(
        id: UUID = UUID(),
        date: Date = .now,
        workoutType: GymWorkoutType = .push,
        exercises: [ExerciseEntry] = [],
        durationMinutes: Int,
        notes: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.workoutType = workoutType
        self.exercisesData = (try? JSONEncoder().encode(exercises)) ?? Data()
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.createdAt = createdAt
    }

    /// Formatted duration string
    var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    /// Summary of all exercises for display
    var exercisesSummary: String {
        exercises.map { $0.summary }.joined(separator: ", ")
    }
}
