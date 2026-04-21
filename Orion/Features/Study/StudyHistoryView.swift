// StudyHistoryView.swift — Features/Study

import SwiftUI
import SwiftData

struct StudyHistoryView: View {
    @Query(sort: \StudySession.date, order: .reverse)
    private var sessions: [StudySession]

    var body: some View {
        ZStack {
            StarFieldView().ignoresSafeArea()

            Group {
                if sessions.isEmpty {
                    EmptyStateView(
                        systemImage: "book.fill",
                        title: "No study history",
                        subtitle: "Your logged sessions will appear here",
                        accentColor: .auroraTeal
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.sm) {
                            ForEach(sessions) { StudySessionCard(session: $0) }
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, Spacing.xxl)
                    }
                }
            }
        }
        .navigationTitle("Study History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
