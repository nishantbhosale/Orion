// RestTimerManager.swift — Utilities
import Foundation
import Observation
import SwiftUI
import UserNotifications

@Observable
final class RestTimerManager {
    var timeRemaining: Int = 0
    var totalDuration: Int = 0
    var isActive: Bool = false
    var isFinished: Bool = false
    
    private var timer: Timer?
    private var backgroundDate: Date?
    
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return Double(timeRemaining) / Double(totalDuration)
    }
    
    func start(seconds: Int) {
        stop()
        self.totalDuration = seconds
        self.timeRemaining = seconds
        self.isActive = true
        self.isFinished = false
        
        scheduleNotification(after: seconds)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.complete()
            }
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isActive = false
        cancelNotifications()
    }
    
    private func complete() {
        stop()
        isFinished = true
        HapticManager.notification(.success)
        
        // Auto-dismiss after 5 seconds if not acknowledged
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if self.isFinished {
                self.isFinished = false
            }
        }
    }
    
    // Background handling
    func handleBackground() {
        backgroundDate = Date()
    }
    
    func handleForeground() {
        guard let bgDate = backgroundDate, isActive else { return }
        let elapsed = Int(Date().timeIntervalSince(bgDate))
        fastForward(seconds: elapsed)
        backgroundDate = nil
    }
    
    func fastForward(seconds: Int) {
        if timeRemaining > seconds {
            timeRemaining -= seconds
        } else {
            complete()
        }
    }
    
    // Notifications
    private func scheduleNotification(after seconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Rest Over"
        content.body = "Time for your next set!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: "rest_timer_over", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["rest_timer_over"])
    }
}
