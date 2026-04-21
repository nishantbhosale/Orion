// HabitRepository.swift — Core/Repositories

import Foundation
import SwiftData

@MainActor
final class HabitRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: — StreakData

    func fetchStreakData() throws -> StreakData? {
        let descriptor = FetchDescriptor<StreakData>()
        return try modelContext.fetch(descriptor).first
    }

    func saveStreakData(_ data: StreakData) throws {
        modelContext.insert(data)
        try modelContext.save()
    }

    func updateStreakData(_ data: StreakData) throws {
        try modelContext.save()
    }

    // MARK: — HabitLog

    func fetchHabitLog(for date: Date) throws -> HabitLog? {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        let descriptor = FetchDescriptor<HabitLog>(
            predicate: #Predicate<HabitLog> { log in
                log.date >= startOfDay && log.date < endOfDay
            }
        )
        return try modelContext.fetch(descriptor).first
    }

    func fetchAllHabitLogs() throws -> [HabitLog] {
        let descriptor = FetchDescriptor<HabitLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchHabitLogs(from startDate: Date, to endDate: Date) throws -> [HabitLog] {
        let descriptor = FetchDescriptor<HabitLog>(
            predicate: #Predicate<HabitLog> { log in
                log.date >= startDate && log.date <= endDate
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func upsertHabitLog(for date: Date, hasStudy: Bool? = nil, hasGym: Bool? = nil) throws {
        let startOfDay = Calendar.current.startOfDay(for: date)

        if let existing = try fetchHabitLog(for: date) {
            if let hasStudy { existing.hasStudy = existing.hasStudy || hasStudy }
            if let hasGym   { existing.hasGym = existing.hasGym || hasGym }
        } else {
            let log = HabitLog(
                date: startOfDay,
                hasStudy: hasStudy ?? false,
                hasGym: hasGym ?? false
            )
            modelContext.insert(log)
        }
        try modelContext.save()
    }

    func deleteHabitLog(_ log: HabitLog) throws {
        modelContext.delete(log)
        try modelContext.save()
    }
}
