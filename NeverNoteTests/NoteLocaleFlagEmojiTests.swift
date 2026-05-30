//
//  NoteLocaleFlagEmojiTests.swift
//  NeverNoteTests
//

import XCTest
@testable import NeverNote

final class NoteLocaleFlagEmojiTests: XCTestCase {
    func testExplicitRegionIdentifiers() {
        XCTAssertEqual(NoteLocaleFlagEmoji.flagEmoji(forLocaleIdentifier: "en-US"), "🇺🇸")
        XCTAssertEqual(NoteLocaleFlagEmoji.flagEmoji(forLocaleIdentifier: "en-GB"), "🇬🇧")
        XCTAssertEqual(NoteLocaleFlagEmoji.flagEmoji(forLocaleIdentifier: "fr-FR"), "🇫🇷")
        XCTAssertEqual(NoteLocaleFlagEmoji.flagEmoji(forLocaleIdentifier: "en_US"), "🇺🇸")
    }

    func testRegionCodeGBNotUK() {
        XCTAssertEqual(NoteLocaleFlagEmoji.flagEmoji(regionCode: "GB"), "🇬🇧")
        XCTAssertEqual(NoteLocaleFlagEmoji.flagEmoji(forLocaleIdentifier: "en-GB"), "🇬🇧")
        // ISO 3166-1 uses GB; "UK" is not a region subtag in BCP-47 locale identifiers.
        XCTAssertNotEqual(NoteLocaleFlagEmoji.flagEmoji(regionCode: "GB"), NoteLocaleFlagEmoji.flagEmoji(regionCode: "US"))
    }

    func testResolveSourceEnglishFromPreferredUS() {
        let resolved = NoteLocaleFlagEmoji.resolveSourceLocaleIdentifier(
            languageCode: "en",
            preferredLanguageIdentifiers: ["en-US", "fr-FR"]
        )
        XCTAssertEqual(NoteLocaleFlagEmoji.flagEmoji(forLocaleIdentifier: resolved), "🇺🇸")
    }

    func testResolveSourceEnglishFromPreferredGB() {
        let resolved = NoteLocaleFlagEmoji.resolveSourceLocaleIdentifier(
            languageCode: "en",
            preferredLanguageIdentifiers: ["en-GB"]
        )
        XCTAssertEqual(NoteLocaleFlagEmoji.flagEmoji(forLocaleIdentifier: resolved), "🇬🇧")
    }

    func testResolveSourceFrenchDefaultsToFrance() {
        let resolved = NoteLocaleFlagEmoji.resolveSourceLocaleIdentifier(
            languageCode: "fr",
            preferredLanguageIdentifiers: ["en-US"]
        )
        XCTAssertEqual(NoteLocaleFlagEmoji.flagEmoji(forLocaleIdentifier: resolved), "🇫🇷")
    }

    func testPortuguesePreferredPT() {
        let resolved = NoteLocaleFlagEmoji.resolveSourceLocaleIdentifier(
            languageCode: "pt",
            preferredLanguageIdentifiers: ["en-US", "pt-PT"]
        )
        XCTAssertEqual(NoteLocaleFlagEmoji.flagEmoji(forLocaleIdentifier: resolved), "🇵🇹")
    }

    func testPortugueseDefaultBrazil() {
        let resolved = NoteLocaleFlagEmoji.resolveSourceLocaleIdentifier(
            languageCode: "pt",
            preferredLanguageIdentifiers: ["en-US"]
        )
        XCTAssertEqual(NoteLocaleFlagEmoji.flagEmoji(forLocaleIdentifier: resolved), "🇧🇷")
    }

    func testChineseHansDefaultChina() {
        let resolved = NoteLocaleFlagEmoji.resolveSourceLocaleIdentifier(
            languageCode: "zh",
            detectedIdentifier: "zh-Hans",
            preferredLanguageIdentifiers: ["en-US"]
        )
        XCTAssertEqual(NoteLocaleFlagEmoji.flagEmoji(forLocaleIdentifier: resolved), "🇨🇳")
    }

    func testChineseHantFromPreferredTaiwan() {
        let resolved = NoteLocaleFlagEmoji.resolveSourceLocaleIdentifier(
            languageCode: "zh",
            detectedIdentifier: "zh-Hant",
            preferredLanguageIdentifiers: ["en-US", "zh-Hant-TW"]
        )
        XCTAssertEqual(NoteLocaleFlagEmoji.flagEmoji(forLocaleIdentifier: resolved), "🇹🇼")
    }

    func testInvalidRegionReturnsNil() {
        XCTAssertNil(NoteLocaleFlagEmoji.flagEmoji(forLocaleIdentifier: "en-INVALID"))
        XCTAssertNil(NoteLocaleFlagEmoji.flagEmoji(regionCode: "X"))
    }

    func testFlagEmojiForLocaleLanguage() {
        let language = Locale.Language(identifier: "en-US")
        XCTAssertEqual(NoteLocaleFlagEmoji.flagEmoji(for: language), "🇺🇸")
    }
}
