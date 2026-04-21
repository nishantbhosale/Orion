// GymHistoryView.swift — Features/Gym

import SwiftUI
import SwiftData

struct GymHistoryView: View {
    @Query(sort: \GymSession.date, order: .reverse)
    private var sessions: [GymSession]

    var body: some View {
        ZStack {
            StarFieldView().ignoresSafeArea()

            Group {
                if sessions.isEmpty {
                    EmptyStateView(
                        systemImage: "dumbbell.fill",
                        title: "No gym history",
                        subtitle: "Your logged workouts will appear here",
                        accentColor: .novaOrange
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.sm) {
                            ForEach(sessions) { GymSessionCard(session: $0) }
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, Spacing.xxl)
                    }
                }
            }
        }
        .navigationTitle("Gym History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
