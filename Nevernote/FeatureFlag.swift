//
//  FeatureFlag.swift
//  NeverNote
//

import Foundation

/// Typed catalog of product feature flags.
///
/// Add a `case` when gating a feature, set `defaultEnabled`, then call
/// `featureFlags.isEnabled(.yourFlag)` from SwiftUI or services.
///
/// User-facing preferences belong in `@AppStorage`, not here.
enum FeatureFlag: CaseIterable, Identifiable, Hashable {
    case onDeviceNoteTranslation

    var id: String { rawValue }

    var rawValue: String {
        switch self {
        case .onDeviceNoteTranslation:
            return "on-device-note-translation"
        }
    }

    var displayName: String {
        switch self {
        case .onDeviceNoteTranslation:
            return "On-device note translation"
        }
    }

    var defaultEnabled: Bool {
        switch self {
        case .onDeviceNoteTranslation:
            return true
        }
    }
}

extension FeatureFlag {
    static func matching(rawValue: String) -> FeatureFlag? {
        allCases.first { $0.rawValue == rawValue }
    }
}
