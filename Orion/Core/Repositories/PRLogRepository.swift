// PRLogRepository.swift — Core/Repositories
import Foundation
import SwiftData

@MainActor
final class PRLogRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [PRLog] {
        let descriptor = FetchDescriptor<PRLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchBest(for exerciseName: String) throws -> PRLog? {
        let name = exerciseName.lowercased().trimmingCharacters(in: .whitespaces)
        let descriptor = FetchDescriptor<PRLog>(
            sortBy: [SortDescriptor(\.estimated1RMkg, order: .reverse)]
        )
        let all = try modelContext.fetch(descriptor)
        return all.first { $0.exerciseName.lowercased().trimmingCharacters(in: .whitespaces) == name }
    }

    func fetchHistory(for exerciseName: String) throws -> [PRLog] {
        let name = exerciseName.lowercased().trimmingCharacters(in: .whitespaces)
        let descriptor = FetchDescriptor<PRLog>(
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        let all = try modelContext.fetch(descriptor)
        return all.filter { $0.exerciseName.lowercased().trimmingCharacters(in: .whitespaces) == name }
    }

    /// Saves a PR only if it beats the current best for that exercise.
    @discardableResult
    func saveIfPR(exerciseName: String, weightKg: Double, reps: Int) throws -> PRLog? {
        let estimate = PRLog.epley(weightKg: weightKg, reps: reps)
        guard estimate > 0 else { return nil }

        let currentBest = try fetchBest(for: exerciseName)?.estimated1RMkg ?? 0
        guard estimate > currentBest else { return nil }

        let pr = PRLog(
            exerciseName: exerciseName,
            estimated1RMkg: estimate,
            performedWeightKg: weightKg,
            performedReps: reps
        )
        modelContext.insert(pr)
        try modelContext.save()
        return pr
    }
}
