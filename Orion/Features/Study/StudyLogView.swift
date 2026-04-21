// StudyLogView.swift — Features/Study

import SwiftUI
import SwiftData

struct StudyLogView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: StudyViewModel
    @AppStorage(UserPreferencesKey.studySubjects) private var studySubjects: [String] = UserPreferencesKey.defaultStudySubjects
    @AppStorage(UserPreferencesKey.weeklyGoalCelebratedDate) private var celebratedDate: String = ""
    @Environment(StudyStatsService.self) private var statsService
    @Environment(PomodoroManager.self) private var pomodoroManager

    enum DurationMode: String, CaseIterable {
        case manual   = "Manual"
        case timer    = "Timer"
        case pomodoro = "Pomodoro"
    }
    @State private var durationMode: DurationMode = .manual

    @Query(sort: \StudySession.createdAt, order: .reverse)
    private var allSessions: [StudySession]

    private var todaySessions: [StudySession] {
        allSessions.filter { DateHelper.isToday($0.date) }
    }

    init(studyRepository: StudyRepository, streakUseCase: StreakUseCase, xpService: XPService? = nil) {
        _viewModel = State(initialValue: StudyViewModel(
            studyRepository: studyRepository,
            streakUseCase: streakUseCase,
            xpService: xpService
        ))
    }

    var body: some View {
        ZStack {
            StarFieldView().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.lg) {
                    screenHeader
                    WeeklyGoalBannerView(
                        progress: statsService.weeklyProgress,
                        label: statsService.weeklyProgressLabel,
                        goalMet: statsService.weeklyGoalMet
                    )
                    formCard
                    statsStrip
                    todaySessionsList
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .navigationTitle("Study")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .shootingStarToast(message: viewModel.toastMessage, isShowing: $viewModel.showToast)
        .task { 
            statsService.calculateWeeklyStats(from: allSessions)
        }
        .onChange(of: allSessions) { _, newSessions in
            statsService.calculateWeeklyStats(from: newSessions)
        }
        .onChange(of: statsService.weeklyGoalMet) { _, met in
            guard met else { return }
            let today = DateHelper.formatDate(.now, format: "yyyy-MM-dd")
            guard celebratedDate != today else { return }
            celebratedDate = today
            viewModel.toastMessage = "🏆 Weekly goal smashed! You're on fire."
            viewModel.showToast = true
        }
        .sheet(isPresented: $viewModel.showFocusRatingSheet) {
            FocusRatingSheet(isPresented: $viewModel.showFocusRatingSheet) { focusScore in
                Task { await viewModel.commitSession(focusScore: focusScore) }
            }
        }
        .onDisappear { viewModel.onDisappear() }
    }

    // MARK: — Header
    private var screenHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Study Session")
                    .font(.cosmicTitle(26))
                    .foregroundStyle(Color.starWhite)
                Text(formattedToday)
                    .font(.moonCaption())
                    .foregroundStyle(Color.moonGray)
            }
            Spacer()
            Image(systemName: "book.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.auroraTeal)
                .shadow(color: Color.auroraTeal.opacity(0.6), radius: 8)
        }
        .padding(.top, Spacing.sm)
    }

    // MARK: — Form Card
    private var formCard: some View {
        NebulaCardView {
            VStack(spacing: Spacing.md) {
                // Module Name
                cosmicTextField(
                    placeholder: "Module / Subject name",
                    text: $viewModel.moduleName,
                    icon: "doc.text.fill"
                )
                .submitLabel(.next)

                // Topic Detail
                cosmicTextField(
                    placeholder: "Topic covered (optional)",
                    text: $viewModel.topicDetail,
                    icon: "tag.fill"
                )
                .submitLabel(.next)

                // Subject Picker
                subjectPicker

                Divider().background(Color.surfaceBorder)

                // Duration
                durationSection

                Divider().background(Color.surfaceBorder)

                // Notes
                notesField

                // Error
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.moonCaption())
                        .foregroundStyle(Color.novaOrange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Log Button
                PulsingStarButton(
                    title: "Log Study Session",
                    systemImage: "plus.circle.fill",
                    gradient: .auroraGradient,
                    action: { viewModel.logSession() },
                    isLoading: viewModel.isLogging
                )
            }
        }
    }

    // MARK: — Subject Picker
    private var subjectPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Subject", systemImage: "books.vertical.fill")
                .font(.moonCaption())
                .foregroundStyle(Color.moonGray)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(studySubjects, id: \.self) { subject in
                        Button {
                            viewModel.subject = subject
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 12))
                                Text(subject)
                                    .font(.moonCaption())
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(
                                Capsule()
                                    .fill(viewModel.subject == subject
                                        ? Color.auroraTeal.opacity(0.25)
                                        : Color.nebulaCardHover)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(
                                                viewModel.subject == subject ? Color.auroraTeal : Color.surfaceBorder,
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .foregroundStyle(viewModel.subject == subject ? Color.auroraTeal : Color.moonGray)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(subject)
                        .accessibilityAddTraits(viewModel.subject == subject ? [.isSelected, .isButton] : .isButton)
                    }
                }
            }
        }
    }

    // MARK: — Duration Section
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Mode picker
            Picker("Mode", selection: $durationMode.animation()) {
                ForEach(DurationMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: durationMode) { _, mode in
                // Sync useTimer for legacy logic
                viewModel.useTimer = (mode == .timer)
                if mode != .pomodoro { pomodoroManager.pause() }
            }

            switch durationMode {
            case .manual:   manualDurationPickers
            case .timer:    timerSection
            case .pomodoro: PomodoroRingView().padding(.top, Spacing.sm)
            }
        }
    }

    private var timerSection: some View {
        VStack(spacing: Spacing.md) {
            // Pulsing ring while running
            ZStack {
                if viewModel.timerRunning {
                    Circle()
                        .stroke(Color.auroraTeal.opacity(0.2), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.timerSeconds % 60) / 60.0)
                        .stroke(Color.auroraTeal, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 100, height: 100)
                        .animation(.linear(duration: 1), value: viewModel.timerSeconds)
                }

                Text(viewModel.timerDisplay)
                    .font(.monoData(28))
                    .foregroundStyle(Color.starWhite)
            }
            .frame(height: 110)

            HStack(spacing: Spacing.lg) {
                if viewModel.timerRunning {
                    Button {
                        HapticManager.impact(.medium)
                        viewModel.stopTimer()
                    } label: {
                        Label("Stop", systemImage: "stop.circle.fill")
                            .font(.orbitHeading())
                            .foregroundStyle(Color.novaOrange)
                    }
                    .accessibilityLabel("Stop timer")
                } else {
                    Button {
                        HapticManager.impact(.light)
                        viewModel.startTimer()
                    } label: {
                        Label("Start", systemImage: "play.circle.fill")
                            .font(.orbitHeading())
                            .foregroundStyle(Color.auroraTeal)
                    }
                    .accessibilityLabel("Start timer")
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var manualDurationPickers: some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hours")
                    .font(.moonCaption(11))
                    .foregroundStyle(Color.moonGray)
                Picker("Hours", selection: $viewModel.hours) {
                    ForEach(0..<13) { Text("\($0)h").tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(height: 80)
                .clipped()
                .tint(Color.auroraTeal)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Minutes")
                    .font(.moonCaption(11))
                    .foregroundStyle(Color.moonGray)
                Picker("Minutes", selection: $viewModel.minutes) {
                    ForEach(0..<60) { Text("\($0)m").tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(height: 80)
                .clipped()
                .tint(Color.auroraTeal)
            }
        }
    }

    // MARK: — Notes
    private var notesField: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Notes (optional)", systemImage: "note.text")
                .font(.moonCaption())
                .foregroundStyle(Color.moonGray)

            TextEditor(text: $viewModel.notes)
                .scrollContentBackground(.hidden)
                .font(.starBody())
                .foregroundStyle(Color.starWhite)
                .frame(minHeight: 80)
                .padding(Spacing.sm)
                .background(Color.nebulaCardHover)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .strokeBorder(Color.surfaceBorder, lineWidth: 1)
                )
        }
    }

    // MARK: — Stats Strip
    private var statsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                StatPill(label: "Sessions this week", value: "\(viewModel.weeklySessions)", color: .auroraTeal)
                StatPill(label: "Hours this week", value: DateHelper.formatDuration(minutes: viewModel.weeklyMinutes), color: .pulsarPurple)
                StatPill(label: "Longest session", value: DateHelper.formatDuration(minutes: viewModel.longestSessionMinutes), color: .streakGold)
            }
            .padding(.horizontal, Spacing.xs)
        }
    }

    // MARK: — Today's Sessions
    private var todaySessionsList: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Today's Sessions")
                .font(.orbitHeading())
                .foregroundStyle(Color.starWhite)

            if todaySessions.isEmpty {
                EmptyStateView(
                    systemImage: "book.fill",
                    title: "No sessions today",
                    subtitle: "Log your first study session above to ignite the stars",
                    accentColor: .auroraTeal
                )
            } else {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(todaySessions) { session in
                        StudySessionCard(session: session)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    HapticManager.impact(.medium)
                                    viewModel.deleteSession(session)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }

    // MARK: — Helpers
    private var formattedToday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: .now)
    }

    private func cosmicTextField(placeholder: String, text: Binding<String>, icon: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.moonGray)
                .frame(width: 20)

            TextField(placeholder, text: text)
                .font(.starBody())
                .foregroundStyle(Color.starWhite)
                .autocorrectionDisabled()
        }
        .padding(Spacing.md)
        .background(Color.nebulaCardHover)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .strokeBorder(Color.surfaceBorder, lineWidth: 1)
        )
    }
}

