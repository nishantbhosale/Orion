// BodyMetricLog.swift — Core/Models
import Foundation
import SwiftData

@Model
final class BodyMetricLog: Identifiable {
    var id: UUID
    var date: Date            // Normalised to start of day via DateHelper.startOfDay()
    var weightKg: Double      // Always stored in kg
    var notes: String?
    var createdAt: Date
    var bodyFatPercent: Double?  // Optional for future use

    init(
        id: UUID = UUID(),
        date: Date = .now,
        weightKg: Double,
        notes: String? = nil,
        createdAt: Date = .now,
        bodyFatPercent: Double? = nil
    ) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.notes = notes
        self.createdAt = createdAt
        self.bodyFatPercent = bodyFatPercent
    }
}
