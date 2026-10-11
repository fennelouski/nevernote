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
        context.coordinator.onDataDetectorInteraction = onDataDetectorInteraction
        return textView
    }

    func updateUIView(_ uiView: NoteWrappingTextView, context: Context) {
        context.coordinator.requiresLinkConfirmation = requiresLinkConfirmation
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

        init(requiresLinkConfirmation: Bool) {
            self.requiresLinkConfirmation = requiresLinkConfirmation
        }

        func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
            guard requiresLinkConfirmation,
                  case .link(let url) = textItem.content,
                  let interactionModel = NoteDataDetectorInteraction.make(url: url, range: textItem.range, in: textView.text) else {
                return defaultAction
            }
            return UIAction(title: interactionModel.primaryActionTitle) { [onDataDetectorInteraction] _ in
                onDataDetectorInteraction?(interactionModel)
            }
        }

        func textView(_ textView: UITextView, menuConfigurationFor textItem: UITextItem, defaultMenu: UIMenu) -> UITextItem.MenuConfiguration? {
            guard requiresLinkConfirmation,
                  case .link(let url) = textItem.content,
                  let interactionModel = NoteDataDetectorInteraction.make(url: url, range: textItem.range, in: textView.text) else {
                return .init(preview: nil, menu: defaultMenu)
            }
            DispatchQueue.main.async { [onDataDetectorInteraction] in
                onDataDetectorInteraction?(interactionModel)
            }
            return nil
        }
    }
}
#endif