// MARK: — Study Session Card
struct StudySessionCard: View {
    let session: StudySession

    var body: some View {
        NebulaCardView(accentColor: .auroraTeal, showAccentLine: true) {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.moduleName)
                        .font(.starBody())
                        .foregroundStyle(Color.starWhite)
                        .lineLimit(1)

                    if let topic = session.topicDetail {
                        Text(topic)
                            .font(.moonCaption())
                            .foregroundStyle(Color.moonGray)
                            .lineLimit(1)
                    }

                    Text(session.subject)
                        .font(.moonCaption(11))
                        .foregroundStyle(Color.auroraTeal.opacity(0.8))
                        
                    if let score = session.focusScore {
                        CosmicStarRating(rating: .constant(score), isInteractive: false)
                            .padding(.top, 2)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    DurationBadge(duration: session.formattedDuration, color: .auroraTeal)
                    Text(DateHelper.shortTime(session.createdAt))
                        .font(.moonCaption(11))
                        .foregroundStyle(Color.dustGray)
                }
            }
        }
    }
}

// MARK: — Stat Pill
struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(.moonCaption(11))
                .foregroundStyle(Color.moonGray)
            Text(value)
                .font(.orbitHeading(18))
                .foregroundStyle(color)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.nebulaCard)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .strokeBorder(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
// WeeklyGoalBannerView.swift — Components
import SwiftUI

struct WeeklyGoalBannerView: View {
    var progress: Double
    var label: String
    var goalMet: Bool

    var body: some View {
        NebulaCardView {
            VStack(spacing: Spacing.sm) {
                HStack {
                    Label(goalMet ? "🏆 Weekly goal smashed!" : "This Week", systemImage: goalMet ? "star.fill" : "calendar")
                        .font(.moonCaption())
                        .foregroundStyle(goalMet ? Color.streakGold : Color.moonGray)
                    
                    Spacer()
                    
                    Text(label)
                        .font(.monoData(14))
                        .foregroundStyle(Color.starWhite)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.dustGray.opacity(0.3))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(goalMet ? Color.streakGold : Color.auroraTeal)
                            .frame(width: geo.size.width * CGFloat(progress), height: 6)
                            .animation(.spring(duration: 1.0), value: progress)
                    }
                }
                .frame(height: 6)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(goalMet ? RadialGradient(colors: [Color.streakGold.opacity(0.08), .clear], center: .center, startRadius: 0, endRadius: 100) : RadialGradient(colors: [.clear], center: .center, startRadius: 0, endRadius: 0))
        )
    }
}

