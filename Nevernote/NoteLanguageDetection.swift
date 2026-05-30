//
//  NoteLanguageDetection.swift
//  NeverNote
//

import Foundation
import NaturalLanguage

enum NoteLanguageDetection {
    private static let minimumConfidence: Double = 0.5

    struct Result {
        var language: Locale.Language
        var languageCode: String
        var confidence: Double
        /// BCP-47 identifier for source flag display (may infer region from preferred languages).
        var sourceLocaleIdentifier: String
    }

    static func detectDominantLanguage(in text: String) -> Result? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(trimmed)

        guard let dominant = recognizer.dominantLanguage,
              dominant != .undetermined else {
            return nil
        }

        let hypotheses = recognizer.languageHypotheses(withMaximum: 1)
        let confidence = hypotheses[dominant] ?? 0
        guard confidence >= minimumConfidence else { return nil }

        guard let code = NoteTranslationEligibility.normalizedLanguageCode(from: dominant.rawValue) else {
            return nil
        }

        return Result(
            language: Locale.Language(identifier: dominant.rawValue),
            languageCode: code,
            confidence: confidence,
            sourceLocaleIdentifier: NoteLocaleFlagEmoji.resolveSourceLocaleIdentifier(
                languageCode: code,
                detectedIdentifier: dominant.rawValue
            )
        )
    }
}
