// StreakUseCase.swift — Core/UseCases

import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class StreakUseCase {
    private let habitRepository: HabitRepository

    private(set) var currentStreak: Int = 0
    private(set) var longestStreak: Int = 0
    private(set) var todayCompleted: Bool = false

    init(habitRepository: HabitRepository) {
        self.habitRepository = habitRepository
    }

    /// Called on app launch — validates streak continuity, resets if gap > 1 day
    func validateAndUpdateStreak() async {
        do {
            let streakData = try habitRepository.fetchStreakData()
            let todayLog = try habitRepository.fetchHabitLog(for: .now)

            todayCompleted = todayLog?.isCompleted ?? false

            guard let data = streakData else {
                // First launch — create initial streak data
                let newData = StreakData()
                try habitRepository.saveStreakData(newData)
                currentStreak = 0
                longestStreak = 0
                return
            }

            currentStreak = data.currentStreak
            longestStreak = data.longestStreak

            guard let lastLog = data.lastLogDate else { return }

            let calendar = Calendar.current
            let today = calendar.startOfDay(for: .now)
            let lastLogDay = calendar.startOfDay(for: lastLog)
            let daysDiff = calendar.dateComponents([.day], from: lastLogDay, to: today).day ?? 0

            // If gap > 1 day and today not completed, reset streak
            if daysDiff > 1 && !todayCompleted {
                data.currentStreak = 0
                currentStreak = 0
                try habitRepository.updateStreakData(data)
            }
        } catch {
            // Silently handle — streak state remains unchanged
        }
    }

    /// Called after a session is logged successfully
    func recordHabitCompletion(category: HabitCategory) async {
        do {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: .now)

            // Update HabitLog for today
            try habitRepository.upsertHabitLog(
                for: today,
                hasStudy: category == .study ? true : nil,
                hasGym: category == .gym ? true : nil
            )

            let streakData: StreakData
            if let existing = try habitRepository.fetchStreakData() {
                streakData = existing
            } else {
                streakData = StreakData()
                try habitRepository.saveStreakData(streakData)
            }

            let lastLogDay = streakData.lastLogDate.map { calendar.startOfDay(for: $0) }
            let daysDiff = lastLogDay.map {
                calendar.dateComponents([.day], from: $0, to: today).day ?? 0
            } ?? -1

            // Only increment streak if this is the first log today
            if daysDiff != 0 {
                if daysDiff == 1 {
                    // Consecutive day — increment
                    streakData.currentStreak += 1
                } else {
                    // Gap or first ever — start at 1
                    streakData.currentStreak = 1
                }

                if streakData.currentStreak > streakData.longestStreak {
                    streakData.longestStreak = streakData.currentStreak
                }
                streakData.lastLogDate = today
            }

            // Update monthly counters
            let thisMonth = calendar.dateInterval(of: .month, for: today)?.start ?? today
            if let monthStart = calendar.dateInterval(of: .month, for: today)?.start {
                let allLogs = try habitRepository.fetchHabitLogs(from: monthStart, to: today)
                streakData.studyDaysThisMonth = allLogs.filter { $0.hasStudy }.count
                streakData.gymDaysThisMonth   = allLogs.filter { $0.hasGym }.count
                _ = thisMonth // suppress unused warning
            }

            try habitRepository.updateStreakData(streakData)

            currentStreak = streakData.currentStreak
            longestStreak = streakData.longestStreak
            todayCompleted = true

            // Check milestones
            await checkMilestones(streak: streakData.currentStreak)
        } catch {
            // Silently handle
        }
    }

    /// Evaluates streak removal when sessions are deleted.
    func forceRecalculateToday(hasStudy: Bool?, hasGym: Bool?) async {
        do {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: .now)

            let todayLog = try habitRepository.fetchHabitLog(for: today)
            let updatedStudy = hasStudy ?? todayLog?.hasStudy ?? false
            let updatedGym = hasGym ?? todayLog?.hasGym ?? false

            if !updatedStudy && !updatedGym {
                // Today is no longer completed
                if let log = todayLog {
                    try habitRepository.deleteHabitLog(log)
                }

                if let data = try habitRepository.fetchStreakData() {
                    // Try to rollback streak by 1 if today was completed
                    if self.todayCompleted {
                        data.currentStreak = max(0, data.currentStreak - 1)
                        // Note: lastLogDate might become yesterday. For MVP, just deducting is enough
                        try habitRepository.updateStreakData(data)
                        self.currentStreak = data.currentStreak
                    }
                }
                self.todayCompleted = false
            } else {
                if let log = todayLog {
                    log.hasStudy = updatedStudy
                    log.hasGym = updatedGym
                }
            }
        } catch { }
    }

    private func checkMilestones(streak: Int) async {
        let milestones = [1, 7, 30, 100]
        if milestones.contains(streak) {
            await NotificationManager.shared.scheduleMilestoneNotification(streak: streak)
        }
    }
}
