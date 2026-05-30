//
//  FeatureFlags.swift
//  NeverNote
//

import Foundation
import Observation

@Observable
final class FeatureFlags {
    enum OverrideSource: String {
        case launch
        case debugStorage
        case `default`
    }

    private let launchOverrides: [FeatureFlag: Bool]
    private let defaults: UserDefaults

    init(
        launchOverrides: [FeatureFlag: Bool] = FeatureFlagLaunchOverrides.parse(),
        defaults: UserDefaults = .standard
    ) {
        self.launchOverrides = launchOverrides
        self.defaults = defaults
    }

    func isEnabled(_ flag: FeatureFlag) -> Bool {
        if let launchValue = launchOverrides[flag] {
            return launchValue
        }
        #if DEBUG
        if let stored = storedOverride(for: flag) {
            return stored
        }
        #endif
        return flag.defaultEnabled
    }

    #if DEBUG
    func setOverride(_ flag: FeatureFlag, enabled: Bool?) {
        let key = Self.storageKey(for: flag)
        if let enabled {
            defaults.set(enabled, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    func storedOverride(for flag: FeatureFlag) -> Bool? {
        let key = Self.storageKey(for: flag)
        guard defaults.object(forKey: key) != nil else { return nil }
        return defaults.bool(forKey: key)
    }

    func overrideSource(for flag: FeatureFlag) -> OverrideSource {
        if launchOverrides[flag] != nil {
            return .launch
        }
        if storedOverride(for: flag) != nil {
            return .debugStorage
        }
        return .default
    }

    func resetAllDebugOverrides() {
        for flag in FeatureFlag.allCases {
            defaults.removeObject(forKey: Self.storageKey(for: flag))
        }
    }
    #endif

    private static func storageKey(for flag: FeatureFlag) -> String {
        "nevernote.featureFlag.\(flag.rawValue)"
    }
}
