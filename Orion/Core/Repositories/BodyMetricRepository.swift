// BodyMetricRepository.swift — Core/Repositories
import Foundation
import SwiftData

@MainActor
protocol BodyMetricRepositoryProtocol {
    func fetchAll() throws -> [BodyMetricLog]
    func fetchLatest() throws -> BodyMetricLog?
    func fetchThisMonth() throws -> [BodyMetricLog]
    func todayLog() throws -> BodyMetricLog?
    func logWeight(_ weight: Double, notes: String?) async throws
}

@MainActor
final class BodyMetricRepository: BodyMetricRepositoryProtocol {
    private let modelContext: ModelContext
    weak var xpService: XPService?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [BodyMetricLog] {
        let descriptor = FetchDescriptor<BodyMetricLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }

    func fetchLatest() throws -> BodyMetricLog? {
        let descriptor = FetchDescriptor<BodyMetricLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return try modelContext.fetch(descriptor).first
    }

    func fetchThisMonth() throws -> [BodyMetricLog] {
        let startOfMonth = DateHelper.startOfMonth(for: Date.now)
        let descriptor = FetchDescriptor<BodyMetricLog>(
            predicate: #Predicate<BodyMetricLog> { $0.date >= startOfMonth },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    func todayLog() throws -> BodyMetricLog? {
        let today = DateHelper.startOfDay(.now)
        let descriptor = FetchDescriptor<BodyMetricLog>(
            predicate: #Predicate<BodyMetricLog> { $0.date == today }
        )
        return try modelContext.fetch(descriptor).first
    }

    func logWeight(_ weight: Double, notes: String?) async throws {
        let today = DateHelper.startOfDay(.now)
        let isNew = (try? todayLog()) == nil

        if let existing = try todayLog() {
            existing.weightKg = weight
            existing.notes = notes
        } else {
            let newLog = BodyMetricLog(date: today, weightKg: weight, notes: notes)
            modelContext.insert(newLog)
        }

        try modelContext.save()

        // Award XP only for first log of the day (not updates)
        if isNew { await xpService?.award(.bodyWeightLogged) }
    }
}
