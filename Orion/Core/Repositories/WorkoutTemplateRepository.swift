// WorkoutTemplateRepository.swift — Core/Repositories
import Foundation
import SwiftData

@MainActor
final class WorkoutTemplateRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [WorkoutTemplate] {
        let descriptor = FetchDescriptor<WorkoutTemplate>(
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func save(_ template: WorkoutTemplate) throws {
        modelContext.insert(template)
        try modelContext.save()
    }

    func delete(_ template: WorkoutTemplate) throws {
        modelContext.delete(template)
        try modelContext.save()
    }

    func markUsed(_ template: WorkoutTemplate) throws {
        template.lastUsedAt = .now
        template.useCount += 1
        try modelContext.save()
    }
}
