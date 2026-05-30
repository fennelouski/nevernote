#if canImport(UIKit)
//
//  ReadOnlyNoteTextView.swift
//  NeverNote
//
//  Created by Nathan Fennel on 5/17/26.
//  Copyright © 2026 Nathan Fennel. All rights reserved.
//

import SwiftUI
import UIKit

struct ReadOnlyNoteTextView: UIViewRepresentable {
    var attributedText: NSAttributedString
    var textAlignment: NSTextAlignment
    var dataDetectorTypes: UIDataDetectorTypes
    var onDataDetectorInteraction: ((NoteDataDetectorInteraction) -> Void)?
    var onHTTPSImageLinkLongPress: ((URL, CGPoint, UITextView) -> Void)?

    private var requiresLinkConfirmation: Bool {
        !dataDetectorTypes.isEmpty
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(requiresLinkConfirmation: requiresLinkConfirmation)
    }

    func makeUIView(context: Context) -> NoteWrappingTextView {
        let textView = NoteWrappingTextView()
        textView.isEditable = false
        textView.allowsEditingTextAttributes = false
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.showsVerticalScrollIndicator = false
        textView.alwaysBounceHorizontal = false
        textView.backgroundColor = .clear
        textView.textAlignment = textAlignment
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        textView.dataDetectorTypes = dataDetectorTypes
        textView.tintColor = .brandBlueTint
        textView.textColor = .noteBodyText
        textView.attributedText = attributedText
        textView.textColor = .noteBodyText
        textView.delegate = context.coordinator
        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLinkLongPress(_:)))
        longPress.minimumPressDuration = 0.45
        textView.addGestureRecognizer(longPress)
        context.coordinator.onHTTPSImageLinkLongPress = onHTTPSImageLinkLongPress
        context.coordinator.onDataDetectorInteraction = onDataDetectorInteraction
        return textView
    }

    func updateUIView(_ uiView: NoteWrappingTextView, context: Context) {
        context.coordinator.requiresLinkConfirmation = requiresLinkConfirmation
        context.coordinator.onHTTPSImageLinkLongPress = onHTTPSImageLinkLongPress
        context.coordinator.onDataDetectorInteraction = onDataDetectorInteraction
        uiView.textAlignment = textAlignment
        uiView.dataDetectorTypes = dataDetectorTypes
        if !(uiView.attributedText?.isEqual(to: attributedText) ?? false) {
            uiView.attributedText = attributedText
            uiView.textColor = .noteBodyText
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var requiresLinkConfirmation: Bool
        var onDataDetectorInteraction: ((NoteDataDetectorInteraction) -> Void)?
        var onHTTPSImageLinkLongPress: ((URL, CGPoint, UITextView) -> Void)?

        init(requiresLinkConfirmation: Bool) {
            self.requiresLinkConfirmation = requiresLinkConfirmation
        }

        func textView(
            _ textView: UITextView,
            shouldInteractWith url: URL,
            in characterRange: NSRange,
            interaction: UITextItemInteraction
        ) -> Bool {
            guard requiresLinkConfirmation else { return true }
            guard let interactionModel = NoteDataDetectorInteraction.make(
                url: url,
                range: characterRange,
                in: textView.text
            ) else { return true }
            DispatchQueue.main.async { [onDataDetectorInteraction] in
                onDataDetectorInteraction?(interactionModel)
            }
            return false
        }

        @objc fileprivate func handleLinkLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began, let textView = gesture.view as? UITextView else { return }
            let point = gesture.location(in: textView)
            guard let pos = textView.closestPosition(to: point) else { return }
            let idx = textView.offset(from: textView.beginningOfDocument, to: pos)
            guard textView.textStorage.length > 0 else { return }
            let safeIdx = min(max(0, idx), textView.textStorage.length - 1)
            var effective = NSRange()
            let link = textView.textStorage.attribute(.link, at: safeIdx, effectiveRange: &effective)
            guard let url = link as? URL ?? (link as? String).flatMap(URL.init(string:)) else { return }
            guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return }
            onHTTPSImageLinkLongPress?(url, point, textView)
        }
    }
}
#endif
