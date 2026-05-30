//
//  FeatureFlagsDebugSheet.swift
//  NeverNote
//

#if DEBUG
import SwiftUI

struct FeatureFlagsDebugSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var featureFlags: FeatureFlags

    var body: some View {
        NavigationStack {
            Group {
                if FeatureFlag.allCases.isEmpty {
                    ContentUnavailableView(
                        "No Feature Flags",
                        systemImage: "flag",
                        description: Text("Add cases to FeatureFlag when gating features.")
                    )
                } else {
                    List {
                        ForEach(FeatureFlag.allCases) { flag in
                            flagRow(flag)
                        }
                    }
                }
            }
            .navigationTitle("Feature Flags")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Reset All") {
                        featureFlags.resetAllDebugOverrides()
                    }
                    .disabled(FeatureFlag.allCases.isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    private func flagRow(_ flag: FeatureFlag) -> some View {
        let source = featureFlags.overrideSource(for: flag)
        let effective = featureFlags.isEnabled(flag)
        let stored = featureFlags.storedOverride(for: flag)

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(flag.displayName)
                    .font(.headline)
                Spacer()
                Text(effective ? "On" : "Off")
                    .font(.subheadline.monospaced())
                    .foregroundStyle(effective ? .green : .secondary)
            }

            Text(flag.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Source: \(source.rawValue) · Default: \(flag.defaultEnabled ? "on" : "off")")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Picker("Override", selection: overrideBinding(for: flag, stored: stored)) {
                Text("Use default").tag(Optional<Bool>.none)
                Text("Force on").tag(Optional(true))
                Text("Force off").tag(Optional(false))
            }
            .pickerStyle(.segmented)
            .disabled(source == .launch)
        }
        .padding(.vertical, 4)
    }

    private func overrideBinding(for flag: FeatureFlag, stored: Bool?) -> Binding<Bool?> {
        Binding(
            get: { stored },
            set: { newValue in
                featureFlags.setOverride(flag, enabled: newValue)
            }
        )
    }
}
#endif
