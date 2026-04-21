// LogGymSessionUseCase.swift — Core/UseCases

import Foundation
import SwiftData

@MainActor
final class LogGymSessionUseCase {
    private let gymRepository: GymRepository
    private let streakUseCase: StreakUseCase
    weak var xpService: XPService?

    init(gymRepository: GymRepository, streakUseCase: StreakUseCase, xpService: XPService? = nil) {
        self.gymRepository = gymRepository
        self.streakUseCase = streakUseCase
        self.xpService     = xpService
    }

    func execute(
        workoutType: GymWorkoutType,
        exercises: [ExerciseEntry],
        durationMinutes: Int,
        notes: String?,
        hasOverload: Bool = false,
        newPRCount: Int = 0
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

        // XP Awards
        await xpService?.award(.gymSessionLogged, sourceId: session.id)
        if hasOverload    { await xpService?.award(.overloadAchieved,   sourceId: session.id) }
        if newPRCount > 0 { await xpService?.award(.newPersonalRecord,  sourceId: session.id) }

        await NotificationManager.shared.updateDailyReminder()
    }
}
