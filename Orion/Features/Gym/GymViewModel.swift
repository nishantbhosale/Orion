// GymViewModel.swift — Features/Gym

import Foundation
import SwiftData
import Observation
import SwiftUI

@Observable
@MainActor
final class GymViewModel {
    private let gymRepository: GymRepository
    private let logUseCase: LogGymSessionUseCase
    private let streakUseCase: StreakUseCase
    private let templateRepository: WorkoutTemplateRepository
    private let prRepository: PRLogRepository

    // Form state
    var selectedWorkoutType: GymWorkoutType = .push
    var exercises: [ExerciseEntry] = []
    var notes: String = ""

    // Duration
    var hours: Int = 1
    var minutes: Int = 0
    var useTimer: Bool = false
    var timerSeconds: Int = 0
    var timerRunning: Bool = false

    // Exercise sheet
    var showExerciseSheet: Bool = false
    var newExerciseName: String = ""
    var newExerciseSets: Int = 3
    var newExerciseReps: Int = 10
    var newExerciseWeightKg: Double = 0
    var newExerciseDurationSeconds: Int = 0
    var newExerciseIsTimed: Bool = false
    var newExerciseMuscleGroup: MuscleGroup = .fullBody
    var newExerciseRestSeconds: Int = 90

    // UI state
    var isLogging: Bool = false
    var showToast: Bool = false
    var toastMessage: String = ""
    var errorMessage: String? = nil

    // Template
    var showTemplateSheet: Bool = false
    var availableTemplates: [WorkoutTemplate] = []
    var showSaveTemplateAlert: Bool = false
    var newTemplateName: String = ""

    private var timerTask: Task<Void, Never>?

    init(gymRepository: GymRepository, streakUseCase: StreakUseCase, templateRepository: WorkoutTemplateRepository, prRepository: PRLogRepository, xpService: XPService? = nil) {
        self.gymRepository      = gymRepository
        self.streakUseCase      = streakUseCase
        self.templateRepository = templateRepository
        self.prRepository       = prRepository
        self.logUseCase = LogGymSessionUseCase(
            gymRepository: gymRepository,
            streakUseCase: streakUseCase,
            xpService: xpService
        )
        self.availableTemplates = (try? templateRepository.fetchAll()) ?? []
    }

