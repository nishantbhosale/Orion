// GymLogView.swift — Features/Gym

import SwiftUI
import SwiftData

struct GymLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(RestTimerManager.self) private var restTimer
    @State private var viewModel: GymViewModel

    @Query(sort: \GymSession.createdAt, order: .reverse)
    private var allSessions: [GymSession]

    private var todaySessions: [GymSession] {
        allSessions.filter { DateHelper.isToday($0.date) }
    }

    init(gymRepository: GymRepository, streakUseCase: StreakUseCase, modelContext: ModelContext) {
        _viewModel = State(initialValue: GymViewModel(
            gymRepository: gymRepository,
            streakUseCase: streakUseCase,
            templateRepository: WorkoutTemplateRepository(modelContext: modelContext),
            prRepository: PRLogRepository(modelContext: modelContext)
        ))
    }

    var body: some View {
        ZStack {
            StarFieldView().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.lg) {
                    screenHeader
                    workoutTypeSelector
                    exerciseSection
                    durationSection
                    notesField

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.moonCaption())
                            .foregroundStyle(Color.novaOrange)
                    }

                    PulsingStarButton(
                        title: "Log Gym Session",
                        systemImage: "plus.circle.fill",
                        gradient: .novaGradient,
                        action: { Task { await viewModel.logSession() } },
                        isLoading: viewModel.isLogging
                    )

                    todayGymLog
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }

            // Floating overlay for rest timer
            RestTimerOverlay()
        }
        .navigationTitle("Gym")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $viewModel.showExerciseSheet) {
            AddExerciseSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showTemplateSheet) {
            TemplatePickerSheet(viewModel: viewModel)
        }
        .alert("Save as Template", isPresented: $viewModel.showSaveTemplateAlert) {
            TextField("Template name", text: $viewModel.newTemplateName)
            Button("Save") { viewModel.saveCurrentAsTemplate() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Give this workout a name to save it as a reusable template.")
        }
        .shootingStarToast(message: viewModel.toastMessage, isShowing: $viewModel.showToast)
        .onDisappear { viewModel.onDisappear() }
    }

    // MARK: — Header
    private var screenHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Gym Session")
                    .font(.cosmicTitle(26))
                    .foregroundStyle(Color.starWhite)
                Text(formattedToday)
                    .font(.moonCaption())
                    .foregroundStyle(Color.moonGray)
            }
            Spacer()
            HStack(spacing: Spacing.md) {
                // Load template
                Button {
                    HapticManager.impact(.light)
                    viewModel.showTemplateSheet = true
                } label: {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.auroraTeal)
                }
                .accessibilityLabel("Load workout template")

                // Save as template
                Button {
                    HapticManager.impact(.light)
                    viewModel.showSaveTemplateAlert = true
                } label: {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(viewModel.exercises.isEmpty ? Color.moonGray.opacity(0.4) : Color.novaOrange)
                }
                .disabled(viewModel.exercises.isEmpty)
                .accessibilityLabel("Save workout as template")

                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.novaOrange)
                    .shadow(color: Color.novaOrange.opacity(0.6), radius: 8)
            }
        }
        .padding(.top, Spacing.sm)
    }

    // MARK: — Workout Type Selector
    private var workoutTypeSelector: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Workout Type")
                .font(.moonCaption())
                .foregroundStyle(Color.moonGray)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(GymWorkoutType.allCases) { type in
                        Button {
                            HapticManager.selection()
                            withAnimation(OrionAnimation.tabSwitch) {
                                viewModel.selectedWorkoutType = type
                            }
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: type.systemImage)
                                    .font(.system(size: 13))
                                Text(type.displayName)
                                    .font(.moonCaption(13))
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm + 2)
                            .background(
                                Capsule()
                                    .fill(viewModel.selectedWorkoutType == type
                                        ? type.accentColor.opacity(0.25)
                                        : Color.nebulaCard)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(
                                                viewModel.selectedWorkoutType == type ? type.accentColor : Color.surfaceBorder,
                                                lineWidth: viewModel.selectedWorkoutType == type ? 1.5 : 1
                                            )
                                    )
                            )
                            .foregroundStyle(viewModel.selectedWorkoutType == type ? type.accentColor : Color.moonGray)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(type.displayName)
                        .accessibilityAddTraits(viewModel.selectedWorkoutType == type ? [.isSelected, .isButton] : .isButton)
                    }
                }
                .padding(.horizontal, Spacing.xs)
            }
        }
    }

    // MARK: — Exercise Section
    private var exerciseSection: some View {
        NebulaCardView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Label("Exercises", systemImage: "list.bullet.clipboard")
                        .font(.orbitHeading(16))
                        .foregroundStyle(Color.starWhite)
                    Spacer()
                    Button {
                        HapticManager.impact(.light)
                        viewModel.showExerciseSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add")
                        }
                        .font(.moonCaption(13))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.novaOrange)
                    }
                    .accessibilityLabel("Add exercise")
                }

                if viewModel.exercises.isEmpty {
                    Text("No exercises added yet")
                        .font(.starBody())
                        .foregroundStyle(Color.moonGray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, Spacing.md)
                } else {
                    ForEach(viewModel.exercises) { exercise in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name)
                                    .font(.starBody())
                                    .foregroundStyle(Color.starWhite)
                                HStack(spacing: Spacing.xs) {
                                    Text(exercise.summary)
                                        .font(.moonCaption())
                                        .foregroundStyle(Color.moonGray)
                                    if let rmLabel = viewModel.prGainLabel(for: exercise) {
                                        Text(rmLabel)
                                            .font(.moonCaption(11))
                                            .fontWeight(.semibold)
                                            .foregroundStyle(Color.streakGold)
                                    } else if let rm = viewModel.live1RM(for: exercise) {
                                        Text("~\(String(format: "%.0f", rm))kg 1RM")
                                            .font(.moonCaption(11))
                                            .foregroundStyle(Color.dustGray)
                                    }
                                }
                            }
                            Spacer()
                            
                            // Overload Badge
                            let delta = viewModel.overloadDelta(for: exercise)
                            HStack(spacing: 4) {
                                Image(systemName: delta.icon)
                                if case .improved(let label) = delta {
                                    Text(label)
                                }
                            }
                            .font(.moonCaption(10))
                            .fontWeight(.bold)
                            .foregroundStyle(delta.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(delta.color.opacity(0.15))
                            .clipShape(Capsule())

                            StartRestTimerButton(seconds: exercise.restSeconds)
                            
                            Button {
                                withAnimation { viewModel.removeExercise(exercise) }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color.moonGray.opacity(0.6))
                            }
                            .accessibilityLabel("Remove \(exercise.name)")
                        }
                        .padding(.vertical, Spacing.xs)

                        if exercise.id != viewModel.exercises.last?.id {
                            Divider().background(Color.surfaceBorder)
                        }
                    }
                }
            }
        }
    }

    // MARK: — Duration Section
    private var durationSection: some View {
        NebulaCardView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Label("Duration", systemImage: "timer")
                        .font(.moonCaption())
                        .foregroundStyle(Color.moonGray)
                    Spacer()
                    Toggle("Timer Mode", isOn: $viewModel.useTimer.animation())
                        .labelsHidden()
                        .tint(Color.novaOrange)
                    Text("Timer")
                        .font(.moonCaption())
                        .foregroundStyle(Color.moonGray)
                }

                if viewModel.useTimer {
                    HStack {
                        Spacer()
                        VStack(spacing: Spacing.md) {
                            ZStack {
                                Circle()
                                    .stroke(Color.novaOrange.opacity(0.2), lineWidth: 6)
                                    .frame(width: 88, height: 88)
                                if viewModel.timerRunning {
                                    Circle()
                                        .trim(from: 0, to: CGFloat(viewModel.timerSeconds % 60) / 60.0)
                                        .stroke(Color.novaOrange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                        .rotationEffect(.degrees(-90))
                                        .frame(width: 88, height: 88)
                                        .animation(.linear(duration: 1), value: viewModel.timerSeconds)
                                }
                                Text(viewModel.timerDisplay)
                                    .font(.monoData(22))
                                    .foregroundStyle(Color.starWhite)
                            }

                            Button {
                                HapticManager.impact(.medium)
                                viewModel.timerRunning ? viewModel.stopTimer() : viewModel.startTimer()
                            } label: {
                                Label(
                                    viewModel.timerRunning ? "Stop" : "Start",
                                    systemImage: viewModel.timerRunning ? "stop.circle.fill" : "play.circle.fill"
                                )
                                .font(.orbitHeading())
                                .foregroundStyle(viewModel.timerRunning ? Color.novaOrange : Color.auroraTeal)
                            }
                        }
                        Spacer()
                    }
                } else {
                    HStack(spacing: Spacing.sm) {
                        Picker("Hours", selection: $viewModel.hours) {
                            ForEach(0..<5) { Text("\($0)h").tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 80)
                        .clipped()

                        Picker("Minutes", selection: $viewModel.minutes) {
                            ForEach(0..<60) { Text("\($0)m").tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 80)
                        .clipped()
                    }
                    .tint(Color.novaOrange)
                }
            }
        }
    }

    // MARK: — Notes
    private var notesField: some View {
        NebulaCardView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("Notes / RPE (optional)", systemImage: "note.text")
                    .font(.moonCaption())
                    .foregroundStyle(Color.moonGray)
                TextEditor(text: $viewModel.notes)
                    .scrollContentBackground(.hidden)
                    .font(.starBody())
                    .foregroundStyle(Color.starWhite)
                    .frame(minHeight: 70)
            }
        }
    }

    // MARK: — Today's Gym Log
    private var todayGymLog: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Today's Gym Log")
                .font(.orbitHeading())
                .foregroundStyle(Color.starWhite)

            if todaySessions.isEmpty {
                EmptyStateView(
                    systemImage: "dumbbell.fill",
                    title: "No workout today",
                    subtitle: "Log your gym session above to track your progress",
                    accentColor: .novaOrange
                )
            } else {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(todaySessions) { session in
                        GymSessionCard(session: session)
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

    private var formattedToday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: .now)
    }
}

