// TemplatePickerSheet.swift — Features/Gym/Components
import SwiftUI

struct TemplatePickerSheet: View {
    @Bindable var viewModel: GymViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.nebulaDeep.ignoresSafeArea()

                if viewModel.availableTemplates.isEmpty {
                    VStack(spacing: Spacing.lg) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.moonGray.opacity(0.5))
                        Text("No Templates Yet")
                            .font(.orbitHeading())
                            .foregroundStyle(Color.starWhite)
                        Text("Save your current workout as a template by tapping the bookmark icon.")
                            .font(.starBody())
                            .foregroundStyle(Color.moonGray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xl)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.availableTemplates) { template in
                            Button {
                                HapticManager.impact(.light)
                                viewModel.loadTemplate(template)
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(template.name)
                                            .font(.orbitHeading(16))
                                            .foregroundStyle(Color.starWhite)
                                        Text("\(template.exercises.count) exercises · \(template.workoutType.displayName)")
                                            .font(.moonCaption())
                                            .foregroundStyle(Color.moonGray)
                                        if let used = template.lastUsedAt {
                                            Text("Last used: \(DateHelper.shortDate(used))")
                                                .font(.moonCaption(11))
                                                .foregroundStyle(Color.dustGray)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.moonCaption())
                                        .foregroundStyle(Color.moonGray)
                                }
                                .padding(.vertical, Spacing.xs)
                            }
                            .listRowBackground(Color.nebulaCard)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteTemplate(template)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Workout Templates")
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
}
