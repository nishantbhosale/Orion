// HomeViewModel.swift — Features/Home

import Foundation
import SwiftData
import Observation
import SwiftUI

@Observable
@MainActor
final class HomeViewModel {
    private let studyRepository: StudyRepository
    private let gymRepository: GymRepository
    private let weightRepository: BodyMetricRepositoryProtocol
    let streakUseCase: StreakUseCase
    weak var xpService: XPService?

    // XP
    var totalXP: Int = 0
    var todayXP: Int = 0
    var currentRank: OrionRank = .stargazer

    // Streak
    var displayedStreak: Int = 0
    var currentStreak: Int = 0
    var todayCompleted: Bool = false

    // Weight
    var latestWeightStr: String?

    // Today's progress
    var studyMinutesToday: Int = 0
    var gymSessionsToday: Int = 0
    var recentSessions: [(category: HabitCategory, title: String, subtitle: String, duration: String, date: Date)] = []

    // Habit logs for constellation
    var habitLogs: [HabitLog] = []

    @ObservationIgnored @AppStorage(UserPreferencesKey.studyGoalMinutes)
    var studyGoalMinutes: Int = UserPreferencesKey.defaultStudyGoalMinutes

    @ObservationIgnored @AppStorage(UserPreferencesKey.gymGoalSessions)
    var gymGoalSessions: Int = UserPreferencesKey.defaultGymGoalSessions

    @ObservationIgnored @AppStorage(UserPreferencesKey.weightUnit)
    var weightUnit: String = "kg"

    var studyProgress: Double {
        guard studyGoalMinutes > 0 else { return 0 }
        return min(Double(studyMinutesToday) / Double(studyGoalMinutes), 1.0)
    }

    var gymProgress: Double {
        guard gymGoalSessions > 0 else { return 0 }
        return min(Double(gymSessionsToday) / Double(gymGoalSessions), 1.0)
    }

    var todayStudyFormatted: String {
        DateHelper.formatDuration(minutes: studyMinutesToday)
    }

    init(
        studyRepository: StudyRepository, 
        gymRepository: GymRepository, 
        weightRepository: BodyMetricRepositoryProtocol,
        streakUseCase: StreakUseCase,
        xpService: XPService? = nil
    ) {
        self.studyRepository  = studyRepository
        self.gymRepository    = gymRepository
        self.weightRepository = weightRepository
        self.streakUseCase    = streakUseCase
        self.xpService        = xpService
    }

    func onAppear() async {
        await refresh()
        animateStreakCounter()
    }

    func refresh() async {
        do {
            let todayStudy = try studyRepository.fetchToday()
            let todayGym   = try gymRepository.fetchToday()

            studyMinutesToday = todayStudy.reduce(0) { $0 + $1.durationMinutes }
            gymSessionsToday  = todayGym.count
            currentStreak     = streakUseCase.currentStreak
            todayCompleted    = streakUseCase.todayCompleted
            totalXP           = xpService?.totalXP ?? 0
            todayXP           = xpService?.todayXP  ?? 0
            currentRank       = xpService?.currentRank ?? .stargazer
            
            // Weight refresh
            if let weight = try weightRepository.fetchLatest() {
                let unit = weightUnit
                let weightVal = weight.weightKg // Simplified, unit conversion in v1.2 or via computed
                let daysAgo = Calendar.current.dateComponents([.day], from: weight.date, to: .now).day ?? 0
                let dateStr = daysAgo == 0 ? "Today" : (daysAgo == 1 ? "Yesterday" : "\(daysAgo)d ago")
                latestWeightStr = "\(String(format: "%.1f", weightVal))\(unit) · \(dateStr)"
            } else {
                latestWeightStr = nil
            }

            // Build recent sessions list (last 5 across both categories)
            let studySessions: [(HabitCategory, String, String, String, Date)] = (try studyRepository.fetchAll())
                .prefix(5)
                .map { (.study, $0.moduleName, $0.topicDetail ?? $0.subject, $0.formattedDuration, $0.date) }

            let gymSessions: [(HabitCategory, String, String, String, Date)] = (try gymRepository.fetchAll())
                .prefix(5)
                .map { (.gym, $0.workoutType.displayName, $0.exercisesSummary, $0.formattedDuration, $0.date) }

            let combined = (studySessions + gymSessions).sorted { $0.4 > $1.4 }
            recentSessions = combined.prefix(5).map { (category: $0.0, title: $0.1, subtitle: $0.2, duration: $0.3, date: $0.4) }
        } catch {
            // Keep existing data on error
        }
    }

    private func animateStreakCounter() {
        displayedStreak = 0
        let target = currentStreak
        guard target > 0 else { return }

        let stepDuration = 0.8 / Double(target)
        for i in 0...target {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * stepDuration) {
                withAnimation(OrionAnimation.streakCounter) {
                    self.displayedStreak = i
                }
            }
        }
    }
}
// StudyStatsService.swift — Utilities
import Foundation
import SwiftData
import SwiftUI

@Observable
final class StudyStatsService {
    @ObservationIgnored @AppStorage(UserPreferencesKey.weeklyStudyGoalHours) private var weeklyGoalHours: Int = 15
    @ObservationIgnored @AppStorage(UserPreferencesKey.weeklyGoalStartDay) private var weeklyGoalStartDay: Int = 2

    // State populated by observing changes to study sessions
    var weeklyStudyMinutes: Int = 0

    var weeklyStudyGoalMinutes: Int {
        weeklyGoalHours * 60
    }

    var weeklyProgress: Double {
        guard weeklyStudyGoalMinutes > 0 else { return 0 }
        return min(Double(weeklyStudyMinutes) / Double(weeklyStudyGoalMinutes), 1.0)
    }

    var weeklyProgressLabel: String {
        let hrs = weeklyStudyMinutes / 60
        let mins = weeklyStudyMinutes % 60
        let goalHrs = weeklyGoalHours
        return mins > 0 ? "\(hrs)h \(mins)m / \(goalHrs)h" : "\(hrs)h / \(goalHrs)h"
    }

    var weeklyGoalMet: Bool {
        weeklyProgress >= 1.0
    }

    func calculateWeeklyStats(from sessions: [StudySession]) {
        // Find start of week using the AppStorage preferred start day
        var cal = Calendar.current
        cal.firstWeekday = weeklyGoalStartDay
        let startOfWeek = cal.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        
        let validSessions = sessions.filter { $0.date >= startOfWeek }
        weeklyStudyMinutes = validSessions.reduce(0) { $0 + $1.durationMinutes }
    }
}
