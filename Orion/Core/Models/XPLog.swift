// XPLog.swift — Core/Models
import Foundation
import SwiftData

@Model
final class XPLog {
    var id: UUID
    var eventRawValue: String   // XPEvent.rawValue
    var points: Int
    var date: Date              // Normalised to startOfDay for daily totals
    var sourceId: UUID?         // e.g. session.id for de-dup if needed
    var createdAt: Date

    init(
        id: UUID = UUID(),
        event: XPEvent,
        points: Int,            // Explicit — not derived from event.points (badge override)
        date: Date = DateHelper.startOfDay(.now),
        sourceId: UUID? = nil,
        createdAt: Date = .now
    ) {
        self.id             = id
        self.eventRawValue  = event.rawValue
        self.points         = points
        self.date           = date
        self.sourceId       = sourceId
        self.createdAt      = createdAt
    }

    var event: XPEvent? {
        XPEvent(rawValue: eventRawValue)
    }

    var displayName: String {
        event?.displayName ?? eventRawValue
    }
}
