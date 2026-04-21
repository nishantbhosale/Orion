// StudySession.swift — Core/Models

import Foundation
import SwiftData

@Model
final class StudySession {
    var id: UUID
    var date: Date
    var moduleName: String
    var topicDetail: String?
    var subject: String
    var durationMinutes: Int
    var focusScore: Int?
    var notes: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date = .now,
        moduleName: String,
        topicDetail: String? = nil,
        subject: String = "Computer Science",
        durationMinutes: Int,
        focusScore: Int? = nil,
        notes: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.moduleName = moduleName
        self.topicDetail = topicDetail
        self.subject = subject
        self.durationMinutes = durationMinutes
        self.focusScore = focusScore
        self.notes = notes
        self.createdAt = createdAt
    }

    /// Formatted duration string e.g. "1h 30m"
    var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}
