// GymRepository.swift — Core/Repositories

import Foundation
import SwiftData

@MainActor
final class GymRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [GymSession] {
        let descriptor = FetchDescriptor<GymSession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchToday() throws -> [GymSession] {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? .now
        let descriptor = FetchDescriptor<GymSession>(
            predicate: #Predicate<GymSession> { session in
                session.date >= startOfDay && session.date < endOfDay
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchThisWeek() throws -> [GymSession] {
        guard let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start else {
            return []
        }
        let descriptor = FetchDescriptor<GymSession>(
            predicate: #Predicate<GymSession> { session in
                session.date >= weekStart
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchThisMonth() throws -> [GymSession] {
        guard let monthStart = Calendar.current.dateInterval(of: .month, for: .now)?.start else {
            return []
        }
        let descriptor = FetchDescriptor<GymSession>(
            predicate: #Predicate<GymSession> { session in
                session.date >= monthStart
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func save(_ session: GymSession) throws {
        modelContext.insert(session)
        try modelContext.save()
    }

    func delete(_ session: GymSession) throws {
        modelContext.delete(session)
        try modelContext.save()
    }

    func fetchLastSession(containing exerciseName: String, before date: Date) throws -> GymSession? {
        let descriptor = FetchDescriptor<GymSession>(
            predicate: #Predicate<GymSession> { $0.date < date },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let sessions = try modelContext.fetch(descriptor)
        let target = exerciseName.lowercased().trimmingCharacters(in: .whitespaces)
        
        return sessions.first { session in
            session.exercises.contains { 
                $0.name.lowercased().trimmingCharacters(in: .whitespaces) == target 
            }
        }
    }
}
