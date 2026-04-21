// LogGymSessionUseCase.swift — Core/UseCases

import Foundation
import SwiftData

@MainActor
final class LogGymSessionUseCase {
    private let gymRepository: GymRepository
    private let streakUseCase: StreakUseCase

    init(gymRepository: GymRepository, streakUseCase: StreakUseCase) {
        self.gymRepository = gymRepository
        self.streakUseCase = streakUseCase
    }

    func execute(
        workoutType: GymWorkoutType,
        exercises: [ExerciseEntry],
        durationMinutes: Int,
        notes: String?
    ) async throws {
        guard durationMinutes > 0 else {
            throw UseCaseError.invalidInput("Duration must be greater than 0")
        }

        let session = GymSession(
            workoutType: workoutType,
            exercises: exercises,
            durationMinutes: durationMinutes,
            notes: notes?.trimmingCharacters(in: .whitespaces)
        )

        try gymRepository.save(session)
        await streakUseCase.recordHabitCompletion(category: .gym)
        await NotificationManager.shared.updateDailyReminder()
    }
}
