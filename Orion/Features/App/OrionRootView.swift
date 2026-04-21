// OrionRootView.swift — App
// Extracted from OrionApp.swift in v1.1 to host XP/Badge/RankUp overlays cleanly.

import SwiftUI

struct OrionRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(XPService.self)  private var xpService
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
                        weightRepo: BodyMetricRepository(modelContext: modelContext),
                        streakUseCase: makeStreakUseCase(),
                        xpService: xpService
                    )
                case .study:
                    NavigationStack {
                        StudyLogView(
                            studyRepository: StudyRepository(modelContext: modelContext),
                            streakUseCase: makeStreakUseCase(),
                            xpService: xpService
                        )
                    }
                case .gym:
                    NavigationStack {
                        GymLogView(
                            gymRepository: GymRepository(modelContext: modelContext),
                            streakUseCase: makeStreakUseCase(),
                            modelContext: modelContext,
                            xpService: xpService
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
        .xpBurstOverlay()         // Phase 1: XP burst floating label
    }

    private func makeStreakUseCase() -> StreakUseCase {
        let habitRepo = HabitRepository(modelContext: modelContext)
        return StreakUseCase(habitRepository: habitRepo)
    }
}
