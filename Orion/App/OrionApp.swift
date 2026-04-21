// OrionApp.swift — App entry point

import SwiftUI
import SwiftData

@main
struct OrionApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @AppStorage(UserPreferencesKey.hasOnboarded) private var hasOnboarded: Bool = false
    @State private var studyStatsService = StudyStatsService()
    @State private var pomodoroManager = PomodoroManager()
    @State private var restTimerManager = RestTimerManager()
    @State private var xpService: XPService
    @Environment(\.scenePhase) private var scenePhase

    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            StudySession.self,
            GymSession.self,
            HabitLog.self,
            StreakData.self,
            BodyMetricLog.self,
            WorkoutTemplate.self,
            PRLog.self,
            XPLog.self
        ])

        // Try the normal versioned container first.
        // If the store is incompatible (e.g. old enum-based schema), destroy it
        // and recreate a clean one rather than crashing.
        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(isStoredInMemoryOnly: false)]
            )
        } catch {
            print("⚠️ Orion: existing store unreadable (\(error.localizedDescription)). Recreating.")
            do {
                // Destroy the bad store file and start fresh
                let storeURL = URL.applicationSupportDirectory
                    .appending(path: "default.store")
                let walURL  = storeURL.deletingLastPathComponent()
                    .appending(path: "default.store-wal")
                let shmURL  = storeURL.deletingLastPathComponent()
                    .appending(path: "default.store-shm")
                for url in [storeURL, walURL, shmURL] {
                    try? FileManager.default.removeItem(at: url)
                }
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [ModelConfiguration(isStoredInMemoryOnly: false)]
                )
            } catch {
                fatalError("Failed to create ModelContainer even after store reset: \(error)")
            }
        }
        _xpService = State(initialValue: XPService(modelContext: modelContainer.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded {
                    OrionRootView()
                } else {
                    OnboardingView()
                }
            }
            .modelContainer(modelContainer)
            .environment(studyStatsService)
            .environment(pomodoroManager)
            .environment(restTimerManager)
            .environment(xpService)
            .preferredColorScheme(.dark)
            .onChange(of: scenePhase) { _, newPhase in
                pomodoroManager.handleScenePhaseChange(newPhase)
                if newPhase == .background {
                    restTimerManager.handleBackground()
                } else if newPhase == .active {
                    restTimerManager.handleForeground()
                    Task { await xpService.refreshTotals() }
                }
            }
            .task {
                // Wire xpService into pomodoroManager (can't be done in init due to @State isolation)
                pomodoroManager.xpService = xpService

                // Validate streak on every launch (async, not blocking main thread)
                let context = ModelContext(modelContainer)
                let habitRepo = HabitRepository(modelContext: context)
                let streakUC  = StreakUseCase(habitRepository: habitRepo)
                await streakUC.validateAndUpdateStreak()

                // Seed initial XP totals
                await xpService.refreshTotals()

                // Request notification permission
                NotificationManager.shared.requestPermission()
            }
        }
    }
}

// MARK: — Root View (extracted to Features/App/OrionRootView.swift)
// OrionRootView is now defined in Features/App/OrionRootView.swift