// CosmicStarRating.swift — Components
import SwiftUI

struct CosmicStarRating: View {
    @Binding var rating: Int
    var maxRating: Int = 5
    var isInteractive: Bool = true
    var onRate: ((Int) -> Void)? = nil

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(1...maxRating, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: isInteractive ? 32 : 14))
                    .foregroundStyle(star <= rating ? Color.streakGold : Color.moonGray)
                    .scaleEffect(star == rating && isInteractive ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: rating)
                    .onTapGesture {
                        if isInteractive {
                            HapticManager.impact(.light)
                            rating = star
                            onRate?(star)
                        }
                    }
                    .accessibilityLabel("\(star) star\(star == 1 ? "" : "s")")
                    .accessibilityAddTraits(star <= rating ? [.isSelected] : [])
            }
        }
    }
}

// FocusRatingSheet.swift — Components
import SwiftUI

struct FocusRatingSheet: View {
    @Binding var isPresented: Bool
    var onCommit: (Int?) -> Void

    @State private var selectedRating: Int = 0
    @State private var autoDismissTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.cosmicBlack.ignoresSafeArea()
            StarFieldView().ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Text("How was your focus?")
                    .font(.cosmicTitle())
                    .foregroundStyle(Color.starWhite)
                
                Text("Rate your session to track your flow state over time.")
                    .font(.starBody())
                    .foregroundStyle(Color.moonGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)

                CosmicStarRating(rating: $selectedRating) { _ in
                    cancelAutoDismiss()
                }
                .padding(.vertical, Spacing.md)

