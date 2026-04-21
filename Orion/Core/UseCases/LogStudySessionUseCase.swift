// LogStudySessionUseCase.swift — Core/UseCases

import Foundation
import SwiftData

@MainActor
final class LogStudySessionUseCase {
    private let studyRepository: StudyRepository
    private let streakUseCase: StreakUseCase
    weak var xpService: XPService?   // Optional — safe if gamification not yet injected

    init(studyRepository: StudyRepository, streakUseCase: StreakUseCase, xpService: XPService? = nil) {
        self.studyRepository = studyRepository
        self.streakUseCase   = streakUseCase
        self.xpService       = xpService
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

        // XP Awards
        await xpService?.award(.studySessionLogged, sourceId: session.id)
        if focusScore != nil {
            await xpService?.award(.focusScoreGiven, sourceId: session.id)
        }

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
