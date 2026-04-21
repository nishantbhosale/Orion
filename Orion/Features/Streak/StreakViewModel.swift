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
    private let weightRepository: BodyMetricRepositoryProtocol
    private let gymRepository: GymRepository
    private(set) var gymStats = GymStatsService()

    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var studyDaysThisMonth: Int = 0
    var gymDaysThisMonth: Int = 0
    var habitLogs: [HabitLog] = []
    var calendarDays: [Date] = []

    // Weight Data
    var latestWeight: BodyMetricLog?
    var weightTrend: String = ""
    var last30Weights: [BodyMetricLog] = []
    var showWeightLogSheet: Bool = false
    var weightUnit: String = "kg"

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

    init(
        streakUseCase: StreakUseCase, 
        habitRepository: HabitRepository,
        weightRepository: BodyMetricRepositoryProtocol,
        gymRepository: GymRepository
    ) {
        self.streakUseCase    = streakUseCase
        self.habitRepository  = habitRepository
        self.weightRepository = weightRepository
        self.gymRepository    = gymRepository
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
            
            // Weight data
            latestWeight = try weightRepository.fetchLatest()
            last30Weights = try weightRepository.fetchThisMonth()
            calculateWeightTrend()
            
            // Volume data
            let weekSessions = try gymRepository.fetchThisWeek()
            gymStats.calculateWeeklyVolume(from: weekSessions)
        } catch {}

        calendarDays = DateHelper.daysInCurrentMonth()
        buildBadges()
    }

    private func calculateWeightTrend() {
        guard last30Weights.count >= 2,
              let first = last30Weights.first?.weightKg,
              let last = last30Weights.last?.weightKg else {
            weightTrend = "No trend data"
            return
        }
        
        let diff = last - first
        let emoji = diff > 0 ? "↑" : (diff < 0 ? "↓" : "→")
        weightTrend = "\(emoji) \(String(format: "%.1f", abs(diff)))kg this month"
    }

    func logWeight(_ weight: Double, notes: String?) async {
        do {
            try await weightRepository.logWeight(weight, notes: notes)
            await onAppear() // Refresh data
        } catch {}
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
