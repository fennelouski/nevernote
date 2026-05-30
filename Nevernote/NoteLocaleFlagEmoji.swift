//
//  NoteLocaleFlagEmoji.swift
//  NeverNote
//

import Foundation

enum NoteLocaleFlagEmoji {
    static let displayFallbackEmoji = "🌐"

    /// ISO 3166-1 alpha-2 region code → flag emoji (regional indicator symbols).
    static func flagEmoji(regionCode: String) -> String? {
        let upper = regionCode.uppercased()
        guard upper.count == 2,
              upper.unicodeScalars.allSatisfy({ CharacterSet.uppercaseLetters.contains($0) }) else {
            return nil
        }
        let base: UInt32 = 127_397 // U+1F1E6 - ASCII 'A'
        var scalars: [Unicode.Scalar] = []
        scalars.reserveCapacity(2)
        for scalar in upper.unicodeScalars {
            guard let flagScalar = Unicode.Scalar(base + scalar.value) else { return nil }
            scalars.append(flagScalar)
        }
        return String(String.UnicodeScalarView(scalars))
    }

    static func flagEmoji(forLocaleIdentifier identifier: String) -> String? {
        let normalized = normalizeIdentifier(identifier)
        if let region = regionCode(fromIdentifier: normalized) {
            return flagEmoji(regionCode: region)
        }
        return nil
    }

    static func flagEmoji(for language: Locale.Language) -> String? {
        if let region = language.region?.identifier {
            return flagEmoji(regionCode: region)
        }
        return flagEmoji(forLocaleIdentifier: language.maximalIdentifier)
    }

    /// Best BCP-47 identifier for source-note flag display when detection is language-only.
    static func resolveSourceLocaleIdentifier(
        languageCode: String,
        detectedIdentifier: String? = nil,
        preferredLanguageIdentifiers: [String] = Locale.preferredLanguages
    ) -> String {
        let code = languageCode.lowercased()
        if let detectedIdentifier {
            let normalized = normalizeIdentifier(detectedIdentifier)
            if regionCode(fromIdentifier: normalized) != nil {
                return normalized
            }
        }

        for preferred in preferredLanguageIdentifiers {
            guard let preferredCode = NoteTranslationEligibility.normalizedLanguageCode(from: preferred),
                  preferredCode == code else { continue }
            let normalized = normalizeIdentifier(preferred)
            if regionCode(fromIdentifier: normalized) != nil {
                return normalized
            }
        }

        if let scriptRegion = resolveChineseScriptRegion(
            languageCode: code,
            detectedIdentifier: detectedIdentifier,
            preferredLanguageIdentifiers: preferredLanguageIdentifiers
        ) {
            return scriptRegion
        }

        if code == "pt" {
            if let preferred = preferredPortugueseIdentifier(from: preferredLanguageIdentifiers) {
                return preferred
            }
            return "pt-BR"
        }

        if let region = defaultRegionByLanguageCode[code] {
            return "\(code)-\(region)"
        }

        return detectedIdentifier.map(normalizeIdentifier) ?? code
    }

    static func localizedLocaleDescription(forIdentifier identifier: String, in locale: Locale = .current) -> String {
        let normalized = normalizeIdentifier(identifier)
        let language = Locale.Language(identifier: normalized)
        let languageCode = language.languageCode?.identifier
            ?? NoteTranslationEligibility.normalizedLanguageCode(from: normalized)
            ?? normalized

        let languageName = locale.localizedString(forLanguageCode: languageCode) ?? languageCode

        if let region = language.region?.identifier ?? regionCode(fromIdentifier: normalized),
           let regionName = locale.localizedString(forRegionCode: region),
           !regionName.isEmpty {
            return "\(languageName) (\(regionName))"
        }
        return languageName
    }

    static func accessibilityLabel(
        sourceIdentifier: String,
        targetIdentifier: String,
        in locale: Locale = .current
    ) -> String {
        let source = localizedLocaleDescription(forIdentifier: sourceIdentifier, in: locale)
        let target = localizedLocaleDescription(forIdentifier: targetIdentifier, in: locale)
        return String(
            format: String(localized: "Translate note from %1$@ to %2$@"),
            locale: locale,
            source,
            target
        )
    }

    // MARK: - Region parsing

    private static func normalizeIdentifier(_ identifier: String) -> String {
        identifier.replacingOccurrences(of: "_", with: "-")
    }

    private static func regionCode(fromIdentifier identifier: String) -> String? {
        let language = Locale.Language(identifier: identifier)
        if let region = language.region?.identifier, !region.isEmpty {
            return region.uppercased()
        }
        let locale = Locale(identifier: identifier)
        if let region = locale.region?.identifier, !region.isEmpty {
            return region.uppercased()
        }
        return nil
    }

    // MARK: - Chinese script + region

    private static func resolveChineseScriptRegion(
        languageCode: String,
        detectedIdentifier: String?,
        preferredLanguageIdentifiers: [String]
    ) -> String? {
        guard languageCode == "zh" || detectedIdentifier?.lowercased().contains("zh") == true else {
            return nil
        }

        let detectedScript = scriptSubtag(from: detectedIdentifier)

        for preferred in preferredLanguageIdentifiers {
            let normalized = normalizeIdentifier(preferred)
            guard NoteTranslationEligibility.normalizedLanguageCode(from: normalized) == "zh" else { continue }
            if let detectedScript {
                let preferredScript = scriptSubtag(from: normalized)
                if preferredScript != detectedScript { continue }
            }
            if regionCode(fromIdentifier: normalized) != nil {
                return normalized
            }
        }

        if detectedScript == "Hant" {
            return "zh-Hant-TW"
        }
        if detectedScript == "Hans" {
            return "zh-Hans-CN"
        }
        return "zh-Hans-CN"
    }

    private static func scriptSubtag(from identifier: String?) -> String? {
        guard let identifier else { return nil }
        let parts = normalizeIdentifier(identifier).split(separator: "-").map(String.init)
        for part in parts.dropFirst() {
            if part.count == 4, part.first?.isLowercase == true {
                return part.prefix(1).uppercased() + part.dropFirst()
            }
        }
        return nil
    }

    // MARK: - Portuguese

    private static func preferredPortugueseIdentifier(from preferred: [String]) -> String? {
        for identifier in preferred {
            let normalized = normalizeIdentifier(identifier)
            guard NoteTranslationEligibility.normalizedLanguageCode(from: normalized) == "pt" else { continue }
            if regionCode(fromIdentifier: normalized) != nil {
                return normalized
            }
        }
        return nil
    }

    /// Default ISO region when language-only and preferred list has no regional match.
    /// English defaults to US (not GB) unless the user's preferred list includes en-GB.
    private static let defaultRegionByLanguageCode: [String: String] = [
        "en": "US",
        "es": "ES",
        "pt": "BR",
        "zh": "CN",
        "ar": "SA",
        "fr": "FR",
        "de": "DE",
        "it": "IT",
        "ja": "JP",
        "ko": "KR",
        "nl": "NL",
        "ru": "RU",
        "hi": "IN",
    ]
}
