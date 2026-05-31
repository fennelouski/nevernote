//
//  NoteEditorTranslationHost.swift
//  NeverNote
//

import SwiftUI
import Translation

/// Invisible attachment that runs `translationTask` on iOS 18+; omitted on earlier OS versions.
@available(iOS 18.0, macOS 15.0, *)
struct NoteEditorTranslationHost: View {
    let sourceIdentifier: String
    let targetIdentifier: String
    let requestID: UUID?
    let prefetchID: UUID?
    @Binding var taskIntent: TranslationTaskIntent
    let prefetchCache: NoteTranslationPrefetchCache
    @Binding var attributedText: NSAttributedString
    var fontToken: String
    var pointSize: CGFloat
    @Binding var isTranslating: Bool
    var onPersist: () -> Void
    var onClearOffer: () -> Void
    var onEligibilityRefresh: () async -> Void

    @State private var taskConfiguration: TranslationSession.Configuration?

    private var prefetchTrigger: UUID? {
        taskIntent == .prefetch ? prefetchID : nil
    }

    private var applyTrigger: UUID? {
        taskIntent == .apply ? requestID : nil
    }

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .translationTask(taskConfiguration) { session in
                await performTranslation(using: session)
            }
            .task(id: prefetchTrigger) {
                guard prefetchTrigger != nil else { return }
                startTranslationSession()
            }
            .task(id: applyTrigger) {
                guard applyTrigger != nil else { return }
                startTranslationSession()
            }
    }

    private func startTranslationSession() {
        let source = Locale.Language(identifier: sourceIdentifier)
        let target = Locale.Language(identifier: targetIdentifier)
        if var configuration = taskConfiguration {
            configuration.invalidate()
            taskConfiguration = configuration
        } else {
            taskConfiguration = TranslationSession.Configuration(source: source, target: target)
        }
    }

    @MainActor
    private func performTranslation(using session: TranslationSession) async {
        switch taskIntent {
        case .prefetch:
            await performPrefetch(using: session)
        case .apply:
            await performApply(using: session)
        case .idle:
            taskConfiguration = nil
        }
    }

    @MainActor
    private func performPrefetch(using session: TranslationSession) async {
        defer {
            taskConfiguration = nil
            if taskIntent == .prefetch {
                taskIntent = .idle
            }
        }
        let sourceText = NoteTranslationPrefetchCache.fingerprint(for: attributedText.string)
        guard !sourceText.isEmpty else { return }
        let fingerprint = sourceText
        prefetchCache.beginPrefetch(fingerprint: fingerprint)
        do {
            try await session.prepareTranslation()
            let targetText = try await session.translate(sourceText).targetText
            prefetchCache.storeReady(fingerprint: fingerprint, targetText: targetText)
        } catch {
            prefetchCache.clearFailedPrefetch()
        }
    }

    @MainActor
    private func performApply(using session: TranslationSession) async {
        defer {
            isTranslating = false
            taskConfiguration = nil
            taskIntent = .idle
        }
        let fingerprint = NoteTranslationPrefetchCache.fingerprint(for: attributedText.string)
        guard !fingerprint.isEmpty else { return }

        if let cached = prefetchCache.readyText(for: fingerprint) {
            applyTranslation(cached)
            prefetchCache.reset()
            return
        }

        do {
            let response = try await session.translate(fingerprint)
            applyTranslation(response.targetText)
            prefetchCache.reset()
        } catch {
            prefetchCache.reset()
            onClearOffer()
        }
    }

    @MainActor
    private func applyTranslation(_ targetText: String) {
        attributedText = NoteOnDeviceTranslation.prependTranslation(
            targetText,
            to: attributedText,
            fontToken: fontToken,
            pointSize: pointSize
        )
        onPersist()
        Task { await onEligibilityRefresh() }
    }
}

extension View {
    @ViewBuilder
    func noteEditorTranslationHost(
        isSupported: Bool,
        sourceIdentifier: String?,
        targetIdentifier: String?,
        requestID: UUID?,
        prefetchID: UUID?,
        taskIntent: Binding<TranslationTaskIntent>,
        prefetchCache: NoteTranslationPrefetchCache,
        attributedText: Binding<NSAttributedString>,
        fontToken: String,
        pointSize: CGFloat,
        isTranslating: Binding<Bool>,
        onPersist: @escaping () -> Void,
        onClearOffer: @escaping () -> Void,
        onEligibilityRefresh: @escaping () async -> Void
    ) -> some View {
        if isSupported,
           #available(iOS 18.0, *),
           let sourceIdentifier,
           let targetIdentifier {
            background {
                NoteEditorTranslationHost(
                    sourceIdentifier: sourceIdentifier,
                    targetIdentifier: targetIdentifier,
                    requestID: requestID,
                    prefetchID: prefetchID,
                    taskIntent: taskIntent,
                    prefetchCache: prefetchCache,
                    attributedText: attributedText,
                    fontToken: fontToken,
                    pointSize: pointSize,
                    isTranslating: isTranslating,
                    onPersist: onPersist,
                    onClearOffer: onClearOffer,
                    onEligibilityRefresh: onEligibilityRefresh
                )
            }
        } else {
            self
        }
    }
}
