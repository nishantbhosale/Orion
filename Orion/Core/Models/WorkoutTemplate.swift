// WorkoutTemplate.swift — Core/Models
import Foundation
import SwiftData

@Model
final class WorkoutTemplate: Identifiable {
    var id: UUID
    var name: String
    var workoutType: GymWorkoutType    // reuses existing enum from GymSession
    var exercises: [TemplateExercise]
    var notes: String?
    var createdAt: Date
    var lastUsedAt: Date?
    var useCount: Int

    init(
        id: UUID = UUID(),
        name: String,
        workoutType: GymWorkoutType,
        exercises: [TemplateExercise] = [],
        notes: String? = nil,
        createdAt: Date = .now,
        useCount: Int = 0
    ) {
        self.id          = id
        self.name        = name
        self.workoutType = workoutType
        self.exercises   = exercises
        self.notes       = notes
        self.createdAt   = createdAt
        self.useCount    = useCount
    }
}

// Light-weight value type stored as a Codable array inside WorkoutTemplate
struct TemplateExercise: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var sets: Int
    var reps: Int?
    var weightKg: Double?
    var muscleGroup: MuscleGroup?
    var restSeconds: Int = 90

    func toExerciseEntry() -> ExerciseEntry {
        ExerciseEntry(
            name: name,
            sets: sets,
            reps: reps,
            weightKg: weightKg,
            muscleGroup: muscleGroup,
            restSeconds: restSeconds
        )
    }
}
