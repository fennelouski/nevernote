//
//  FeatureFlagLaunchOverrides.swift
//  NeverNote
//

import Foundation

enum FeatureFlagLaunchOverrides {
    private static let enablePrefix = "--ff-"
    private static let disablePrefix = "--no-ff-"
    private static let enableAll = "--ff-all"
    private static let disableAll = "--no-ff-all"
    static let showFeatureFlagsPanel = "--show-feature-flags"

    static func parse(from arguments: [String] = ProcessInfo.processInfo.arguments) -> [FeatureFlag: Bool] {
        var overrides: [FeatureFlag: Bool] = [:]

        if arguments.contains(enableAll) {
            for flag in FeatureFlag.allCases {
                overrides[flag] = true
            }
        }
        if arguments.contains(disableAll) {
            for flag in FeatureFlag.allCases {
                overrides[flag] = false
            }
        }

        for argument in arguments {
            if argument == enableAll || argument == disableAll || argument == showFeatureFlagsPanel {
                continue
            }
            if argument.hasPrefix(enablePrefix) {
                let id = String(argument.dropFirst(enablePrefix.count))
                apply(id: id, enabled: true, into: &overrides)
            } else if argument.hasPrefix(disablePrefix) {
                let id = String(argument.dropFirst(disablePrefix.count))
                apply(id: id, enabled: false, into: &overrides)
            }
        }

        return overrides
    }

    static var shouldShowFeatureFlagsPanel: Bool {
        ProcessInfo.processInfo.arguments.contains(showFeatureFlagsPanel)
    }

    private static func apply(id: String, enabled: Bool, into overrides: inout [FeatureFlag: Bool]) {
        guard let flag = FeatureFlag.matching(rawValue: id) else { return }
        overrides[flag] = enabled
    }
}
