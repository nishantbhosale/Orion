// StreakViewModel.swift — Features/Streak

import Foundation
import SwiftData
import Observation
import SwiftUI

@Observable
@MainActor
final class StreakViewModel {
    private let streakUseCase: StreakUseCase
    private let habitRepository: HabitRepository

    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var studyDaysThisMonth: Int = 0
    var gymDaysThisMonth: Int = 0
    var habitLogs: [HabitLog] = []
    var calendarDays: [Date] = []

    // Badges
    struct MilestoneBadge: Identifiable {
        let id = UUID()
        let days: Int
        let name: String
        let icon: String
        let description: String
        var isEarned: Bool
    }

    var badges: [MilestoneBadge] = []

    init(streakUseCase: StreakUseCase, habitRepository: HabitRepository) {
        self.streakUseCase   = streakUseCase
        self.habitRepository = habitRepository
    }

    func onAppear() async {
        currentStreak         = streakUseCase.currentStreak
        longestStreak         = streakUseCase.longestStreak

        do {
            if let streakData = try habitRepository.fetchStreakData() {
                studyDaysThisMonth = streakData.studyDaysThisMonth
                gymDaysThisMonth   = streakData.gymDaysThisMonth
            }
            habitLogs = try habitRepository.fetchAllHabitLogs()
        } catch {}

        calendarDays = DateHelper.daysInCurrentMonth()
        buildBadges()
    }

    func habitLogFor(date: Date) -> HabitLog? {
        habitLogs.first { DateHelper.isSameDay($0.date, date) }
    }

    func calendarCellColor(for date: Date) -> Color {
        guard let log = habitLogFor(date: date) else { return .clear }
        if log.hasStudy && log.hasGym { return .streakGold }
        if log.hasGym   { return .novaOrange }
        if log.hasStudy { return .auroraTeal }
        return .clear
    }

    private func buildBadges() {
        let longestEarned = longestStreak
        badges = [
            MilestoneBadge(days: 1,   name: "First Star",    icon: "star.fill",        description: "1-day streak",  isEarned: longestEarned >= 1),
            MilestoneBadge(days: 7,   name: "Constellation", icon: "sparkles",          description: "7-day streak",  isEarned: longestEarned >= 7),
            MilestoneBadge(days: 30,  name: "Nebula",         icon: "cloud.fill",        description: "30-day streak", isEarned: longestEarned >= 30),
            MilestoneBadge(days: 100, name: "Galaxy",         icon: "globe.americas.fill", description: "100-day streak", isEarned: longestEarned >= 100)
        ]
    }
}
