// XPService.swift — Utilities

import Foundation
import SwiftUI
import SwiftData
import Observation

// MARK: — Notification names
extension Notification.Name {
    static let xpAwarded = Notification.Name("orion.xpAwarded")
    static let rankUp    = Notification.Name("orion.rankUp")
}

// MARK: — XPService
@Observable
@MainActor
final class XPService {
    private let repo: XPLogRepository

    var totalXP:  Int = 0
    var todayXP:  Int = 0
    var recentLogs: [XPLog] = []

    init(modelContext: ModelContext) {
        self.repo = XPLogRepository(modelContext: modelContext)
    }

    // MARK: — Award XP
    /// Award XP for an event. Pass `points` to override the event's default (use for .badgeEarned).
    func award(_ event: XPEvent, points: Int? = nil, sourceId: UUID? = nil) async {
        let xp = points ?? event.points
        guard xp > 0 else { return }

        let log = XPLog(event: event, points: xp, sourceId: sourceId)
        do {
            try repo.save(log)
        } catch { return }

        let prevTotal = totalXP
        await refreshTotals()

        // Broadcast for XPBurstOverlay
        NotificationCenter.default.post(
            name: .xpAwarded,
            object: nil,
            userInfo: ["points": xp, "displayName": event.displayName]
        )

        // Detect rank-up (done after totals refresh)
        detectRankUp(previousXP: prevTotal, currentXP: totalXP)
    }

    // MARK: — Refresh
    func refreshTotals() async {
        totalXP    = (try? repo.totalXP())    ?? 0
        todayXP    = (try? repo.todayXP())    ?? 0
        recentLogs = (try? repo.fetchLast30()) ?? []
    }

    // MARK: — Rank-up Detection
    private func detectRankUp(previousXP: Int, currentXP: Int) {
        let prevRank = OrionRank.rank(for: previousXP)
        let newRank  = OrionRank.rank(for: currentXP)
        guard newRank > prevRank else { return }
        NotificationCenter.default.post(
            name: .rankUp,
            object: nil,
            userInfo: ["newRank": newRank.rawValue, "rankName": newRank.displayName]
        )
    }

    // MARK: — Convenience
    var currentRank: OrionRank { OrionRank.rank(for: totalXP) }
}
