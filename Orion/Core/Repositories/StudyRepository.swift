// StudyRepository.swift — Core/Repositories

import Foundation
import SwiftData

@MainActor
final class StudyRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [StudySession] {
        let descriptor = FetchDescriptor<StudySession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchToday() throws -> [StudySession] {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? .now
        let descriptor = FetchDescriptor<StudySession>(
            predicate: #Predicate<StudySession> { session in
                session.date >= startOfDay && session.date < endOfDay
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchThisWeek() throws -> [StudySession] {
        guard let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start else {
            return []
        }
        let descriptor = FetchDescriptor<StudySession>(
            predicate: #Predicate<StudySession> { session in
                session.date >= weekStart
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchThisMonth() throws -> [StudySession] {
        guard let monthStart = Calendar.current.dateInterval(of: .month, for: .now)?.start else {
            return []
        }
        let descriptor = FetchDescriptor<StudySession>(
            predicate: #Predicate<StudySession> { session in
                session.date >= monthStart
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func save(_ session: StudySession) throws {
        modelContext.insert(session)
        try modelContext.save()
    }

    func delete(_ session: StudySession) throws {
        modelContext.delete(session)
        try modelContext.save()
    }

    /// Total study minutes today
    func totalMinutesToday() throws -> Int {
        let sessions = try fetchToday()
        return sessions.reduce(0) { $0 + $1.durationMinutes }
    }
}
