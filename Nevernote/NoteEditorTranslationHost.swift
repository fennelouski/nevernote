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
    @Binding var attributedText: NSAttributedString
    var fontToken: String
    var pointSize: CGFloat
    @Binding var isTranslating: Bool
    var onPersist: () -> Void
    var onClearOffer: () -> Void
    var onEligibilityRefresh: () async -> Void

    @State private var taskConfiguration: TranslationSession.Configuration?

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .translationTask(taskConfiguration) { session in
                await performTranslation(using: session)
            }
            .onChange(of: requestID) { _, newID in
                guard newID != nil else { return }
                beginTranslation()
            }
    }

    private func beginTranslation() {
        let source = Locale.Language(identifier: sourceIdentifier)
        let target = Locale.Language(identifier: targetIdentifier)
        taskConfiguration = TranslationSession.Configuration(source: source, target: target)
    }

    @MainActor
    private func performTranslation(using session: TranslationSession) async {
        defer {
            isTranslating = false
            taskConfiguration = nil
        }
        let sourceText = attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sourceText.isEmpty else { return }
        do {
            let response = try await session.translate(sourceText)
            attributedText = NoteOnDeviceTranslation.prependTranslation(
                response.targetText,
                to: attributedText,
                fontToken: fontToken,
                pointSize: pointSize
            )
            onPersist()
            await onEligibilityRefresh()
        } catch {
            onClearOffer()
        }
    }
}

extension View {
    @ViewBuilder
    func noteEditorTranslationHost(
        isSupported: Bool,
        sourceIdentifier: String?,
        targetIdentifier: String?,
        requestID: UUID?,
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
