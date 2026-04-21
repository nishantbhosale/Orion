// SettingsViewModel.swift — Features/Settings

import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class SettingsViewModel {
    @ObservationIgnored @AppStorage(UserPreferencesKey.userName)
    var userName: String = ""

    @ObservationIgnored @AppStorage(UserPreferencesKey.studyGoalMinutes)
    var studyGoalMinutes: Int = UserPreferencesKey.defaultStudyGoalMinutes

    @ObservationIgnored @AppStorage(UserPreferencesKey.gymGoalSessions)
    var gymGoalSessions: Int = UserPreferencesKey.defaultGymGoalSessions

    @ObservationIgnored @AppStorage(UserPreferencesKey.dailyReminderHour)
    var reminderHour: Int = UserPreferencesKey.defaultReminderHour

    @ObservationIgnored @AppStorage(UserPreferencesKey.dailyReminderMinute)
    var reminderMinute: Int = UserPreferencesKey.defaultReminderMinute

    @ObservationIgnored @AppStorage(UserPreferencesKey.notificationsEnabled)
    var notificationsEnabled: Bool = true

    var reminderTime: Date {
        get {
            var components = DateComponents()
            components.hour   = reminderHour
            components.minute = reminderMinute
            return Calendar.current.date(from: components) ?? .now
        }
        set {
            reminderHour   = Calendar.current.component(.hour, from: newValue)
            reminderMinute = Calendar.current.component(.minute, from: newValue)
        }
    }

    func saveNotificationSettings() async {
        if notificationsEnabled {
            await NotificationManager.shared.scheduleDailyReminder(
                hour: reminderHour,
                minute: reminderMinute
            )
        }
    }
}
