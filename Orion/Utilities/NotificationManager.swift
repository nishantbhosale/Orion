// NotificationManager.swift — Utilities

import Foundation
import UserNotifications

@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        center.delegate = self
    }

    // MARK: — Permission

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: — Daily Reminder

    func scheduleDailyReminder(hour: Int, minute: Int) async {
        await center.removePendingNotificationRequests(withIdentifiers: ["orion_daily_reminder"])

        var components = DateComponents()
        components.hour   = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "🌌 Your stars await"
        content.body  = "Log today's habit and keep your streak alive."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "orion_daily_reminder",
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    func updateDailyReminder() async {
        // Re-schedule after logging to cancel streak danger alert if already done today
        await center.removePendingNotificationRequests(withIdentifiers: ["orion_streak_danger"])
    }

    // MARK: — Streak Danger Alert (9 PM)

    func scheduleStreakDangerAlert(currentStreak: Int) async {
        guard currentStreak > 0 else { return }

        var components = DateComponents()
        components.hour   = 21
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = "⚠️ Streak in danger!"
        content.body  = "Don't break your \(currentStreak)-day streak! Log a habit before midnight."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "orion_streak_danger",
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    // MARK: — Milestone Notifications

    func scheduleMilestoneNotification(streak: Int) async {
        let messages: [Int: (title: String, body: String)] = [
            1:   ("🌟 First Star earned!", "You've started your journey. The cosmos awaits."),
            7:   ("✨ Constellation unlocked!", "7 days strong — your first constellation is complete!"),
            30:  ("🌌 Nebula achieved!", "30 days of consistency. You're a force of nature."),
            100: ("🌠 Galaxy-tier streaker!", "100 days. You are Orion — the constellation in the sky.")
        ]

        guard let message = messages[streak] else { return }

        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body  = message.body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "orion_milestone_\(streak)",
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    // MARK: — UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
