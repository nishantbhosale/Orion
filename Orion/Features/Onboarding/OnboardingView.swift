// OnboardingView.swift — Features/Onboarding
// Shown on first launch — collects user name and reminder time

import SwiftUI

struct OnboardingView: View {
    @AppStorage(UserPreferencesKey.hasOnboarded)    private var hasOnboarded: Bool = false
    @AppStorage(UserPreferencesKey.userName)         private var userName: String = ""
    @AppStorage(UserPreferencesKey.dailyReminderHour) private var reminderHour: Int = UserPreferencesKey.defaultReminderHour
    @AppStorage(UserPreferencesKey.dailyReminderMinute) private var reminderMinute: Int = UserPreferencesKey.defaultReminderMinute

    @State private var nameInput: String = ""
    @State private var reminderTime: Date = {
        var components = DateComponents()
        components.hour = UserPreferencesKey.defaultReminderHour
        components.minute = UserPreferencesKey.defaultReminderMinute
        return Calendar.current.date(from: components) ?? .now
    }()
    @State private var appeared = false

    var body: some View {
        ZStack {
            StarFieldView().ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo + Welcome
                VStack(spacing: Spacing.lg) {
                    ConstellationLogoView()
                        .frame(width: 80, height: 80)
                        .scaleEffect(appeared ? 1.0 : 0.5)
                        .opacity(appeared ? 1.0 : 0)

                    VStack(spacing: Spacing.sm) {
                        Text("Welcome to Orion")
                            .font(.cosmicTitle())
                            .foregroundStyle(Color.starWhite)
                            .opacity(appeared ? 1.0 : 0)
                            .offset(y: appeared ? 0 : 20)

                        Text("Track your study and gym habits\namong the stars")
                            .font(.starBody())
                            .foregroundStyle(Color.moonGray)
                            .multilineTextAlignment(.center)
                            .opacity(appeared ? 1.0 : 0)
                            .offset(y: appeared ? 0 : 20)
                    }
                }

                Spacer()

                // Form
                VStack(spacing: Spacing.lg) {
                    NebulaCardView {
                        VStack(spacing: Spacing.md) {
                            // Name
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("What should we call you?")
                                    .font(.orbitHeading(16))
                                    .foregroundStyle(Color.starWhite)

                                TextField("Your name", text: $nameInput)
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
                                    .accessibilityLabel("Enter your name")
                            }

                            Divider().background(Color.surfaceBorder)

                            // Reminder Time
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Daily habit reminder")
                                    .font(.orbitHeading(16))
                                    .foregroundStyle(Color.starWhite)

                                DatePicker(
                                    "Reminder time",
                                    selection: $reminderTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .datePickerStyle(.wheel)
                                .colorScheme(.dark)
                                .frame(height: 120)
                                .clipped()
                                .accessibilityLabel("Set daily reminder time")
                            }
                        }
                    }
                    .opacity(appeared ? 1.0 : 0)
                    .offset(y: appeared ? 0 : 30)

                    PulsingStarButton(
                        title: "Begin Your Journey",
                        systemImage: "sparkles",
                        gradient: .auroraGradient,
                        action: completeOnboarding
                    )
                    .opacity(appeared ? 1.0 : 0)
                    .offset(y: appeared ? 0 : 30)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.8).delay(0.2)) {
                appeared = true
            }
        }
    }

    private func completeOnboarding() {
        // Save preferences
        let name = nameInput.trimmingCharacters(in: .whitespaces)
        userName = name.isEmpty ? "Astronaut" : name
        reminderHour   = Calendar.current.component(.hour, from: reminderTime)
        reminderMinute = Calendar.current.component(.minute, from: reminderTime)

        // Schedule daily reminder
        Task {
            await NotificationManager.shared.scheduleDailyReminder(
                hour: reminderHour,
                minute: reminderMinute
            )
        }

        HapticManager.notification(.success)

        withAnimation(.spring(duration: 0.5)) {
            hasOnboarded = true
        }
    }
}
