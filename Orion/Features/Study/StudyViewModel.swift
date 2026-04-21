// StudyViewModel.swift — Features/Study

import Foundation
import SwiftData
import Observation
import SwiftUI

@Observable
@MainActor
final class StudyViewModel {
    private let studyRepository: StudyRepository
    private let logUseCase: LogStudySessionUseCase

    // Form state
    var moduleName: String = ""
    var topicDetail: String = ""
    var subject: String = UserPreferencesKey.defaultStudySubjects.first ?? "Computer Science"
    var notes: String = ""

    // Duration
    var hours: Int = 0
    var minutes: Int = 30
    var useTimer: Bool = false
    var timerSeconds: Int = 0
    var timerRunning: Bool = false

    // UI state
    var isLogging: Bool = false
    var showToast: Bool = false
    var toastMessage: String = ""
    var errorMessage: String? = nil
    var showFocusRatingSheet: Bool = false

    // Today's sessions (loaded separately for display in the view via @Query)
    // Stats
    var weeklyMinutes: Int = 0
    var weeklySessions: Int = 0
    var longestSessionMinutes: Int = 0

    private var timerTask: Task<Void, Never>?

    private let streakUseCase: StreakUseCase

    init(studyRepository: StudyRepository, streakUseCase: StreakUseCase) {
        self.studyRepository = studyRepository
        self.streakUseCase = streakUseCase
        self.logUseCase = LogStudySessionUseCase(
            studyRepository: studyRepository,
            streakUseCase: streakUseCase
        )
    }

    // MARK: — Timer Controls
    func startTimer() {
        timerRunning = true
        timerSeconds = 0
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !Task.isCancelled {
                    timerSeconds += 1
                }
            }
        }
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
        timerRunning = false
        // Auto-fill hours/minutes from timer
        hours   = timerSeconds / 3600
        minutes = (timerSeconds % 3600) / 60
        if minutes == 0 && hours == 0 { minutes = 1 }
    }

    func onDisappear() {
        timerTask?.cancel()
        timerTask = nil
        timerRunning = false
    }

    // MARK: — Computed Duration
    var totalMinutes: Int {
        useTimer ? max(timerSeconds / 60, 1) : (hours * 60 + minutes)
    }

    var timerDisplay: String {
        DateHelper.formatSeconds(timerSeconds)
    }

    // MARK: — Log Session
    func logSession() {
        guard !isLogging else { return }
        showFocusRatingSheet = true
    }
    
    func commitSession(focusScore: Int?) async {
        isLogging = true
        errorMessage = nil

        do {
            try await logUseCase.execute(
                moduleName: moduleName,
                topicDetail: topicDetail.isEmpty ? nil : topicDetail,
                subject: subject,
                durationMinutes: totalMinutes,
                focusScore: focusScore,
                notes: notes.isEmpty ? nil : notes
            )

            HapticManager.notification(.success)
            toastMessage = "Session logged! 🌟"
            showToast = true
            resetForm()
            await loadWeeklyStats()
            // Force validate streak context in memory immediately
            await streakUseCase.validateAndUpdateStreak()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.notification(.error)
        }
        isLogging = false
    }

    func deleteSession(_ session: StudySession) {
        do {
            try studyRepository.delete(session)
            Task { 
                await loadWeeklyStats()
                let todaySessions = (try? studyRepository.fetchToday()) ?? []
                let hasStudy = !todaySessions.isEmpty
                await streakUseCase.forceRecalculateToday(hasStudy: hasStudy, hasGym: nil)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: — Stats
    func loadWeeklyStats() async {
        do {
            let weekly = try studyRepository.fetchThisWeek()
            weeklySessions = weekly.count
            weeklyMinutes  = weekly.reduce(0) { $0 + $1.durationMinutes }
            longestSessionMinutes = weekly.max(by: { $0.durationMinutes < $1.durationMinutes })?.durationMinutes ?? 0
        } catch {}
    }

    // MARK: — Form Reset
    private func resetForm() {
        moduleName  = ""
        topicDetail = ""
        subject     = UserPreferencesKey.defaultStudySubjects.first ?? "Computer Science"
        notes       = ""
        hours       = 0
        minutes     = 30
        timerSeconds = 0
    }
}