    // MARK: — Timer
    func startTimer() {
        timerRunning = true
        timerSeconds = 0
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !Task.isCancelled { timerSeconds += 1 }
            }
        }
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
        timerRunning = false
        hours   = timerSeconds / 3600
        minutes = (timerSeconds % 3600) / 60
        if minutes == 0 && hours == 0 { hours = 1 }
    }

    func onDisappear() {
        timerTask?.cancel()
        timerTask = nil
        timerRunning = false
    }

    var totalMinutes: Int {
        useTimer ? max(timerSeconds / 60, 1) : (hours * 60 + minutes)
    }

    var timerDisplay: String {
        DateHelper.formatSeconds(timerSeconds)
    }

    // MARK: — Exercise Management
    func addExercise() {
        guard !newExerciseName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let entry = ExerciseEntry(
            name: newExerciseName.trimmingCharacters(in: .whitespaces),
            sets: newExerciseSets,
            reps: newExerciseIsTimed ? nil : newExerciseReps,
            weightKg: newExerciseWeightKg > 0 ? newExerciseWeightKg : nil,
            durationSeconds: newExerciseIsTimed ? newExerciseDurationSeconds : nil,
            muscleGroup: newExerciseMuscleGroup,
            restSeconds: newExerciseRestSeconds
        )
        exercises.append(entry)
        resetExerciseForm()
        showExerciseSheet = false
    }

    func removeExercise(_ entry: ExerciseEntry) {
        exercises.removeAll { $0.id == entry.id }
    }

    private func resetExerciseForm() {
        newExerciseName = ""
        newExerciseSets = 3
        newExerciseReps = 10
        newExerciseWeightKg = 0
        newExerciseDurationSeconds = 0
        newExerciseIsTimed = false
        newExerciseMuscleGroup = .fullBody
        newExerciseRestSeconds = 90
    }

    // MARK: — Log Session
    func logSession() async {
        guard !isLogging else { return }
        isLogging = true
        errorMessage = nil

        do {
            // Detect overload before calling the use case
            let hasOverload = exercises.contains {
                if case .improved = overloadDelta(for: $0) { return true }
                return false
            }

            // Detect PRs before save (so we can pass the count)
            var newPRNames: [String] = []
            for entry in exercises {
                guard let weight = entry.weightKg, let reps = entry.reps, weight > 0, reps > 0 else { continue }
                if let _ = try? prRepository.saveIfPR(exerciseName: entry.name, weightKg: weight, reps: reps) {
                    newPRNames.append(entry.name)
                }
            }

            try await logUseCase.execute(
                workoutType: selectedWorkoutType,
                exercises: exercises,
                durationMinutes: totalMinutes,
                notes: notes.isEmpty ? nil : notes,
                hasOverload: hasOverload,
                newPRCount: newPRNames.count
            )
            HapticManager.notification(.success)

            if newPRNames.isEmpty {
                toastMessage = "Workout logged! 💪"
            } else {
                toastMessage = "🏆 New PR\(newPRNames.count > 1 ? "s" : ""): \(newPRNames.joined(separator: ", "))"
                HapticManager.notification(.success)
            }
            showToast = true
            resetForm()
            await streakUseCase.validateAndUpdateStreak()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.notification(.error)
        }
        isLogging = false
    }

    func deleteSession(_ session: GymSession) {
        do {
            try gymRepository.delete(session)
            Task {
                let todaySessions = (try? gymRepository.fetchToday()) ?? []
                let hasGym = !todaySessions.isEmpty
                await streakUseCase.forceRecalculateToday(hasStudy: nil, hasGym: hasGym)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resetForm() {
        exercises    = []
        notes        = ""
        hours        = 1
        minutes      = 0
        timerSeconds = 0
    }

    // MARK: — Templates
    func loadTemplate(_ template: WorkoutTemplate) {
        exercises = template.exercises.map { $0.toExerciseEntry() }
        selectedWorkoutType = template.workoutType
        notes = template.notes ?? ""
        try? templateRepository.markUsed(template)
        showTemplateSheet = false
    }

    func saveCurrentAsTemplate() {
        guard !exercises.isEmpty, !newTemplateName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let templateExercises = exercises.map { entry in
            TemplateExercise(
                name: entry.name, sets: entry.sets, reps: entry.reps,
                weightKg: entry.weightKg, muscleGroup: entry.muscleGroup, restSeconds: entry.restSeconds
            )
        }
        let template = WorkoutTemplate(
            name: newTemplateName.trimmingCharacters(in: .whitespaces),
            workoutType: selectedWorkoutType,
            exercises: templateExercises,
            notes: notes.isEmpty ? nil : notes
        )
        do {
            try templateRepository.save(template)
            availableTemplates = (try? templateRepository.fetchAll()) ?? []
            newTemplateName = ""
            toastMessage = "Template saved ⭐"
            withAnimation { showToast = true }
        } catch { errorMessage = error.localizedDescription }
    }

    func deleteTemplate(_ template: WorkoutTemplate) {
        try? templateRepository.delete(template)
        availableTemplates = (try? templateRepository.fetchAll()) ?? []
    }

    // MARK: — Progressive Overload Logic
    func overloadDelta(for entry: ExerciseEntry, sessionDate: Date = .now) -> OverloadDelta {
        do {
            guard let last = try gymRepository.fetchLastSession(
                containing: entry.name, before: sessionDate
            ) else { return .noHistory }
            
            guard let lastEntry = last.exercises.first(where: {
                $0.name.lowercased().trimmingCharacters(in: .whitespaces) == entry.name.lowercased().trimmingCharacters(in: .whitespaces)
            }) else { return .noHistory }
            
            let weightDiff = (entry.weightKg ?? 0) - (lastEntry.weightKg ?? 0)
            let repsDiff   = (entry.reps ?? 0)     - (lastEntry.reps ?? 0)
            
            if weightDiff > 0 || (weightDiff == 0 && repsDiff > 0) { return .improved(label: weightDiff > 0 ? "+\(String(format: "%.1f", weightDiff))kg" : "+\(repsDiff) reps") }
            if weightDiff < 0 || (weightDiff == 0 && repsDiff < 0) { return .declined }
            return .same
        } catch {
            return .noHistory
        }
    }

    // MARK: — Muscle Group Suggestion
    static let exerciseMuscleMap: [String: MuscleGroup] = [
        "bench press": .chest, "incline bench": .chest, "chest fly": .chest,
        "pull up": .back, "lat pulldown": .back, "row": .back, "deadlift": .back,
        "overhead press": .shoulders, "lateral raise": .shoulders,
        "squat": .legs, "leg press": .legs, "romanian deadlift": .legs, "lunge": .legs,
        "bicep curl": .arms, "tricep": .arms, "skull crusher": .arms,
        "plank": .core, "crunch": .core, "leg raise": .core,
        "running": .cardio, "cycling": .cardio, "jump rope": .cardio,
    ]

    func suggestMuscleGroup(for exerciseName: String) -> MuscleGroup? {
        let lower = exerciseName.lowercased()
        return Self.exerciseMuscleMap.first(where: { lower.contains($0.key) })?.value
    }

    // Smart suggestions for current workout type
    var exerciseSuggestions: [String] {
        selectedWorkoutType.exerciseSuggestions
    }

    // MARK: — 1RM Helpers
    func live1RM(for entry: ExerciseEntry) -> Double? {
        guard let weight = entry.weightKg, let reps = entry.reps,
              weight > 0, reps > 0 else { return nil }
        return PRLog.epley(weightKg: weight, reps: reps)
    }

    func bestPR(for exerciseName: String) -> PRLog? {
        try? prRepository.fetchBest(for: exerciseName)
    }

    /// Returns "+X.Xkg" or nil if current 1RM doesn't beat historical best.
    func prGainLabel(for entry: ExerciseEntry) -> String? {
        guard let current = live1RM(for: entry),
              let best = bestPR(for: entry.name) else { return nil }
        let gain = current - best.estimated1RMkg
        guard gain > 0 else { return nil }
        return "+\(String(format: "%.1f", gain))kg 1RM"
    }
}

enum OverloadDelta {
    case improved(label: String)
    case same
    case declined
    case noHistory
    
    var icon: String {
        switch self {
        case .improved: return "arrow.up"
        case .same:     return "arrow.right"
        case .declined: return "arrow.down"
        case .noHistory: return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .improved: return Color.streakGold
        case .same:     return Color.moonGray
        case .declined: return Color.novaOrange.opacity(0.7)
        case .noHistory: return Color.dustGray
        }
    }
}
