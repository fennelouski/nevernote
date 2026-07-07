//
//  NoteLogicTests.swift
//  NeverNoteTests
//

import XCTest
@testable import NeverNote

final class NoteRichTextCodecTests: XCTestCase {
    func testRoundTripPreservesStringAndAttributes() {
        let original = NSMutableAttributedString(string: "Hello world")
        original.addAttribute(.link, value: URL(string: "https://example.com")!, range: NSRange(location: 6, length: 5))
        let data = NoteRichTextCodec.encode(original)
        XCTAssertNotNil(data)
        let decoded = NoteRichTextCodec.decode(data!)
        XCTAssertEqual(decoded?.string, "Hello world")
        let link = decoded?.attribute(.link, at: 6, effectiveRange: nil) as? URL
        XCTAssertEqual(link?.absoluteString, "https://example.com")
    }

    func testDecodeEmptyDataReturnsNil() {
        XCTAssertNil(NoteRichTextCodec.decode(Data()))
    }

    func testDecodeGarbageDataReturnsNil() {
        XCTAssertNil(NoteRichTextCodec.decode(Data([0x00, 0x01, 0x02, 0x03])))
    }
}

final class NoteTranslationEligibilityTests: XCTestCase {
    func testMeetsWordThreshold() {
        XCTAssertTrue(NoteTranslationEligibility.meetsWordThreshold("one two three four five six"))
        XCTAssertTrue(NoteTranslationEligibility.meetsWordThreshold("word word word word word"))
        XCTAssertTrue(NoteTranslationEligibility.meetsWordThreshold("hello"))  // single token >= 5 chars
        XCTAssertFalse(NoteTranslationEligibility.meetsWordThreshold("hi"))
        XCTAssertFalse(NoteTranslationEligibility.meetsWordThreshold(""))
        XCTAssertFalse(NoteTranslationEligibility.meetsWordThreshold("a b c"))
    }

    func testTokenizationStripsPunctuation() {
        // "hi!!!!!" strips to "hi" (2 chars) — must not count as a 5-char token
        XCTAssertFalse(NoteTranslationEligibility.meetsWordThreshold("hi!!!!!"))
    }

    func testNormalizedLanguageCode() {
        XCTAssertEqual(NoteTranslationEligibility.normalizedLanguageCode(from: "en-US"), "en")
        XCTAssertEqual(NoteTranslationEligibility.normalizedLanguageCode(from: "zh-Hans-CN"), "zh")
        XCTAssertEqual(NoteTranslationEligibility.normalizedLanguageCode(from: "FR"), "fr")
        XCTAssertNil(NoteTranslationEligibility.normalizedLanguageCode(from: ""))
    }

    func testIsForeignLanguage() {
        XCTAssertFalse(NoteTranslationEligibility.isForeignLanguage(
            detectedCode: "en", preferredLanguageIdentifiers: ["en-US", "es-MX"]))
        XCTAssertTrue(NoteTranslationEligibility.isForeignLanguage(
            detectedCode: "ja", preferredLanguageIdentifiers: ["en-US"]))
        // No preferred languages: everything counts as foreign
        XCTAssertTrue(NoteTranslationEligibility.isForeignLanguage(
            detectedCode: "en", preferredLanguageIdentifiers: []))
    }
}

final class NoteHTTPPasteboardLinkFormattingTests: XCTestCase {
    func testDetectsLinkWithinRange() {
        let text = NSMutableAttributedString(string: "see https://example.com now")
        NoteHTTPPasteboardLinkFormatting.applyHTTPDetectedLinks(
            in: text, range: NSRange(location: 0, length: text.length))
        let link = text.attribute(.link, at: 4, effectiveRange: nil) as? URL
        XCTAssertEqual(link?.absoluteString, "https://example.com")
        XCTAssertNil(text.attribute(.link, at: 0, effectiveRange: nil))
    }

    func testOutOfBoundsRangeIsIgnored() {
        let text = NSMutableAttributedString(string: "short")
        NoteHTTPPasteboardLinkFormatting.applyHTTPDetectedLinks(
            in: text, range: NSRange(location: 0, length: 100))
        XCTAssertNil(text.attribute(.link, at: 0, effectiveRange: nil))
    }

    func testPlainTextGetsNoLinks() {
        let text = NSMutableAttributedString(string: "no links here at all")
        NoteHTTPPasteboardLinkFormatting.applyHTTPDetectedLinks(
            in: text, range: NSRange(location: 0, length: text.length))
        text.enumerateAttribute(.link, in: NSRange(location: 0, length: text.length)) { value, _, _ in
            XCTAssertNil(value)
        }
    }
}

final class NoteLanguageDetectionTests: XCTestCase {
    func testDetectsEnglish() {
        let result = NoteLanguageDetection.detectDominantLanguage(
            in: "The quick brown fox jumps over the lazy dog and runs far away.")
        XCTAssertEqual(result?.languageCode, "en")
    }

    func testDetectsSpanish() {
        let result = NoteLanguageDetection.detectDominantLanguage(
            in: "El rápido zorro marrón salta sobre el perro perezoso y corre lejos.")
        XCTAssertEqual(result?.languageCode, "es")
    }

    func testEmptyTextReturnsNil() {
        XCTAssertNil(NoteLanguageDetection.detectDominantLanguage(in: ""))
    }
}
