// PRLog.swift — Core/Models
import Foundation
import SwiftData

/// Records a personal-record 1RM estimate for a given exercise on a given date.
@Model
final class PRLog: Identifiable {
    var id: UUID
    var exerciseName: String
    var date: Date
    var estimated1RMkg: Double    // Epley estimate
    var performedWeightKg: Double
    var performedReps: Int
    var notes: String?

    init(
        id: UUID = UUID(),
        exerciseName: String,
        date: Date = .now,
        estimated1RMkg: Double,
        performedWeightKg: Double,
        performedReps: Int,
        notes: String? = nil
    ) {
        self.id                  = id
        self.exerciseName        = exerciseName
        self.date                = date
        self.estimated1RMkg      = estimated1RMkg
        self.performedWeightKg   = performedWeightKg
        self.performedReps       = performedReps
        self.notes               = notes
    }
}

// MARK: — Epley 1RM Formula
extension PRLog {
    /// Epley formula: 1RM = weight × (1 + reps/30)
    static func epley(weightKg: Double, reps: Int) -> Double {
        guard reps > 0, weightKg > 0 else { return 0 }
        return weightKg * (1.0 + Double(reps) / 30.0)
    }
}
