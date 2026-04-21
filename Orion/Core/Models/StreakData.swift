// StreakData.swift — Core/Models

import Foundation
import SwiftData

@Model
final class StreakData {
    var currentStreak: Int
    var longestStreak: Int
    var lastLogDate: Date?
    var studyDaysThisMonth: Int
    var gymDaysThisMonth: Int

    init(
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastLogDate: Date? = nil,
        studyDaysThisMonth: Int = 0,
        gymDaysThisMonth: Int = 0
    ) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastLogDate = lastLogDate
        self.studyDaysThisMonth = studyDaysThisMonth
        self.gymDaysThisMonth = gymDaysThisMonth
    }
}
