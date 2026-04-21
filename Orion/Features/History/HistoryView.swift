// HistoryView.swift — Features/History

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HistoryViewModel

    init(studyRepo: StudyRepository, gymRepo: GymRepository, streakUseCase: StreakUseCase) {
        _viewModel = State(initialValue: HistoryViewModel(
            studyRepository: studyRepo,
            gymRepository: gymRepo,
            streakUseCase: streakUseCase
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                StarFieldView().ignoresSafeArea()

                VStack(spacing: 0) {
                    filterBar

                    if viewModel.sections.isEmpty {
                        Spacer()
                        EmptyStateView(
                            systemImage: "clock.fill",
                            title: "No sessions found",
                            subtitle: "Your habit history will appear here as you log sessions",
                            accentColor: .pulsarPurple
                        )
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                                // Pinned monthly summary
                                monthlySummaryCard
                                    .padding(.horizontal, Spacing.md)
                                    .padding(.top, Spacing.md)

                                ForEach(viewModel.sections) { section in
                                    Section {
                                        LazyVStack(spacing: Spacing.sm) {
                                            ForEach(section.items) { item in
                                                HistoryItemRow(item: item) {
                                                    Task { await viewModel.delete(item: item) }
                                                }
                                                .padding(.horizontal, Spacing.md)
                                            }
                                        }
                                        .padding(.bottom, Spacing.md)
                                    } header: {
                                        sectionHeader(title: section.title)
                                    }
                                }
                            }
                            .padding(.bottom, Spacing.xxl)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task { await viewModel.loadData() }
            .onChange(of: viewModel.selectedFilter) { _, _ in
                Task { await viewModel.loadData() }
            }
        }
    }

    // MARK: — Filter Bar
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(HistoryFilter.allCases, id: \.self) { filter in
                    Button {
                        HapticManager.selection()
                        viewModel.selectedFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(.moonCaption(13))
                            .fontWeight(viewModel.selectedFilter == filter ? .semibold : .regular)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(
                                Capsule()
                                    .fill(viewModel.selectedFilter == filter
                                        ? Color.pulsarPurple.opacity(0.25)
                                        : Color.nebulaCard)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(
                                                viewModel.selectedFilter == filter ? Color.pulsarPurple : Color.surfaceBorder,
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .foregroundStyle(viewModel.selectedFilter == filter ? Color.pulsarPurple : Color.moonGray)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(filter.rawValue)
                    .accessibilityAddTraits(viewModel.selectedFilter == filter ? [.isSelected, .isButton] : .isButton)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
    }

    // MARK: — Monthly Summary Card
    private var monthlySummaryCard: some View {
        NebulaCardView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("This Month")
                    .font(.orbitHeading(15))
                    .foregroundStyle(Color.moonGray)

                HStack(spacing: Spacing.lg) {
                    summaryItem(value: "\(viewModel.totalStudySessions)", label: "Study", color: .auroraTeal)
                    summaryItem(value: "\(viewModel.totalGymSessions)", label: "Gym", color: .novaOrange)
                    summaryItem(
                        value: DateHelper.formatDuration(minutes: viewModel.totalMinutesThisMonth),
                        label: "Total",
                        color: .streakGold
                    )
                }
            }
        }
    }

    private func summaryItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.cosmicTitle(22))
                .foregroundStyle(color)
            Text(label)
                .font(.moonCaption(11))
                .foregroundStyle(Color.moonGray)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: — Section Header
    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.orbitHeading(14))
                .foregroundStyle(Color.moonGray)
            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.cosmicBlack.opacity(0.85))
    }
}

// MARK: — History Item Row
struct HistoryItemRow: View {
    let item: HistoryItem
    var onDelete: () -> Void
    @State private var expanded = false

    var body: some View {
        NebulaCardView(accentColor: item.category.accentColor, showAccentLine: true) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: Spacing.md) {
                    Image(systemName: item.category.systemImage)
                        .font(.system(size: 18))
                        .foregroundStyle(item.category.accentColor)
                        .frame(width: 26)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.starBody())
                            .foregroundStyle(Color.starWhite)
                            .lineLimit(expanded ? nil : 1)

                        Text(item.subtitle)
                            .font(.moonCaption())
                            .foregroundStyle(Color.moonGray)
                            .lineLimit(expanded ? nil : 1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        DurationBadge(duration: item.duration, color: item.category.accentColor)
                        Text(DateHelper.shortTime(item.date))
                            .font(.moonCaption(11))
                            .foregroundStyle(Color.dustGray)
                    }
                }

                // Expanded Detail
                if expanded {
                    expandedDetail
                        .padding(.top, Spacing.md)
                }
            }
        }
        .onTapGesture {
            HapticManager.impact(.light)
            withAnimation(OrionAnimation.cardAppear) { expanded.toggle() }
        }
        .accessibilityLabel("\(item.category.displayName): \(item.title), \(item.duration)")
        .accessibilityHint("Double tap to \(expanded ? "collapse" : "expand") details")
    }

    @ViewBuilder
    private var expandedDetail: some View {
        Divider().background(Color.surfaceBorder)

        switch item {
        case .study(let session):
            VStack(alignment: .leading, spacing: Spacing.sm) {
                if let topic = session.topicDetail {
                    detailRow(label: "Topic", value: topic)
                }
                detailRow(label: "Subject", value: session.subject)
                detailRow(label: "Date", value: DateHelper.shortDate(session.date))
                
                if let score = session.focusScore {
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Text("Focus:")
                            .font(.moonCaption())
                            .foregroundStyle(Color.moonGray)
                            .frame(width: 60, alignment: .leading)
                        CosmicStarRating(rating: .constant(score), isInteractive: false)
                    }
                }
                if let notes = session.notes, !notes.isEmpty {
                    detailRow(label: "Notes", value: notes)
                }
            }
            .padding(.top, Spacing.sm)

        case .gym(let session):
            VStack(alignment: .leading, spacing: Spacing.sm) {
                detailRow(label: "Type", value: session.workoutType.displayName)
                if !session.exercises.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Exercises")
                            .font(.moonCaption())
                            .foregroundStyle(Color.moonGray)
                        ForEach(session.exercises) { ex in
                            Text("• \(ex.summary)")
                                .font(.starBody(14))
                                .foregroundStyle(Color.starWhite)
                        }
                    }
                }
                if let notes = session.notes, !notes.isEmpty {
                    detailRow(label: "Notes", value: notes)
                }
            }
            .padding(.top, Spacing.sm)
        }
        
        Button(role: .destructive, action: {
            HapticManager.impact(.medium)
            withAnimation(.easeInOut) {
                onDelete()
            }
        }) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "trash")
                Text("Delete Session")
            }
            .font(.orbitHeading(14))
            .foregroundStyle(Color.novaOrange)
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity)
            .background(Color.novaOrange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.sm))
        }
        .padding(.top, Spacing.md)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text(label + ":")
                .font(.moonCaption())
                .foregroundStyle(Color.moonGray)
                .frame(width: 60, alignment: .leading)
            Text(value)
                .font(.starBody(14))
                .foregroundStyle(Color.starWhite)
        }
    }
}
