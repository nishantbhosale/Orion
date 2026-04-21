// GymViewModel.swift — Features/Gym

import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class GymViewModel {
    private let gymRepository: GymRepository
    private let logUseCase: LogGymSessionUseCase
    private let streakUseCase: StreakUseCase

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

    // UI state
    var isLogging: Bool = false
    var showToast: Bool = false
    var toastMessage: String = ""
    var errorMessage: String? = nil

    private var timerTask: Task<Void, Never>?

    init(gymRepository: GymRepository, streakUseCase: StreakUseCase) {
        self.gymRepository = gymRepository
        self.streakUseCase = streakUseCase
        self.logUseCase = LogGymSessionUseCase(
            gymRepository: gymRepository,
            streakUseCase: streakUseCase
        )
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
            durationSeconds: newExerciseIsTimed ? newExerciseDurationSeconds : nil
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
    }

    // MARK: — Log Session
    func logSession() async {
        guard !isLogging else { return }
        isLogging = true
        errorMessage = nil

        do {
            try await logUseCase.execute(
                workoutType: selectedWorkoutType,
                exercises: exercises,
                durationMinutes: totalMinutes,
                notes: notes.isEmpty ? nil : notes
            )
            HapticManager.notification(.success)
            toastMessage = "Workout logged! 💪"
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
        exercises = []
        notes = ""
        hours = 1
        minutes = 0
        timerSeconds = 0
    }

    // Smart suggestions for current workout type
    var exerciseSuggestions: [String] {
        selectedWorkoutType.exerciseSuggestions
    }
}
