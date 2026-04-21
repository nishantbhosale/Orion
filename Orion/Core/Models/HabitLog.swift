// HabitLog.swift — Core/Models

import Foundation
import SwiftData

@Model
final class HabitLog {
    var id: UUID
    var date: Date          // start of day (normalized)
    var hasStudy: Bool
    var hasGym: Bool

    init(
        id: UUID = UUID(),
        date: Date,
        hasStudy: Bool = false,
        hasGym: Bool = false
    ) {
        self.id = id
        self.date = date
        self.hasStudy = hasStudy
        self.hasGym = hasGym
    }

    /// True if at least one habit was completed (for streak counting)
    var isCompleted: Bool {
        hasStudy || hasGym
    }
}
