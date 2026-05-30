//
//  NoteOnDeviceTranslationIOS18.swift
//  NeverNote
//

import Foundation
import Translation

@available(iOS 18.0, macOS 15.0, *)
enum NoteOnDeviceTranslationIOS18 {
    static func resolveTargetLanguage(
        detected: NoteLanguageDetection.Result,
        preferredLanguageIdentifiers: [String] = Locale.preferredLanguages
    ) async -> NoteOnDeviceTranslation.TargetResolution {
        let detectedCode = detected.languageCode
        let availability = LanguageAvailability()

        for identifier in preferredLanguageIdentifiers {
            guard let preferredCode = NoteTranslationEligibility.normalizedLanguageCode(from: identifier) else {
                continue
            }
            guard preferredCode != detectedCode else { continue }

            let target = Locale.Language(identifier: identifier)
            let status = await availability.status(from: detected.language, to: target)
            switch status {
            case .installed, .supported:
                return .resolved(target, localeIdentifier: identifier)
            case .unsupported:
                continue
            @unknown default:
                continue
            }
        }

        return .unavailable
    }
}
