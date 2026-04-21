// HomeView.swift — Features/Home

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel
    @State private var navigateToStreak = false
    @State private var navigateToSettings = false

    @AppStorage(UserPreferencesKey.userName) private var userName: String = "Astronaut"
    @Environment(StudyStatsService.self) private var statsService
    @Environment(PomodoroManager.self) private var pomodoroManager

    init(studyRepo: StudyRepository, gymRepo: GymRepository, streakUseCase: StreakUseCase) {
        _viewModel = State(initialValue: HomeViewModel(
            studyRepository: studyRepo,
            gymRepository: gymRepo,
            streakUseCase: streakUseCase
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                StarFieldView().ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.lg) {
                        headerBar
                        streakHeroCard
                        habitCategoryCards
                        recentActivitySection
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationDestination(isPresented: $navigateToStreak) {
                StreakView(streakUseCase: viewModel.streakUseCase)
            }
            .navigationDestination(isPresented: $navigateToSettings) {
                SettingsView()
            }
            .task { await viewModel.onAppear() }
            .navigationBarHidden(true)
        }
    }

    // MARK: — Header
    private var headerBar: some View {
        HStack(alignment: .center) {
            // Constellation logo + title
            HStack(spacing: Spacing.sm) {
                ConstellationLogoView()
                Text("Orion")
                    .font(.cosmicTitle(28))
                    .foregroundStyle(Color.starWhite)
            }

            Spacer()

            // Settings + Avatar
            Button {
                navigateToSettings = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.auroraTeal.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.auroraTeal.opacity(0.4), lineWidth: 1.5)
                        )
                        .shadow(color: Color.auroraTeal.opacity(0.3), radius: 8)

                    Text(initials)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.auroraTeal)
                }
            }
            .accessibilityLabel("Settings")
        }
        .padding(.top, Spacing.md)
    }

    private var initials: String {
        let parts = userName.split(separator: " ")
        if parts.count >= 2 {
            return String((parts[0].first ?? "O")) + String((parts[1].first ?? "R"))
        }
        return String(userName.prefix(2)).uppercased()
    }

    // MARK: — Streak Hero Card
    private var streakHeroCard: some View {
        Button { navigateToStreak = true } label: {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.xxl)
                    .fill(Color.nebulaCard)
                    .overlay(
                        RadialGradient(
                            colors: [Color.streakGold.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 180
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.xxl)
                            .strokeBorder(Color.surfaceBorder, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)

                VStack(spacing: Spacing.sm) {
                    HStack(spacing: Spacing.sm) {
                        Text("🔥")
                            .font(.system(size: 36))
                        Text("\(viewModel.displayedStreak)")
                            .font(.streakCounter())
                            .foregroundStyle(Color.streakGold)
                        Text("Day")
                            .font(.cosmicTitle(28))
                            .foregroundStyle(Color.starWhite.opacity(0.7))
                            .padding(.top, 8)
                    }

                    Text("Streak")
                        .font(.orbitHeading())
                        .foregroundStyle(Color.moonGray)

                    Divider()
                        .background(Color.surfaceBorder)
                        .padding(.horizontal, Spacing.lg)

                    Text(viewModel.todayCompleted ? "All done for today ✓" : "Today's habits pending")
                        .font(.starBody())
                        .foregroundStyle(viewModel.todayCompleted ? Color.auroraTeal : Color.moonGray)

                    ConstellationStreakView(
                        streakDays: viewModel.currentStreak,
                        habitLogs: viewModel.habitLogs,
                        maxDays: 20
                    )
                    .padding(.top, Spacing.xs)
                    
                    // Pomodoro stars earned today
                    if pomodoroManager.todayStars > 0 {
                        HStack(spacing: 4) {
                            ForEach(0..<min(pomodoroManager.todayStars, 8), id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.streakGold)
                                    .shadow(color: Color.streakGold.opacity(0.7), radius: 4)
                            }
                            if pomodoroManager.todayStars > 8 {
                                Text("+\(pomodoroManager.todayStars - 8)")
                                    .font(.moonCaption(11))
                                    .foregroundStyle(Color.streakGold)
                            }
                        }
                        .padding(.top, 2)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(Spacing.lg)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(viewModel.currentStreak)-day streak. Tap to view details.")
    }

    // MARK: — Habit Category Cards
    private var habitCategoryCards: some View {
        HStack(spacing: Spacing.md) {
            NavigationLink {
                StudyLogView(
                    studyRepository: StudyRepository(modelContext: modelContext),
                    streakUseCase: viewModel.streakUseCase
                )
            } label: {
                HabitCategoryCard(
                    category: .study,
                    subtitle: "\(viewModel.todayStudyFormatted) today",
                    progress: viewModel.studyProgress,
                    weeklyLabel: "Week: \(statsService.weeklyProgressLabel)",
                    weeklyProgress: statsService.weeklyProgress
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                GymLogView(
                    gymRepository: GymRepository(modelContext: modelContext),
                    streakUseCase: viewModel.streakUseCase
                )
            } label: {
                HabitCategoryCard(
                    category: .gym,
                    subtitle: viewModel.gymSessionsToday > 0 ? "\(viewModel.gymSessionsToday) session today" : "No session yet",
                    progress: viewModel.gymProgress
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: — Recent Activity
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Recent Sessions")
                .font(.orbitHeading())
                .foregroundStyle(Color.starWhite)

            if viewModel.recentSessions.isEmpty {
                EmptyStateView(
                    systemImage: "sparkles",
                    title: "No sessions yet",
                    subtitle: "Log your first study or gym session to start your cosmic journey",
                    accentColor: .auroraTeal
                )
            } else {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(viewModel.recentSessions.indices, id: \.self) { index in
                        let session = viewModel.recentSessions[index]
                        RecentSessionRow(session: session)
                    }
                }
            }
        }
    }

    // MARK: — Streaming props access helper
    private var streakUseCase: StreakUseCase { viewModel.streakUseCase }
}

// MARK: — Habit Category Card
private struct HabitCategoryCard: View {
    let category: HabitCategory
    let subtitle: String
    let progress: Double
    var weeklyLabel: String? = nil
    var weeklyProgress: Double? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: category.systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(category.accentColor)
                    .shadow(color: category.accentColor.opacity(0.6), radius: 6)
                Spacer()
                OrbitProgressRing(
                    progress: progress,
                    gradient: category == .study ? .auroraGradient : .novaGradient,
                    size: 52,
                    lineWidth: 5
                )
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(category.displayName)
                    .font(.orbitHeading(17))
                    .foregroundStyle(Color.starWhite)
                Text(subtitle)
                    .font(.moonCaption())
                    .foregroundStyle(Color.moonGray)
                    .lineLimit(2)
                
                if let wLabel = weeklyLabel, let wProg = weeklyProgress {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(wLabel)
                            .font(.moonCaption())
                            .foregroundStyle(Color.dustGray)
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.dustGray.opacity(0.3))
                                    .frame(height: 3)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(category.accentColor)
                                    .frame(width: geo.size.width * CGFloat(wProg), height: 3)
                            }
                        }
                        .frame(height: 3)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .fill(Color.nebulaCard)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.xl)
                        .strokeBorder(category.accentColor.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .frame(maxWidth: .infinity)
        .accessibilityLabel("\(category.displayName). \(subtitle). Progress \(Int(progress * 100))%")
    }
}

// MARK: — Recent Session Row
private struct RecentSessionRow: View {
    let session: (category: HabitCategory, title: String, subtitle: String, duration: String, date: Date)

    var body: some View {
        NebulaCardView(accentColor: session.category.accentColor, showAccentLine: true) {
            HStack(spacing: Spacing.md) {
                Image(systemName: session.category.systemImage)
                    .font(.system(size: 18))
                    .foregroundStyle(session.category.accentColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.title)
                        .font(.starBody())
                        .foregroundStyle(Color.starWhite)
                        .lineLimit(1)
                    Text(session.subtitle)
                        .font(.moonCaption())
                        .foregroundStyle(Color.moonGray)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    DurationBadge(duration: session.duration, color: session.category.accentColor)
                    Text(DateHelper.shortDate(session.date))
                        .font(.moonCaption(11))
                        .foregroundStyle(Color.dustGray)
                }
            }
        }
    }
}

