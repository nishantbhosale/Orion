// XPEvent.swift — Core/Models
import Foundation

/// All XP-earning event types.
/// NOTE: .badgeEarned carries no points — caller passes xpReward directly to XPService.award().
enum XPEvent: String, Codable, CaseIterable {
    // Study
    case studySessionLogged
    case pomodoroCompleted
    case focusScoreGiven
    case weeklyStudyGoalHit

    // Gym
    case gymSessionLogged
    case newPersonalRecord
    case overloadAchieved
    case restTimerUsed

    // Shared
    case dailyStreakMaintained
    case streak7Milestone
    case streak30Milestone
    case bodyWeightLogged

    // Meta (variable XP — see XPService.award overload)
    case badgeEarned
    case challengeCompleted

    /// Default XP award. See XPService.award(_:points:) for override.
    var points: Int {
        switch self {
        case .studySessionLogged:   return 15
        case .pomodoroCompleted:    return 10
        case .focusScoreGiven:      return 5
        case .weeklyStudyGoalHit:   return 50
        case .gymSessionLogged:     return 20
        case .newPersonalRecord:    return 30
        case .overloadAchieved:     return 15
        case .restTimerUsed:        return 5
        case .dailyStreakMaintained: return 10
        case .streak7Milestone:     return 75
        case .streak30Milestone:    return 200
        case .bodyWeightLogged:     return 5
        case .badgeEarned:          return 0   // Always overridden by caller
        case .challengeCompleted:   return 100
        }
    }

    var displayName: String {
        switch self {
        case .studySessionLogged:    return "Study Session"
        case .pomodoroCompleted:     return "Pomodoro Completed"
        case .focusScoreGiven:       return "Focus Score Rated"
        case .weeklyStudyGoalHit:    return "Weekly Study Goal"
        case .gymSessionLogged:      return "Gym Session"
        case .newPersonalRecord:     return "New Personal Record"
        case .overloadAchieved:      return "Progressive Overload"
        case .restTimerUsed:         return "Rest Timer Used"
        case .dailyStreakMaintained: return "Streak Maintained"
        case .streak7Milestone:      return "7-Day Streak"
        case .streak30Milestone:     return "30-Day Streak"
        case .bodyWeightLogged:      return "Body Weight Logged"
        case .badgeEarned:           return "Badge Earned"
        case .challengeCompleted:    return "Challenge Completed"
        }
    }
}