// MARK: — Gym Session Card
struct GymSessionCard: View {
    let session: GymSession

    var body: some View {
        NebulaCardView(accentColor: session.workoutType.accentColor, showAccentLine: true) {
            HStack(spacing: Spacing.md) {
                Image(systemName: session.workoutType.systemImage)
                    .font(.system(size: 20))
                    .foregroundStyle(session.workoutType.accentColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.workoutType.displayName)
                        .font(.starBody())
                        .foregroundStyle(Color.starWhite)

                    if !session.exercisesSummary.isEmpty {
                        Text(session.exercisesSummary)
                            .font(.moonCaption())
                            .foregroundStyle(Color.moonGray)
                            .lineLimit(2)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    DurationBadge(duration: session.formattedDuration, color: .novaOrange)
                    Text(DateHelper.shortTime(session.createdAt))
                        .font(.moonCaption(11))
                        .foregroundStyle(Color.dustGray)
                }
            }
        }
    }
}

// MARK: — Add Exercise Bottom Sheet
struct AddExerciseSheet: View {
    @Bindable var viewModel: GymViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.nebulaDeep.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Exercise name with suggestions
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Exercise Name")
                                .font(.moonCaption())
                                .foregroundStyle(Color.moonGray)

                            TextField("e.g. Bench Press", text: $viewModel.newExerciseName)
                                .font(.starBody())
                                .foregroundStyle(Color.starWhite)
                                .padding(Spacing.md)
                                .background(Color.nebulaCard)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                                .autocorrectionDisabled()
                                .onChange(of: viewModel.newExerciseName) {
                                    if let suggestion = viewModel.suggestMuscleGroup(for: viewModel.newExerciseName) {
                                        viewModel.newExerciseMuscleGroup = suggestion
                                    }
                                }

                        }

                        // Muscle Group Selection
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Muscle Group")
                                .font(.moonCaption())
                                .foregroundStyle(Color.moonGray)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.sm) {
                                    ForEach(MuscleGroup.allCases, id: \.self) { group in
                                        Button {
                                            viewModel.newExerciseMuscleGroup = group
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: group.systemImage)
                                                Text(group.displayName)
                                            }
                                            .font(.moonCaption(13))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(viewModel.newExerciseMuscleGroup == group ? Color.novaOrange.opacity(0.2) : Color.nebulaCard)
                                            .foregroundStyle(viewModel.newExerciseMuscleGroup == group ? Color.novaOrange : Color.moonGray)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .strokeBorder(viewModel.newExerciseMuscleGroup == group ? Color.novaOrange.opacity(0.5) : Color.surfaceBorder, lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // Timed vs Reps toggle
                        Toggle("Timed Exercise", isOn: $viewModel.newExerciseIsTimed)
                            .tint(Color.novaOrange)
                            .font(.starBody())
                            .foregroundStyle(Color.starWhite)

                        // Sets
                        stepperRow(label: "Sets", value: $viewModel.newExerciseSets, range: 1...20)

                        if viewModel.newExerciseIsTimed {
                            // Duration in seconds
                            stepperRow(label: "Duration (seconds)", value: $viewModel.newExerciseDurationSeconds, range: 10...600, step: 10)
                        } else {
                            // Reps
                            stepperRow(label: "Reps", value: $viewModel.newExerciseReps, range: 1...50)
                            
                            // Rest Timer
                            stepperRow(label: "Rest Timer (sec)", value: $viewModel.newExerciseRestSeconds, range: 30...300, step: 15)
                        }

                        // Weight
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Weight (kg) — optional")
                                .font(.moonCaption())
                                .foregroundStyle(Color.moonGray)
                            HStack {
                                Slider(value: $viewModel.newExerciseWeightKg, in: 0...300, step: 2.5)
                                    .tint(Color.novaOrange)
                                Text("\(String(format: "%.1f", viewModel.newExerciseWeightKg))kg")
                                    .font(.monoData())
                                    .foregroundStyle(Color.starWhite)
                                    .frame(width: 60)
                            }
                        }

                        PulsingStarButton(
                            title: "Add Exercise",
                            systemImage: "plus.circle.fill",
                            gradient: .novaGradient,
                            action: { viewModel.addExercise() }
                        )
                    }
                    .padding(Spacing.lg)
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.moonGray)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Color.nebulaDeep)
    }

    private func stepperRow(label: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int = 1) -> some View {
        HStack {
            Text(label)
                .font(.starBody())
                .foregroundStyle(Color.starWhite)
            Spacer()
            HStack(spacing: Spacing.md) {
                Button {
                    if value.wrappedValue - step >= range.lowerBound {
                        value.wrappedValue -= step
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.moonGray)
                }
                .accessibilityLabel("Decrease \(label)")

                Text("\(value.wrappedValue)")
                    .font(.monoData(18))
                    .foregroundStyle(Color.starWhite)
                    .frame(minWidth: 36)

                Button {
                    if value.wrappedValue + step <= range.upperBound {
                        value.wrappedValue += step
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.novaOrange)
                }
                .accessibilityLabel("Increase \(label)")
            }
        }
    }
}
