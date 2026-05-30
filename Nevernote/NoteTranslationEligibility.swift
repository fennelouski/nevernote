//
//  NoteTranslationEligibility.swift
//  NeverNote
//

import Foundation

enum NoteTranslationEligibility {
    /// Tokenize on whitespace; strip leading/trailing punctuation per token.
    static func meetsWordThreshold(_ text: String) -> Bool {
        let tokens = tokenize(text)
        let count3 = tokens.filter { $0.count >= 3 }.count
        if count3 >= 5 { return true }
        let count4 = tokens.filter { $0.count >= 4 }.count
        if count4 >= 3 { return true }
        if tokens.contains(where: { $0.count >= 5 }) { return true }
        return false
    }

    static func normalizedPreferredLanguageCodes(
        preferredLanguageIdentifiers: [String] = Locale.preferredLanguages
    ) -> Set<String> {
        Set(preferredLanguageIdentifiers.compactMap { normalizedLanguageCode(from: $0) })
    }

    static func isForeignLanguage(
        detectedCode: String,
        preferredLanguageIdentifiers: [String] = Locale.preferredLanguages
    ) -> Bool {
        let preferred = normalizedPreferredLanguageCodes(preferredLanguageIdentifiers: preferredLanguageIdentifiers)
        guard !preferred.isEmpty else { return true }
        return !preferred.contains(detectedCode)
    }

    static func normalizedLanguageCode(from identifier: String) -> String? {
        let locale = Locale(identifier: identifier)
        if let code = locale.language.languageCode?.identifier, !code.isEmpty {
            return code.lowercased()
        }
        let primary = identifier.split(separator: "-").first.map(String.init) ?? identifier
        let trimmed = primary.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed.lowercased()
    }

    private static func tokenize(_ text: String) -> [String] {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isWhitespace)
            .map { String($0).trimmingCharacters(in: CharacterSet.punctuationCharacters) }
            .filter { !$0.isEmpty }
    }
}