                HStack(spacing: Spacing.md) {
                    Button("Skip") {
                        cancelAutoDismiss()
                        onCommit(nil)
                        isPresented = false
                    }
                    .font(.orbitHeading())
                    .foregroundStyle(Color.moonGray)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    
                    Button("Save") {
                        cancelAutoDismiss()
                        onCommit(selectedRating > 0 ? selectedRating : nil)
                        isPresented = false
                    }
                    .font(.orbitHeading())
                    .foregroundStyle(Color.cosmicBlack)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.vertical, Spacing.sm)
                    .background(selectedRating > 0 ? Color.streakGold : Color.moonGray.opacity(0.5))
                    .clipShape(Capsule())
                    .disabled(selectedRating == 0)
                }
            }
            .padding(.top, Spacing.xl)
        }
        .presentationDetents([.medium])
        .onAppear {
            startAutoDismissTimer()
        }
        .onDisappear {
            cancelAutoDismiss()
        }
    }

    private func startAutoDismissTimer() {
        autoDismissTask = Task {
            try? await Task.sleep(nanoseconds: 15_000_000_000)
            if !Task.isCancelled {
                await MainActor.run {
                    onCommit(nil)
                    isPresented = false
                }
            }
        }
    }

    private func cancelAutoDismiss() {
        autoDismissTask?.cancel()
        autoDismissTask = nil
    }
}
// PomodoroRingView.swift — Features/Study
// Premium countdown ring for the Pomodoro timer mode.
// Displays a gradient arc, pulsing glow, an MM:SS counter, phase label,
// and a row of completed-pomodoro dots below.

import SwiftUI

struct PomodoroRingView: View {
    @Environment(PomodoroManager.self) private var manager

    // Ring interpolates: focus = teal → orange as time depletes
    private var ringColor: Color {
        switch manager.phase {
        case .focus:      return Color.auroraTeal.interpolated(to: .novaOrange, fraction: manager.progress)
        case .shortBreak: return Color.pulsarPurple
        case .longBreak:  return Color.streakGold
        }
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // ── Ring ──────────────────────────────
            ZStack {
                // Track ring
                Circle()
                    .stroke(Color.surfaceBorder, lineWidth: 12)
                    .frame(width: 200, height: 200)

                // Progress arc
                Circle()
                    .trim(from: 0, to: CGFloat(manager.progress))
                    .stroke(
                        AngularGradient(
                            colors: [ringColor.opacity(0.4), ringColor],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 200, height: 200)
                    .shadow(color: ringColor.opacity(0.5), radius: 8)
                    .animation(.linear(duration: 1), value: manager.progress)

                // Inner content
                VStack(spacing: 4) {
                    Image(systemName: manager.phase.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(ringColor)
                        .shadow(color: ringColor.opacity(0.7), radius: 6)

                    Text(manager.timeDisplay)
                        .font(.monoData(40))
                        .foregroundStyle(Color.starWhite)
                        .contentTransition(.numericText())
                        .animation(.linear(duration: 0.3), value: manager.timeDisplay)

                    Text(manager.phase.rawValue)
                        .font(.moonCaption(12))
                        .foregroundStyle(Color.moonGray)
                }
            }

            // ── Controls ─────────────────────────
            HStack(spacing: Spacing.xl) {
                // Stop
                Button {
                    HapticManager.impact(.medium)
                    manager.stop()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.novaOrange.opacity(0.8))
                }
                .accessibilityLabel("Stop Pomodoro")

                // Play / Pause
                Button {
                    HapticManager.impact(.medium)
                    manager.isRunning ? manager.pause() : manager.start()
                } label: {
                    Image(systemName: manager.isRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 54))
                        .foregroundStyle(ringColor)
                        .shadow(color: ringColor.opacity(0.5), radius: 10)
                        .scaleEffect(manager.isRunning ? 1.0 : 1.05)
                        .animation(.spring(response: 0.3), value: manager.isRunning)
                }
                .accessibilityLabel(manager.isRunning ? "Pause focus session" : "Start focus session")

                // Skip
                Button {
                    HapticManager.impact(.light)
                    manager.skipPhase()
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.moonGray.opacity(0.7))
                }
                .accessibilityLabel("Skip to next phase")
            }

            // ── Completed dots ────────────────────
            if manager.completedPomodoros > 0 {
                HStack(spacing: 6) {
                    ForEach(0..<min(manager.completedPomodoros, 8), id: \.self) { i in
                        Circle()
                            .fill(i < manager.completedPomodoros ? Color.streakGold : Color.surfaceBorder)
                            .frame(width: 8, height: 8)
                            .shadow(color: Color.streakGold.opacity(0.6), radius: 3)
                    }
                }
                .padding(.top, -Spacing.sm)
            }
        }
    }
}

// MARK: — Color interpolation helper
extension Color {
    /// Linearly interpolates between two colours in RGB space.
    func interpolated(to target: Color, fraction: Double) -> Color {
        let t = max(0, min(1, fraction))
        let from = UIColor(self)
        let to   = UIColor(target)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        from.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        to.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return Color(
            red:   r1 + (r2 - r1) * t,
            green: g1 + (g2 - g1) * t,
            blue:  b1 + (b2 - b1) * t,
            opacity: 1
        )
    }
}
