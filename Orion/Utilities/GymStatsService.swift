// GymStatsService.swift — Utilities
import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
final class GymStatsService {
    
    // MARK: — Volume per Muscle Group
    struct MuscleVolume: Identifiable {
        let id = UUID()
        let group: MuscleGroup
        let totalSets: Int
        var barFraction: Double = 0   // relative to the max group
    }
    
    var weeklyMuscleVolume: [MuscleVolume] = []
    var imbalanceWarnings: [String] = []
    
    func calculateWeeklyVolume(from sessions: [GymSession]) {
        // Aggregate sets by muscle group for the current week
        var counts: [MuscleGroup: Int] = [:]
        
        for session in sessions {
            for exercise in session.exercises {
                guard let group = exercise.muscleGroup else { continue }
                counts[group, default: 0] += exercise.sets
            }
        }
        
        guard !counts.isEmpty else {
            weeklyMuscleVolume = []
            imbalanceWarnings = []
            return
        }
        
        let maxSets = counts.values.max() ?? 1
        weeklyMuscleVolume = counts.map { group, sets in
            MuscleVolume(group: group, totalSets: sets, barFraction: Double(sets) / Double(maxSets))
        }.sorted { $0.totalSets > $1.totalSets }
        
        detectImbalances(counts)
    }
    
    private func detectImbalances(_ counts: [MuscleGroup: Int]) {
        var warnings: [String] = []
        
        // Push/Pull balance
        let pushSets = counts[.chest, default: 0] + counts[.shoulders, default: 0]
        let pullSets  = counts[.back, default: 0]
        if pushSets > 0 && pullSets > 0 {
            let ratio = Double(pushSets) / Double(pullSets)
            if ratio > 2.0 {
                warnings.append("⚠️ Push:Pull ratio is \(String(format: "%.1f", ratio)):1 — add more back work")
            }
        }
        
        // Leg neglect
        let legSets = counts[.legs, default: 0]
        let upperSets = (counts[.chest] ?? 0) + (counts[.back] ?? 0) + (counts[.shoulders] ?? 0) + (counts[.arms] ?? 0)
        if upperSets > 0 && legSets == 0 {
            warnings.append("⚠️ No leg work logged this week — skipping leg day?")
        }
        
        // Core neglect
        if counts[.core] == nil {
            warnings.append("ℹ️ No core training logged this week")
        }
        
        imbalanceWarnings = warnings
    }
}
