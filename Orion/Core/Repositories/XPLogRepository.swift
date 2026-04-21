// XPLogRepository.swift — Core/Repositories
import Foundation
import SwiftData

@MainActor
final class XPLogRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [XPLog] {
        let descriptor = FetchDescriptor<XPLog>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchToday() throws -> [XPLog] {
        let start = DateHelper.startOfDay(.now)
        let descriptor = FetchDescriptor<XPLog>(
            predicate: #Predicate<XPLog> { $0.date >= start },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchLast30() throws -> [XPLog] {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) else {
            return []
        }
        let descriptor = FetchDescriptor<XPLog>(
            predicate: #Predicate<XPLog> { $0.createdAt >= cutoff },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func totalXP() throws -> Int {
        let all = try fetchAll()
        return all.reduce(0) { $0 + $1.points }
    }

    func todayXP() throws -> Int {
        let today = try fetchToday()
        return today.reduce(0) { $0 + $1.points }
    }

    func save(_ log: XPLog) throws {
        modelContext.insert(log)
        try modelContext.save()
    }
}
