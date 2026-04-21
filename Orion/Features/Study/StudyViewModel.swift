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

    init(studyRepository: StudyRepository, streakUseCase: StreakUseCase, xpService: XPService? = nil) {
        self.studyRepository = studyRepository
        self.streakUseCase = streakUseCase
        self.logUseCase = LogStudySessionUseCase(
            studyRepository: studyRepository,
            streakUseCase: streakUseCase,
            xpService: xpService
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
// PomodoroManager.swift — Features/Study
// Governs Pomodoro lifecycle: phases, countdown, background drift compensation,
// notifications, and daily star tally. Consumed via @Environment from OrionApp.

import Foundation
import SwiftUI
import UserNotifications

enum PomodoroPhase: String {
    case focus      = "Focus"
    case shortBreak = "Short Break"
    case longBreak  = "Long Break"

    var icon: String {
        switch self {
        case .focus:      return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak:  return "moon.zzz.fill"
        }
    }
}

@Observable
final class PomodoroManager {
    // ── AppStorage keys (backing values)
    @ObservationIgnored @AppStorage(UserPreferencesKey.pomodoroDurationMinutes)   private var focusMins: Int = 25
    @ObservationIgnored @AppStorage(UserPreferencesKey.pomodoroShortBreakMinutes) private var shortMins: Int = 5
    @ObservationIgnored @AppStorage(UserPreferencesKey.pomodoroLongBreakMinutes)  private var longMins: Int  = 15
    @ObservationIgnored @AppStorage(UserPreferencesKey.todayPomodoroStars)        private var storedStars: Int = 0
    @ObservationIgnored @AppStorage(UserPreferencesKey.todayPomodoroStarsDate)    private var starsDate: String = ""

    // ── Public state
    var phase: PomodoroPhase = .focus
    var timeRemaining: Int   = 0
    var isRunning: Bool      = false
    var completedPomodoros: Int = 0
    var todayStars: Int = 0

    // ── Private
    private var timerTask: Task<Void, Never>? = nil
    private var backgroundedAt: Date? = nil
    weak var xpService: XPService?    // Set from OrionApp after init

    // Number of focus pomodoros before a long break
    private let longBreakInterval = 4

    init() {
        let today = DateHelper.formatDate(.now, format: "yyyy-MM-dd")
        if starsDate == today {
            todayStars = storedStars
        } else {
            // New day — reset star count
            todayStars = 0
            storedStars = 0
            starsDate = today
            completedPomodoros = 0
        }
        timeRemaining = focusMins * 60
    }

    // MARK: — Controls

    func start() {
        guard !isRunning else { return }
        isRunning = true
        scheduleBackgroundNotification()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { break }
                await MainActor.run { self?.tick() }
            }
        }
    }

    func pause() {
        isRunning = false
        timerTask?.cancel()
        timerTask = nil
        cancelPendingNotifications()
    }

    func stop() {
        pause()
        phase = .focus
        timeRemaining = focusMins * 60
        completedPomodoros = 0
    }

    func skipPhase() {
        pause()
        advancePhase()
    }

    // MARK: — Scene Phase Handling (called from OrionApp.swift)

    func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            if isRunning {
                backgroundedAt = Date.now
            }
        case .active:
            if isRunning, let bg = backgroundedAt {
                let elapsed = Int(Date.now.timeIntervalSince(bg))
                backgroundedAt = nil
                if elapsed > 0 {
                    fastForward(seconds: elapsed)
                }
            }
        default:
            break
        }
    }

    // MARK: — Fast-Forward (background drift compensation)
    // Advances the state machine by `seconds` worth of elapsed time, handling
    // multiple phase rollovers correctly.
    func fastForward(seconds: Int) {
        var remaining = seconds
        while remaining > 0 {
            if remaining >= timeRemaining {
                remaining -= timeRemaining
                advancePhase()
            } else {
                timeRemaining -= remaining
                remaining = 0
            }
        }
    }

    // MARK: — Internal

    private func tick() {
        guard isRunning else { return }
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            advancePhase()
        }
    }

    private func advancePhase() {
        cancelPendingNotifications()
        switch phase {
        case .focus:
            completedPomodoros += 1
            grantStar()
            // Award XP for completing a pomodoro (focus phase only; skip doesn't award)
            Task { await xpService?.award(.pomodoroCompleted) }
            if completedPomodoros % longBreakInterval == 0 {
                phase = .longBreak
                timeRemaining = longMins * 60
            } else {
                phase = .shortBreak
                timeRemaining = shortMins * 60
            }
        case .shortBreak, .longBreak:
            phase = .focus
            timeRemaining = focusMins * 60
        }
        if isRunning {
            scheduleBackgroundNotification()
        }
    }

    private func grantStar() {
        let today = DateHelper.formatDate(.now, format: "yyyy-MM-dd")
        if starsDate != today {
            todayStars = 0
            storedStars = 0
            starsDate = today
        }
        todayStars += 1
        storedStars = todayStars
    }

    // MARK: — Notifications

    private func scheduleBackgroundNotification() {
        cancelPendingNotifications()
        let content = UNMutableNotificationContent()
        let phaseLabel = phase.rawValue
        content.title = "Orion · \(phaseLabel) Complete"
        content.body  = phase == .focus ? "Focus session done ⭐ — take a break!" : "Break's over — back to the stars 🚀"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(timeRemaining), repeats: false)
        let request  = UNNotificationRequest(identifier: "orion_pomodoro_phase", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelPendingNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["orion_pomodoro_phase"])
    }

    // MARK: — Computed Helpers

    var progress: Double {
        let total = totalDurationForCurrentPhase
        guard total > 0 else { return 0 }
        return 1.0 - (Double(timeRemaining) / Double(total))
    }

    var timeDisplay: String {
        DateHelper.formatSeconds(timeRemaining)
    }

    private var totalDurationForCurrentPhase: Int {
        switch phase {
        case .focus:      return focusMins * 60
        case .shortBreak: return shortMins * 60
        case .longBreak:  return longMins * 60
        }
    }
}
