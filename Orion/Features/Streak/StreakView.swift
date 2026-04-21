// StreakView.swift — Features/Streak

import SwiftUI
import SwiftData
import Charts

struct StreakView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: StreakViewModel

    init(streakUseCase: StreakUseCase, modelContext: ModelContext, xpService: XPService? = nil) {
        let weightRepo = BodyMetricRepository(modelContext: modelContext)
        weightRepo.xpService = xpService
        let tempVM = StreakViewModel(
            streakUseCase: streakUseCase,
            habitRepository: HabitRepository(modelContext: modelContext),
            weightRepository: weightRepo,
            gymRepository: GymRepository(modelContext: modelContext)
        )
        _viewModel = State(initialValue: tempVM)
    }

    var body: some View {
        ZStack {
            StarFieldView().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.xl) {
                    constellationSection
                    statsPanel
                    monthlyCalendar
                    milestoneBadges
                    bodyWeightCard
                    volumeChartCard
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .navigationTitle("Streak")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.onAppear() }
        .sheet(isPresented: $viewModel.showWeightLogSheet) {
            LogWeightSheet(viewModel: viewModel)
        }
    }

    // MARK: — Constellation Section
    private var constellationSection: some View {
        NebulaCardView {
            VStack(spacing: Spacing.lg) {
                HStack(spacing: Spacing.sm) {
                    Text("🔥")
                        .font(.system(size: 32))
                    Text("\(viewModel.currentStreak)")
                        .font(.streakCounter(56))
                        .foregroundStyle(Color.streakGold)
                    Text("Day Streak")
                        .font(.orbitHeading(20))
                        .foregroundStyle(Color.starWhite.opacity(0.8))
                        .padding(.top, 6)
                }

                ConstellationStreakView(
                    streakDays: viewModel.currentStreak,
                    habitLogs: viewModel.habitLogs,
                    maxDays: 30
                )
            }
        }
        .padding(.top, Spacing.sm)
    }

    // MARK: — Stats Panel
    private var statsPanel: some View {
        HStack(spacing: Spacing.md) {
            streakStatCard(
                label: "Longest Streak",
                value: "\(viewModel.longestStreak)",
                suffix: "days",
                color: .streakGold,
                icon: "trophy.fill"
            )
            streakStatCard(
                label: "Study Days",
                value: "\(viewModel.studyDaysThisMonth)",
                suffix: "this month",
                color: .auroraTeal,
                icon: "book.fill"
            )
            streakStatCard(
                label: "Gym Days",
                value: "\(viewModel.gymDaysThisMonth)",
                suffix: "this month",
                color: .novaOrange,
                icon: "dumbbell.fill"
            )
        }
    }

    private func streakStatCard(label: String, value: String, suffix: String, color: Color, icon: String) -> some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.5), radius: 4)

            Text(value)
                .font(.cosmicTitle(28))
                .foregroundStyle(color)
            Text(suffix)
                .font(.moonCaption(10))
                .foregroundStyle(Color.moonGray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.nebulaCard)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .strokeBorder(color.opacity(0.2), lineWidth: 1)
                )
        )
        .accessibilityLabel("\(label): \(value) \(suffix)")
    }

    // MARK: — Monthly Calendar
    private var monthlyCalendar: some View {
        NebulaCardView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                let formatter: DateFormatter = {
                    let f = DateFormatter()
                    f.dateFormat = "MMMM yyyy"
                    return f
                }()

                Text(formatter.string(from: .now))
                    .font(.orbitHeading())
                    .foregroundStyle(Color.starWhite)

                // Day-of-week headers
                let dayLetters = ["S","M","T","W","T","F","S"]
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Spacing.sm) {
                    ForEach(dayLetters.indices, id: \.self) { i in
                        Text(dayLetters[i])
                            .font(.moonCaption(11))
                            .foregroundStyle(Color.moonGray)
                    }

                    // Leading spacers for first weekday
                    let firstWeekday = firstWeekdayOffset()
                    ForEach(0..<firstWeekday, id: \.self) { _ in Color.clear.frame(height: 30) }

                    // Day cells
                    ForEach(viewModel.calendarDays, id: \.self) { day in
                        let isToday = DateHelper.isToday(day)
                        let habitColor = viewModel.calendarCellColor(for: day)
                        let hasHabit = habitColor != .clear

                        ZStack {
                            Circle()
                                .fill(hasHabit ? habitColor.opacity(0.25) : Color.clear)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            isToday ? Color.streakGold : (hasHabit ? habitColor.opacity(0.5) : Color.clear),
                                            lineWidth: isToday ? 2 : 1
                                        )
                                )

                            Text("\(DateHelper.dayNumber(day))")
                                .font(.moonCaption(12))
                                .foregroundStyle(hasHabit ? habitColor : (isToday ? Color.starWhite : Color.moonGray))
                        }
                        .frame(height: 30)
                        .accessibilityLabel(calendarAccessibility(for: day))
                    }
                }
            }
        }
    }

    // MARK: — Milestone Badges
    private var milestoneBadges: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Milestones")
                .font(.orbitHeading())
                .foregroundStyle(Color.starWhite)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.lg) {
                    ForEach(viewModel.badges) { badge in
                        MilestoneBadgeView(badge: badge)
                    }
                }
                .padding(.horizontal, Spacing.xs)
            }
        }
    }

    // MARK: — Helpers
    private func firstWeekdayOffset() -> Int {
        guard let firstDay = viewModel.calendarDays.first else { return 0 }
        let weekday = Calendar.current.component(.weekday, from: firstDay)
        return weekday - 1  // Sunday = 0
    }

    private func calendarAccessibility(for day: Date) -> String {
        let dayNum = DateHelper.dayNumber(day)
        guard let log = viewModel.habitLogFor(date: day) else { return "Day \(dayNum), no habit" }
        if log.hasStudy && log.hasGym { return "Day \(dayNum), study and gym completed" }
        if log.hasStudy { return "Day \(dayNum), study completed" }
        if log.hasGym   { return "Day \(dayNum), gym completed" }
        return "Day \(dayNum)"
    }

    // MARK: — Body Weight
    private var bodyWeightCard: some View {
        NebulaCardView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Label("Body Weight", systemImage: "scalemass.fill")
                        .font(.orbitHeading())
                        .foregroundStyle(Color.starWhite)
                    
                    Spacer()
                    
                    Button {
                        HapticManager.impact(.light)
                        viewModel.showWeightLogSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Log")
                        }
                        .font(.moonCaption(13))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.auroraTeal)
                    }
                }

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        if let latest = viewModel.latestWeight {
                            Text("\(String(format: "%.1f", latest.weightKg)) \(viewModel.weightUnit)")
                                .font(.cosmicTitle(32))
                                .foregroundStyle(Color.starWhite)
                            Text(viewModel.weightTrend)
                                .font(.moonCaption())
                                .foregroundStyle(Color.auroraTeal)
                        } else {
                            Text("No weight logged")
                                .font(.starBody())
                                .foregroundStyle(Color.moonGray)
                        }
                    }
                    
                    Spacer()
                    
                    // Sparkline
                    if viewModel.last30Weights.count >= 2 {
                        Chart(viewModel.last30Weights) { log in
                            LineMark(
                                x: .value("Date", log.date),
                                y: .value("Weight", log.weightKg)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Color.auroraTeal)
                            
                            PointMark(
                                x: .value("Date", log.date),
                                y: .value("Weight", log.weightKg)
                            )
                            .foregroundStyle(Color.auroraTeal)
                            .symbolSize(log.id == viewModel.latestWeight?.id ? 20 : 0)
                        }
                        .chartXAxis(.hidden)
                        .chartYAxis(.hidden)
                        .chartYScale(domain: .automatic(includesZero: false))
                        .frame(width: 100, height: 40)
                    }
                }
            }
        }
    }

    // MARK: — Volume Chart
    @ViewBuilder
    private var volumeChartCard: some View {
        let volumes = viewModel.gymStats.weeklyMuscleVolume
        let warnings = viewModel.gymStats.imbalanceWarnings

        if !volumes.isEmpty {
            NebulaCardView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Label("Volume This Week", systemImage: "chart.bar.fill")
                        .font(.orbitHeading())
                        .foregroundStyle(Color.starWhite)

                    VStack(spacing: Spacing.sm) {
                        ForEach(volumes) { mv in
                            HStack(spacing: Spacing.sm) {
                                Text(mv.group.displayName)
                                    .font(.moonCaption(12))
                                    .foregroundStyle(Color.moonGray)
                                    .frame(width: 72, alignment: .leading)

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.novaOrange.opacity(0.12))
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.novaOrange.opacity(0.7))
                                            .frame(width: geo.size.width * mv.barFraction)
                                    }
                                }
                                .frame(height: 12)

                                Text("\(mv.totalSets)s")
                                    .font(.moonCaption(11))
                                    .foregroundStyle(Color.novaOrange)
                                    .frame(width: 28, alignment: .trailing)
                            }
                        }
                    }

                    if !warnings.isEmpty {
                        Divider().background(Color.surfaceBorder)
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(warnings, id: \.self) { warning in
                                Text(warning)
                                    .font(.moonCaption(12))
                                    .foregroundStyle(Color.streakGold)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: — StreakView with ModelContext-aware init
extension StreakView {
    // Factory for use from HomeViewModel where we have modelContext
    static func make(streakUseCase: StreakUseCase, modelContext: ModelContext) -> StreakView {
        StreakView(streakUseCase: streakUseCase, modelContext: modelContext)
    }
}

// MARK: — Milestone Badge View
private struct MilestoneBadgeView: View {
    let badge: StreakViewModel.MilestoneBadge
    @State private var shimmer = false

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(badge.isEarned ? Color.streakGold.opacity(0.15) : Color.nebulaCard)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                badge.isEarned ? Color.streakGold : Color.dustGray,
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: badge.isEarned ? Color.streakGold.opacity(shimmer ? 0.5 : 0.2) : .clear,
                        radius: shimmer ? 12 : 6
                    )

                if badge.isEarned {
                    Image(systemName: badge.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(Color.streakGold)
                } else {
                    ZStack {
                        Image(systemName: badge.icon)
                            .font(.system(size: 28))
                            .foregroundStyle(Color.moonGray.opacity(0.3))
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.moonGray.opacity(0.5))
                            .offset(x: 14, y: 14)
                    }
                }
            }
            .onAppear {
                if badge.isEarned {
                    withAnimation(OrionAnimation.pulsingGlow) { shimmer = true }
                }
            }

            Text(badge.name)
                .font(.moonCaption(11))
                .fontWeight(.semibold)
                .foregroundStyle(badge.isEarned ? Color.starWhite : Color.moonGray)
                .multilineTextAlignment(.center)

            Text(badge.description)
                .font(.moonCaption(10))
                .foregroundStyle(Color.dustGray)
        }
        .frame(width: 88)
        .accessibilityLabel("\(badge.name) badge. \(badge.isEarned ? "Earned" : "Locked"). \(badge.description)")
    }
}
