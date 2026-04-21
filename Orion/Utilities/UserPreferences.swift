// UserPreferences.swift — Utilities
// Centralized @AppStorage key constants — prevents typo bugs

import Foundation

enum UserPreferencesKey {
    static let userName            = "orion_user_name"
    static let hasOnboarded        = "orion_has_onboarded"
    static let dailyReminderHour   = "orion_reminder_hour"
    static let dailyReminderMinute = "orion_reminder_minute"
    static let studyGoalMinutes    = "orion_study_goal_minutes"
    static let gymGoalSessions     = "orion_gym_goal_sessions"
    static let notificationsEnabled = "orion_notifications_enabled"
    static let studySubjects        = "orion_study_subjects"
    
    // Weekly Study Goal Keys
    static let weeklyStudyGoalHours  = "weeklyStudyGoalHours"
    static let weeklyGoalStartDay    = "weeklyGoalStartDay"
    static let weeklyGoalCelebratedDate = "weeklyGoalCelebratedDate"
    
    // Pomodoro Keys
    static let pomodoroDurationMinutes      = "pomodoroDurationMinutes"
    static let pomodoroShortBreakMinutes    = "pomodoroShortBreakMinutes"
    static let pomodoroLongBreakMinutes     = "pomodoroLongBreakMinutes"
    static let todayPomodoroStars           = "todayPomodoroStars"
    static let todayPomodoroStarsDate       = "todayPomodoroStarsDate"
    
    // Gym / Body Weight Keys
    static let weightUnit                   = "weightUnit"
}

// MARK: — Default Values
extension UserPreferencesKey {
    static let defaultStudyGoalMinutes: Int = 120   // 2 hours/day
    static let defaultGymGoalSessions: Int  = 1     // 1 session/day
    static let defaultReminderHour: Int     = 20    // 8 PM
    static let defaultReminderMinute: Int   = 0
    static let defaultStudySubjects: [String] = ["Computer Science"]
}

// Support for [String] in @AppStorage
extension Array: @retroactive RawRepresentable where Element == String {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([String].self, from: data) else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return result
    }
}
