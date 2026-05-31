//
//  NoteTranslationPrefetchCache.swift
//  NeverNote
//

import Foundation

enum TranslationTaskIntent: Equatable {
    case idle
    case prefetch
    case apply
}

@MainActor
final class NoteTranslationPrefetchCache {
    private var readyFingerprint: String?
    private var readyTargetText: String?
    private var prefetchInFlightFingerprint: String?

    static func fingerprint(for text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func reset() {
        readyFingerprint = nil
        readyTargetText = nil
        prefetchInFlightFingerprint = nil
    }

    func clearFailedPrefetch() {
        prefetchInFlightFingerprint = nil
    }

    func isSatisfied(by fingerprint: String) -> Bool {
        if readyFingerprint == fingerprint { return true }
        if prefetchInFlightFingerprint == fingerprint { return true }
        return false
    }

    func hasInFlight(matching fingerprint: String) -> Bool {
        prefetchInFlightFingerprint == fingerprint
    }

    func readyText(for fingerprint: String) -> String? {
        guard readyFingerprint == fingerprint else { return nil }
        return readyTargetText
    }

    func beginPrefetch(fingerprint: String) {
        readyFingerprint = nil
        readyTargetText = nil
        prefetchInFlightFingerprint = fingerprint
    }

    func storeReady(fingerprint: String, targetText: String) {
        prefetchInFlightFingerprint = nil
        readyFingerprint = fingerprint
        readyTargetText = targetText
    }
}
