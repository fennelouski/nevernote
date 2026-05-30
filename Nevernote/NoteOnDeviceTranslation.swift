//
//  NoteOnDeviceTranslation.swift
//  NeverNote
//

import Foundation

enum NoteOnDeviceTranslation {
    enum TargetResolution {
        case resolved(Locale.Language, localeIdentifier: String)
        case unavailable
    }

    static var isFrameworkAvailable: Bool {
        if #available(iOS 18.0, macOS 15.0, *) {
            return true
        }
        return false
    }

    static func resolveTargetLanguage(
        detected: NoteLanguageDetection.Result,
        preferredLanguageIdentifiers: [String] = Locale.preferredLanguages
    ) async -> TargetResolution {
        guard #available(iOS 18.0, macOS 15.0, *) else {
            return .unavailable
        }
        return await NoteOnDeviceTranslationIOS18.resolveTargetLanguage(
            detected: detected,
            preferredLanguageIdentifiers: preferredLanguageIdentifiers
        )
    }

    static func prependTranslation(
        _ translatedText: String,
        to existing: NSAttributedString,
        fontToken: String,
        pointSize: CGFloat
    ) -> NSAttributedString {
        let block = translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !block.isEmpty else { return existing }

        let font = EditorFont.platformFont(forToken: fontToken, size: pointSize)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]

        let prefix = NSAttributedString(string: block + "\n\n", attributes: attributes)
        let combined = NSMutableAttributedString(attributedString: prefix)
        combined.append(existing)
        return combined
    }
}