// MARK: — Constellation Logo (SwiftUI Path)
struct ConstellationLogoView: View {
    var body: some View {
        Canvas { context, size in
            let stars: [(CGFloat, CGFloat)] = [
                (0.5, 0.1), (0.2, 0.4), (0.8, 0.35),
                (0.4, 0.7), (0.7, 0.75), (0.15, 0.8)
            ]
            let connections = [(0,1),(0,2),(1,3),(2,4),(3,5),(3,4)]

            // Draw connecting lines
            for (a, b) in connections {
                var path = Path()
                path.move(to: CGPoint(x: stars[a].0 * size.width, y: stars[a].1 * size.height))
                path.addLine(to: CGPoint(x: stars[b].0 * size.width, y: stars[b].1 * size.height))
                context.stroke(path, with: .color(Color.auroraTeal.opacity(0.5)), lineWidth: 0.8)
            }

            // Draw star dots
            for star in stars {
                let center = CGPoint(x: star.0 * size.width, y: star.1 * size.height)
                context.fill(
                    Path(ellipseIn: CGRect(x: center.x - 2, y: center.y - 2, width: 4, height: 4)),
                    with: .color(.auroraTeal)
                )
            }
        }
        .frame(width: 32, height: 32)
    }
}

// MARK: — Duration Badge
struct DurationBadge: View {
    let duration: String
    let color: Color

    var body: some View {
        Text(duration)
            .font(.monoData(12))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
                    .overlay(Capsule().strokeBorder(color.opacity(0.3), lineWidth: 0.5))
            )
    }
}
