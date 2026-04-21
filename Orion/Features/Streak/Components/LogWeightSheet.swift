// LogWeightSheet.swift — Features/Streak/Components
import SwiftUI

struct LogWeightSheet: View {
    @Bindable var viewModel: StreakViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var weight: Double = 70.0
    @State private var notes: String = ""
    @State private var isSaving: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.nebulaDeep.ignoresSafeArea()
                
                VStack(spacing: Spacing.xl) {
                    VStack(spacing: Spacing.sm) {
                        Text("Current Weight")
                            .font(.moonCaption())
                            .foregroundStyle(Color.moonGray)
                        
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                            Text(String(format: "%.1f", weight))
                                .font(.cosmicTitle(48))
                                .foregroundStyle(Color.starWhite)
                            Text(viewModel.weightUnit)
                                .font(.orbitHeading())
                                .foregroundStyle(Color.moonGray)
                        }
                    }
                    .padding(.top, Spacing.xl)
                    
                    VStack(spacing: Spacing.lg) {
                        // Custom numeric input simulation with a slider for now
                        // (iOS 17 TextField with format is also an option)
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                Text("Adjust Weight")
                                    .font(.starBody())
                                    .foregroundStyle(Color.starWhite)
                                Spacer()
                                Button {
                                    weight -= 0.1
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(Color.moonGray)
                                }
                                Button {
                                    weight += 0.1
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(Color.auroraTeal)
                                }
                            }
                            
                            Slider(value: $weight, in: 30...200, step: 0.1)
                                .tint(Color.auroraTeal)
                        }
                        .padding(Spacing.md)
                        .background(Color.nebulaCard)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                        
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Notes (optional)")
                                .font(.moonCaption())
                                .foregroundStyle(Color.moonGray)
                            TextEditor(text: $notes)
                                .scrollContentBackground(.hidden)
                                .font(.starBody())
                                .foregroundStyle(Color.starWhite)
                                .padding(Spacing.sm)
                                .background(Color.nebulaCard)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                                .frame(height: 100)
                        }
                    }
                    
                    Spacer()
                    
                    PulsingStarButton(
                        title: "Save Weight",
                        systemImage: "checkmark.circle.fill",
                        gradient: .auroraGradient,
                        action: {
                            Task {
                                isSaving = true
                                await viewModel.logWeight(weight, notes: notes.isEmpty ? nil : notes)
                                isSaving = false
                                dismiss()
                            }
                        },
                        isLoading: isSaving
                    )
                }
                .padding(Spacing.lg)
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.moonGray)
                }
            }
            .onAppear {
                if let latest = viewModel.latestWeight {
                    weight = latest.weightKg
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Color.nebulaDeep)
    }
}
