// HistoryViewModel.swift — Features/History

import Foundation
import SwiftData
import Observation

enum HistoryFilter: String, CaseIterable {
    case all      = "All"
    case study    = "Study"
    case gym      = "Gym"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
}

struct HistorySection: Identifiable {
    let id = UUID()
    let title: String
    let items: [HistoryItem]
}

enum HistoryItem: Identifiable {
    case study(StudySession)
    case gym(GymSession)

    var id: UUID {
        switch self {
        case .study(let s): return s.id
        case .gym(let g):   return g.id
        }
    }

    var date: Date {
        switch self {
        case .study(let s): return s.date
        case .gym(let g):   return g.date
        }
    }

    var category: HabitCategory {
        switch self {
        case .study: return .study
        case .gym:   return .gym
        }
    }

    var title: String {
        switch self {
        case .study(let s): return s.moduleName
        case .gym(let g):   return g.workoutType.displayName
        }
    }

    var subtitle: String {
        switch self {
        case .study(let s): return s.topicDetail ?? s.subject
        case .gym(let g):   return g.exercisesSummary
        }
    }

    var duration: String {
        switch self {
        case .study(let s): return s.formattedDuration
        case .gym(let g):   return g.formattedDuration
        }
    }
}

@Observable
@MainActor
final class HistoryViewModel {
    private let studyRepository: StudyRepository
    private let gymRepository: GymRepository
    private let streakUseCase: StreakUseCase

    var selectedFilter: HistoryFilter = .all
    var sections: [HistorySection] = []
    var totalStudySessions: Int = 0
    var totalGymSessions: Int = 0
    var totalMinutesThisMonth: Int = 0

    init(studyRepository: StudyRepository, gymRepository: GymRepository, streakUseCase: StreakUseCase) {
        self.studyRepository = studyRepository
        self.gymRepository   = gymRepository
        self.streakUseCase   = streakUseCase
    }

    func loadData() async {
        do {
            let studySessions: [StudySession]
            let gymSessions: [GymSession]

            switch selectedFilter {
            case .all:
                studySessions = try studyRepository.fetchAll()
                gymSessions   = try gymRepository.fetchAll()
            case .study:
                studySessions = try studyRepository.fetchAll()
                gymSessions   = []
            case .gym:
                studySessions = []
                gymSessions   = try gymRepository.fetchAll()
            case .thisWeek:
                studySessions = try studyRepository.fetchThisWeek()
                gymSessions   = try gymRepository.fetchThisWeek()
            case .thisMonth:
                studySessions = try studyRepository.fetchThisMonth()
                gymSessions   = try gymRepository.fetchThisMonth()
            }

            // Monthly summary
            let monthStudy = try studyRepository.fetchThisMonth()
            let monthGym   = try gymRepository.fetchThisMonth()
            totalStudySessions   = monthStudy.count
            totalGymSessions     = monthGym.count
            totalMinutesThisMonth = monthStudy.reduce(0) { $0 + $1.durationMinutes }
                                  + monthGym.reduce(0) { $0 + $1.durationMinutes }

            // Build combined items
            let allItems: [HistoryItem] =
                studySessions.map { .study($0) } +
                gymSessions.map { .gym($0) }

            let sorted = allItems.sorted { $0.date > $1.date }
            sections = buildSections(from: sorted)
        } catch {}
    }

    func delete(item: HistoryItem) async {
        do {
            switch item {
            case .study(let session):
                try studyRepository.delete(session)
            case .gym(let session):
                try gymRepository.delete(session)
            }
            
            await loadData()
            
            let todayStudy = (try? studyRepository.fetchToday()) ?? []
            let todayGym = (try? gymRepository.fetchToday()) ?? []
            await streakUseCase.forceRecalculateToday(
                hasStudy: !todayStudy.isEmpty,
                hasGym: !todayGym.isEmpty
            )
        } catch {
            print("Error deleting history item: \(error)")
        }
    }

    private func buildSections(from items: [HistoryItem]) -> [HistorySection] {
        var grouped: [String: [HistoryItem]] = [:]
        var order: [String] = []

        for item in items {
            let key = DateHelper.relativeSection(for: item.date)
            if grouped[key] == nil {
                grouped[key] = []
                order.append(key)
            }
            grouped[key]?.append(item)
        }

        return order.compactMap { key in
            guard let items = grouped[key] else { return nil }
            return HistorySection(title: key, items: items)
        }
    }
}
