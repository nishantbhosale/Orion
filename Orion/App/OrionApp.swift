// OrionApp.swift — App entry point

import SwiftUI
import SwiftData

@main
struct OrionApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @AppStorage(UserPreferencesKey.hasOnboarded) private var hasOnboarded: Bool = false
    @State private var studyStatsService = StudyStatsService()
    @State private var pomodoroManager = PomodoroManager()
    @Environment(\.scenePhase) private var scenePhase

    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            StudySession.self,
            GymSession.self,
            HabitLog.self,
            StreakData.self
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
            .preferredColorScheme(.dark)
            .onChange(of: scenePhase) { _, newPhase in
                pomodoroManager.handleScenePhaseChange(newPhase)
            }
            .task {
                // Validate streak on every launch (async, not blocking main thread)
                let context = ModelContext(modelContainer)
                let habitRepo = HabitRepository(modelContext: context)
                let streakUC  = StreakUseCase(habitRepository: habitRepo)
                await streakUC.validateAndUpdateStreak()

                // Request notification permission
                NotificationManager.shared.requestPermission()
            }
        }
    }
}

// MARK: — Root View with Custom Tab Bar
struct OrionRootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: OrionTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch selectedTab {
                case .home:
                    HomeView(
                        studyRepo: StudyRepository(modelContext: modelContext),
                        gymRepo:   GymRepository(modelContext: modelContext),
                        streakUseCase: makeStreakUseCase()
                    )
                case .study:
                    NavigationStack {
                        StudyLogView(
                            studyRepository: StudyRepository(modelContext: modelContext),
                            streakUseCase: makeStreakUseCase()
                        )
                    }
                case .gym:
                    NavigationStack {
                        GymLogView(
                            gymRepository: GymRepository(modelContext: modelContext),
                            streakUseCase: makeStreakUseCase()
                        )
                    }
                case .history:
                    HistoryView(
                        studyRepo: StudyRepository(modelContext: modelContext),
                        gymRepo:   GymRepository(modelContext: modelContext),
                        streakUseCase: makeStreakUseCase()
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom tab bar   
            CosmicTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func makeStreakUseCase() -> StreakUseCase {
        let habitRepo = HabitRepository(modelContext: modelContext)
        return StreakUseCase(habitRepository: habitRepo)
    }
}
