// SettingsView.swift — Features/Settings

import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @AppStorage(UserPreferencesKey.studySubjects) private var studySubjects: [String] = UserPreferencesKey.defaultStudySubjects
    @State private var newSubjectName: String = ""
    
    // Study Goals
    @AppStorage(UserPreferencesKey.weeklyStudyGoalHours) private var weeklyStudyGoalHours: Int = 15
    @AppStorage(UserPreferencesKey.weeklyGoalStartDay) private var weeklyGoalStartDay: Int = 2
    
    // Pomodoro
    @AppStorage(UserPreferencesKey.pomodoroDurationMinutes) private var pomodoroDurationMinutes: Int = 25
    @AppStorage(UserPreferencesKey.pomodoroShortBreakMinutes) private var pomodoroShortBreakMinutes: Int = 5
    @AppStorage(UserPreferencesKey.pomodoroLongBreakMinutes) private var pomodoroLongBreakMinutes: Int = 15

    var body: some View {
        ZStack {
            StarFieldView().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.lg) {
                    profileSection
                    goalsSection
                    studyGoalsSection
                    pomodoroSection
                    subjectsSection
                    notificationsSection
                    appInfoSection
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xxl)
                .padding(.top, Spacing.md)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: — Profile
    private var profileSection: some View {
        SettingsSection(title: "Profile", icon: "person.fill", accentColor: .auroraTeal) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Your Name")
                    .font(.moonCaption())
                    .foregroundStyle(Color.moonGray)

                TextField("e.g. Alex", text: $viewModel.userName)
                    .font(.starBody())
                    .foregroundStyle(Color.starWhite)
                    .padding(Spacing.md)
                    .background(Color.nebulaCardHover)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .strokeBorder(Color.surfaceBorder, lineWidth: 1)
                    )
                    .autocorrectionDisabled()
                    .submitLabel(.done)
            }
        }
    }

    // MARK: — Goals
    private var goalsSection: some View {
        SettingsSection(title: "Daily Goals", icon: "target", accentColor: .streakGold) {
            VStack(spacing: Spacing.md) {
                // Study goal
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundStyle(Color.auroraTeal)
                        Text("Study Goal")
                            .font(.starBody())
                            .foregroundStyle(Color.starWhite)
                        Spacer()
                        Text(DateHelper.formatDuration(minutes: viewModel.studyGoalMinutes))
                            .font(.monoData())
                            .foregroundStyle(Color.auroraTeal)
                    }
                    Slider(value: Binding(
                        get: { Double(viewModel.studyGoalMinutes) },
                        set: { viewModel.studyGoalMinutes = Int($0) }
                    ), in: 15...360, step: 15)
                    .tint(Color.auroraTeal)
                }

                Divider().background(Color.surfaceBorder)

                // Gym goal
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Image(systemName: "dumbbell.fill")
                            .foregroundStyle(Color.novaOrange)
                        Text("Gym Sessions / Day")
                            .font(.starBody())
                            .foregroundStyle(Color.starWhite)
                        Spacer()
                        Text("\(viewModel.gymGoalSessions)")
                            .font(.monoData())
                            .foregroundStyle(Color.novaOrange)
                    }
                    Stepper("", value: $viewModel.gymGoalSessions, in: 1...5)
                        .labelsHidden()
                        .accessibilityLabel("Gym sessions per day")
                }
            }
        }
    }

    // MARK: — Study Goals
    private var studyGoalsSection: some View {
        SettingsSection(title: "Study Goals", icon: "chart.bar.fill", accentColor: .auroraTeal) {
            VStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("Weekly Target")
                            .font(.starBody())
                            .foregroundStyle(Color.starWhite)
                        Spacer()
                        Text("\(weeklyStudyGoalHours) hrs")
                            .font(.monoData())
                            .foregroundStyle(Color.auroraTeal)
                    }
                    Slider(value: Binding(
                        get: { Double(weeklyStudyGoalHours) },
                        set: { weeklyStudyGoalHours = Int($0) }
                    ), in: 1...40, step: 1)
                    .tint(Color.auroraTeal)
                }

                Divider().background(Color.surfaceBorder)

                HStack {
                    Text("Week Starts On")
                        .font(.starBody())
                        .foregroundStyle(Color.starWhite)
                    Spacer()
                    Picker("Start Day", selection: $weeklyGoalStartDay) {
                        Text("Monday").tag(2)
                        Text("Sunday").tag(1)
                    }
                    .pickerStyle(.menu)
                    .tint(Color.auroraTeal)
                }
            }
        }
    }

    // MARK: — Pomodoro
    private var pomodoroSection: some View {
        SettingsSection(title: "Pomodoro", icon: "timer", accentColor: .streakGold) {
            VStack(spacing: Spacing.md) {
                HStack {
                    Text("Focus Duration")
                        .font(.starBody())
                        .foregroundStyle(Color.starWhite)
                    Spacer()
                    Picker("Focus", selection: $pomodoroDurationMinutes) {
                        Text("15").tag(15)
                        Text("20").tag(20)
                        Text("25").tag(25)
                        Text("30").tag(30)
                        Text("45").tag(45)
                    }
                    .pickerStyle(.menu)
                    .tint(Color.auroraTeal)
                }
                
                Divider().background(Color.surfaceBorder)
                
                HStack {
                    Text("Short Break")
                        .font(.starBody())
                        .foregroundStyle(Color.starWhite)
                    Spacer()
                    Picker("Short", selection: $pomodoroShortBreakMinutes) {
                        Text("5").tag(5)
                        Text("10").tag(10)
                    }
                    .pickerStyle(.menu)
                    .tint(Color.auroraTeal)
                }
                
                Divider().background(Color.surfaceBorder)
                
                HStack {
                    Text("Long Break")
                        .font(.starBody())
                        .foregroundStyle(Color.starWhite)
                    Spacer()
                    Picker("Long", selection: $pomodoroLongBreakMinutes) {
                        Text("15").tag(15)
                        Text("20").tag(20)
                        Text("30").tag(30)
                    }
                    .pickerStyle(.menu)
                    .tint(Color.auroraTeal)
                }
            }
        }
    }

    // MARK: — Study Modules
    private var subjectsSection: some View {
        SettingsSection(title: "Study Modules", icon: "books.vertical.fill", accentColor: .auroraTeal) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    TextField("Add new module", text: $newSubjectName)
                        .font(.starBody())
                        .foregroundStyle(Color.starWhite)
                        .padding(Spacing.sm)
                        .background(Color.nebulaCardHover)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .strokeBorder(Color.surfaceBorder, lineWidth: 1)
                        )
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit { addSubject() }
                        
                    Button(action: addSubject) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.auroraTeal)
                    }
                    .disabled(newSubjectName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                
                ForEach(studySubjects, id: \.self) { subject in
                    HStack {
                        Text(subject)
                            .font(.starBody())
                            .foregroundStyle(Color.starWhite)
                        Spacer()
                        if studySubjects.count > 1 {
                            Button(role: .destructive) {
                                studySubjects = studySubjects.filter { $0 != subject }
                            } label: {
                                Image(systemName: "trash.fill")
                                    .foregroundStyle(Color.moonGray)
                            }
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                    if subject != studySubjects.last {
                        Divider().background(Color.surfaceBorder)
                    }
                }
            }
        }
    }
    
    private func addSubject() {
        let trimmed = newSubjectName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !studySubjects.contains(trimmed) else { return }
        studySubjects = studySubjects + [trimmed]
        newSubjectName = ""
    }

    // MARK: — Notifications
    private var notificationsSection: some View {
        SettingsSection(title: "Notifications", icon: "bell.fill", accentColor: .pulsarPurple) {
            VStack(spacing: Spacing.md) {
                Toggle(isOn: $viewModel.notificationsEnabled.animation()) {
                    HStack(spacing: Spacing.sm) {
                        Text("Enable Reminders")
                            .font(.starBody())
                            .foregroundStyle(Color.starWhite)
                    }
                }
                .tint(Color.pulsarPurple)
                .onChange(of: viewModel.notificationsEnabled) { _, _ in
                    Task { await viewModel.saveNotificationSettings() }
                }

                if viewModel.notificationsEnabled {
                    Divider().background(Color.surfaceBorder)

                    DatePicker(
                        "Daily Reminder",
                        selection: $viewModel.reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .font(.starBody())
                    .foregroundStyle(Color.starWhite)
                    .datePickerStyle(.compact)
                    .colorScheme(.dark)
                    .onChange(of: viewModel.reminderTime) { _, _ in
                        Task { await viewModel.saveNotificationSettings() }
                    }
                }
            }
        }
    }

    // MARK: — App Info
    private var appInfoSection: some View {
        SettingsSection(title: "About", icon: "info.circle.fill", accentColor: .moonGray) {
            VStack(spacing: Spacing.sm) {
                infoRow(label: "App", value: "Orion")
                infoRow(label: "Version", value: "1.0.0")
                infoRow(label: "Theme", value: "Deep Space")
                infoRow(label: "Built with", value: "SwiftUI + SwiftData")
            }
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.starBody())
                .foregroundStyle(Color.moonGray)
            Spacer()
            Text(value)
                .font(.starBody())
                .foregroundStyle(Color.starWhite)
        }
    }
}

// MARK: — Settings Section Helper
private struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let accentColor: Color
    let content: Content

    init(title: String, icon: String, accentColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.accentColor = accentColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(accentColor)
                Text(title)
                    .font(.orbitHeading())
                    .foregroundStyle(Color.starWhite)
            }

            NebulaCardView { content }
        }
    }
}
