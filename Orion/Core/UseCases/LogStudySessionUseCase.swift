// LogStudySessionUseCase.swift — Core/UseCases

import Foundation
import SwiftData

@MainActor
final class LogStudySessionUseCase {
    private let studyRepository: StudyRepository
    private let streakUseCase: StreakUseCase

    init(studyRepository: StudyRepository, streakUseCase: StreakUseCase) {
        self.studyRepository = studyRepository
        self.streakUseCase = streakUseCase
    }

    func execute(
        moduleName: String,
        topicDetail: String?,
        subject: String,
        durationMinutes: Int,
        focusScore: Int?,
        notes: String?
    ) async throws {
        guard !moduleName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw UseCaseError.invalidInput("Module name cannot be empty")
        }
        guard durationMinutes > 0 else {
            throw UseCaseError.invalidInput("Duration must be greater than 0")
        }

        let session = StudySession(
            moduleName: moduleName.trimmingCharacters(in: .whitespaces),
            topicDetail: topicDetail?.trimmingCharacters(in: .whitespaces),
            subject: subject,
            durationMinutes: durationMinutes,
            focusScore: focusScore,
            notes: notes?.trimmingCharacters(in: .whitespaces)
        )

        try studyRepository.save(session)
        await streakUseCase.recordHabitCompletion(category: .study)

        // Schedule streak danger reminder update
        await NotificationManager.shared.updateDailyReminder()
    }
}

// MARK: — Shared Error Type
enum UseCaseError: LocalizedError {
    case invalidInput(String)
    case persistenceFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidInput(let msg):      return msg
        case .persistenceFailed(let err): return err.localizedDescription
        }
    }
}
