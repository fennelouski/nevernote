#if canImport(UIKit)
//
//  RichTextEditor.swift
//  NeverNote
//
//  Created by Nathan Fennel on 5/17/26.
//  Copyright © 2026 Nathan Fennel. All rights reserved.
//

import SwiftUI
import UIKit

struct RichTextEditor: UIViewRepresentable {
   @Binding var attributedText: NSAttributedString
   @Binding var isFirstResponder: Bool
   var preferredFontName: String
   var pointSize: CGFloat
   var textAlignment: NoteTextAlignment
   var linePrefixMode: NoteLinePrefixMode
   let command: EditorCommand?
   let onHTTPSImageLinkLongPress: (URL, CGPoint, UITextView) -> Void
   let onChange: () -> Void
   let onFormattingStateChange: (Bool, Bool, Bool) -> Void

   private var hasCanvasContent: Bool {
       !attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
   }

   func makeUIView(context: Context) -> NoteWrappingTextView {
       let textView = NoteWrappingTextView()
       textView.blocksResignUnlessCanvasHasContent = true
       textView.canvasHasNonWhitespaceContent = { [attributedText] in
           !attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
       }
       textView.delegate = context.coordinator
       textView.allowsEditingTextAttributes = true
       textView.isScrollEnabled = true
       textView.showsVerticalScrollIndicator = true
       textView.alwaysBounceVertical = true
       textView.alwaysBounceHorizontal = false
       textView.backgroundColor = .clear
       textView.textAlignment = textAlignment.nsTextAlignment
       textView.textContainer.lineBreakMode = .byWordWrapping
       textView.textContainer.lineFragmentPadding = 0
       let initial = EditorFont.uiFont(forToken: preferredFontName, size: pointSize)
       textView.font = initial
       textView.typingAttributes = [
           .font: initial,
           .paragraphStyle: RichTextEditor.paragraphStyle(for: textAlignment)
       ]
       textView.tintColor = .brandBlueTint
       textView.textColor = .noteBodyText
       textView.textContainerInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
       let prefixFallback = EditorFont.uiFont(forToken: preferredFontName, size: pointSize)
       textView.attributedText = NoteTextFormatting.makeDisplayAttributedText(
           from: attributedText,
           alignment: textAlignment,
           linePrefixMode: linePrefixMode,
           prefixFallbackFont: prefixFallback
       )
       textView.textColor = .noteBodyText
       context.coordinator.lastSyncedPreferredFont = preferredFontName
       let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLinkLongPress(_:)))
       longPress.minimumPressDuration = 0.45
       textView.addGestureRecognizer(longPress)
       textView.inputAccessoryView = nil

       return textView
   }

   func updateUIView(_ uiView: NoteWrappingTextView, context: Context) {
       context.coordinator.parent = self
       context.coordinator.focusBinding = $isFirstResponder

       uiView.isScrollEnabled = true
       uiView.alwaysBounceVertical = true
       uiView.showsVerticalScrollIndicator = true

       uiView.blocksResignUnlessCanvasHasContent = true
       uiView.canvasHasNonWhitespaceContent = { [attributedText] in
           !attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
       }

       uiView.textAlignment = textAlignment.nsTextAlignment
       context.coordinator.syncTypingAlignment(in: uiView)

       let prefixFallback = EditorFont.uiFont(forToken: preferredFontName, size: pointSize)
       let display = NoteTextFormatting.makeDisplayAttributedText(
           from: attributedText,
           alignment: textAlignment,
           linePrefixMode: linePrefixMode,
           prefixFallbackFont: prefixFallback
       )
       if uiView.attributedText != display {
           if !uiView.isFirstResponder || uiView.text != display.string {
               let savedRange = uiView.selectedRange
               let savedTypingAttrs = uiView.typingAttributes
               uiView.attributedText = display
               uiView.textColor = .noteBodyText
               if savedRange.location + savedRange.length <= display.length {
                   uiView.selectedRange = savedRange
                   uiView.typingAttributes = savedTypingAttrs
               }
           }
       }

       if context.coordinator.lastSyncedPreferredFont != preferredFontName {
           context.coordinator.lastSyncedPreferredFont = preferredFontName
           context.coordinator.syncPreferredFont(to: uiView)
       }

       if isFirstResponder && !uiView.isFirstResponder {
           DispatchQueue.main.async { uiView.becomeFirstResponder() }
       } else if !isFirstResponder && uiView.isFirstResponder {
           if hasCanvasContent {
               DispatchQueue.main.async { let _ = uiView.resignFirstResponder() }
           } else {
               DispatchQueue.main.async { context.coordinator.focusBinding?.wrappedValue = true }
           }
       }

       if let command, context.coordinator.lastAppliedCommandId != command.id {
           context.coordinator.lastAppliedCommandId = command.id
           context.coordinator.apply(command: command.action, to: uiView)
           context.coordinator.emitFormattingState(uiView)
           guard command.action != .selectAll else { return }
           let updatedDisplay = uiView.attributedText ?? NSAttributedString()
           let updated = NoteTextFormatting.stripPrefixesFromDisplayString(updatedDisplay, mode: linePrefixMode)
           DispatchQueue.main.async {
               attributedText = updated
               onChange()
           }
       }
   }

   func makeCoordinator() -> Coordinator {
       Coordinator(parent: self)
   }

   final class Coordinator: NSObject, UITextViewDelegate {
       var parent: RichTextEditor
       var lastAppliedCommandId: Int = 0
       var lastSyncedPreferredFont: String = ""
       var focusBinding: Binding<Bool>?

       init(parent: RichTextEditor) {
           self.parent = parent
       }

       @objc func handleLinkLongPress(_ gesture: UILongPressGestureRecognizer) {
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
           parent.onHTTPSImageLinkLongPress(url, point, textView)
       }

       func textViewDidBeginEditing(_ textView: UITextView) {
           focusBinding?.wrappedValue = true
       }

       func textViewDidEndEditing(_ textView: UITextView) {
           guard parent.hasCanvasContent else {
               DispatchQueue.main.async { textView.becomeFirstResponder() }
               return
           }
           focusBinding?.wrappedValue = false
       }

       func textViewDidChange(_ textView: UITextView) {
           textView.invalidateIntrinsicContentSize()
           let stripped = NoteTextFormatting.stripPrefixesFromDisplayString(textView.attributedText, mode: parent.linePrefixMode)
           parent.attributedText = stripped
           parent.onChange()
           emitFormattingState(textView)
       }

       func textViewDidChangeSelection(_ textView: UITextView) {
           emitFormattingState(textView)
           guard parent.linePrefixMode != .none else { return }
           let clamped = clampedSelection(textView.selectedRange, in: textView)
           if !NSEqualRanges(clamped, textView.selectedRange) {
               textView.selectedRange = clamped
           }
       }

       func emitFormattingState(_ textView: UITextView) {
           let attrs = textView.typingAttributes
           let font = attrs[.font] as? UIFont
           let isBold = font?.fontDescriptor.symbolicTraits.contains(.traitBold) ?? false
           let isItalic = font?.fontDescriptor.symbolicTraits.contains(.traitItalic) ?? false
           let isUnderline = (attrs[.underlineStyle] as? Int ?? 0) != 0
           parent.onFormattingStateChange(isBold, isItalic, isUnderline)
       }

       func textView(
           _ textView: UITextView,
           shouldChangeTextIn range: NSRange,
           replacementText text: String
       ) -> Bool {
           guard parent.linePrefixMode != .none else { return true }
           let locked = NoteTextFormatting.lockedPrefixRanges(in: textView.text as NSString, mode: parent.linePrefixMode)
           return !locked.contains(where: { NSIntersectionRange($0, range).length > 0 })
       }

       func syncPreferredFont(to textView: UITextView) {
           let token = parent.preferredFontName
           let size = (textView.typingAttributes[.font] as? UIFont)?.pointSize ?? parent.pointSize
           let font = EditorFont.uiFont(forToken: token, size: size)
           if textView.text.isEmpty {
               textView.font = font
           }
           textView.typingAttributes[.font] = font
           textView.invalidateIntrinsicContentSize()
       }

       func apply(command: TextFormatAction, to textView: UITextView) {
           let selection = textView.selectedRange
           let mutable = NSMutableAttributedString(attributedString: textView.attributedText)

           switch command {
           case .bold:
               toggleTrait(.traitBold, in: mutable, selection: selection, typingAttributes: &textView.typingAttributes)
           case .italic:
               toggleTrait(.traitItalic, in: mutable, selection: selection, typingAttributes: &textView.typingAttributes)
           case .underline:
               toggleUnderline(in: mutable, selection: selection, typingAttributes: &textView.typingAttributes)
           case .font(let token):
               applyFontToken(token, in: mutable, selection: selection, typingAttributes: &textView.typingAttributes)
           case .alignment(let alignment):
               applyAlignment(alignment, in: mutable, selection: selection, typingAttributes: &textView.typingAttributes)
               textView.textAlignment = alignment.nsTextAlignment
           case .refreshDerivedDisplay:
               break
           case .selectAll:
               DispatchQueue.main.async { [weak textView] in
                   guard let textView else { return }
                   textView.selectedRange = NSRange(location: 0, length: textView.textStorage.length)
                   self.emitFormattingState(textView)
               }
               return
           case .fontSize(let size):
               let fullRange = NSRange(location: 0, length: mutable.length)
               mutable.enumerateAttribute(.font, in: fullRange) { value, range, _ in
                   let old = (value as? UIFont) ?? defaultFallbackFont()
                   mutable.addAttribute(.font, value: UIFont(descriptor: old.fontDescriptor, size: size), range: range)
               }
               let currentFont = textView.typingAttributes[.font] as? UIFont ?? defaultFallbackFont()
               let newTypingFont = UIFont(descriptor: currentFont.fontDescriptor, size: size)
               textView.typingAttributes[.font] = newTypingFont
               textView.font = newTypingFont
           case .resetFormatting:
               let fullRange = NSRange(location: 0, length: mutable.length)
               let resetFont = EditorFont.uiFont(forToken: EditorFont.systemBoldStorageToken, size: EditorFont.defaultFontSize)
               mutable.setAttributes([.font: resetFont], range: fullRange)
               let resetStyle = NSMutableParagraphStyle()
               resetStyle.alignment = .center
               textView.typingAttributes = [.font: resetFont, .paragraphStyle: resetStyle]
               textView.textAlignment = .center
               textView.font = resetFont
           }

           textView.attributedText = mutable
           textView.selectedRange = selection
           textView.invalidateIntrinsicContentSize()
       }

       private func defaultFallbackFont() -> UIFont {
           EditorFont.uiFont(forToken: parent.preferredFontName, size: parent.pointSize)
       }

       private func applyFontToken(
           _ token: String,
           in text: NSMutableAttributedString,
           selection: NSRange,
           typingAttributes: inout [NSAttributedString.Key: Any]
       ) {
           if selection.length == 0 {
               let size = (typingAttributes[.font] as? UIFont)?.pointSize ?? parent.pointSize
               typingAttributes[.font] = EditorFont.uiFont(forToken: token, size: size)
               return
           }

           text.enumerateAttribute(.font, in: selection) { value, range, _ in
               let old = (value as? UIFont) ?? defaultFallbackFont()
               let size = old.pointSize
               let base = EditorFont.uiFont(forToken: token, size: size)
               let traits = old.fontDescriptor.symbolicTraits
               if let descriptor = base.fontDescriptor.withSymbolicTraits(traits) {
                   text.addAttribute(.font, value: UIFont(descriptor: descriptor, size: size), range: range)
               } else {
                   text.addAttribute(.font, value: base, range: range)
               }
           }
       }

       private func toggleTrait(
           _ trait: UIFontDescriptor.SymbolicTraits,
           in text: NSMutableAttributedString,
           selection: NSRange,
           typingAttributes: inout [NSAttributedString.Key: Any]
       ) {
           guard selection.length > 0 else {
               let currentFont = (typingAttributes[.font] as? UIFont) ?? defaultFallbackFont()
               typingAttributes[.font] = toggledFont(from: currentFont, trait: trait)
               return
           }

           text.enumerateAttribute(.font, in: selection) { value, range, _ in
               let existing = (value as? UIFont) ?? defaultFallbackFont()
               text.addAttribute(.font, value: toggledFont(from: existing, trait: trait), range: range)
           }
       }

       private func toggledFont(from font: UIFont, trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
           var traits = font.fontDescriptor.symbolicTraits
           if traits.contains(trait) {
               traits.remove(trait)
           } else {
               traits.insert(trait)
           }

           guard let descriptor = font.fontDescriptor.withSymbolicTraits(traits) else { return font }
           return UIFont(descriptor: descriptor, size: font.pointSize)
       }

       private func toggleUnderline(
           in text: NSMutableAttributedString,
           selection: NSRange,
           typingAttributes: inout [NSAttributedString.Key: Any]
       ) {
           guard selection.length > 0 else {
               let current = typingAttributes[.underlineStyle] as? Int ?? 0
               typingAttributes[.underlineStyle] = current == 0 ? NSUnderlineStyle.single.rawValue : 0
               return
           }

           text.enumerateAttribute(.underlineStyle, in: selection) { value, range, _ in
               let current = value as? Int ?? 0
               let next = current == 0 ? NSUnderlineStyle.single.rawValue : 0
               text.addAttribute(.underlineStyle, value: next, range: range)
           }
       }

       private func applyAlignment(
           _ alignment: NoteTextAlignment,
           in text: NSMutableAttributedString,
           selection: NSRange,
           typingAttributes: inout [NSAttributedString.Key: Any]
       ) {
           let paragraphStyle = RichTextEditor.paragraphStyle(for: alignment)
           let applyRange: NSRange
           if selection.length > 0 {
               applyRange = selection
           } else {
               applyRange = NSRange(location: 0, length: text.length)
           }
           if applyRange.length > 0 {
               text.addAttribute(.paragraphStyle, value: paragraphStyle, range: applyRange)
           }
           typingAttributes[.paragraphStyle] = paragraphStyle
       }

       private func clampedSelection(_ selection: NSRange, in textView: UITextView) -> NSRange {
           let locked = NoteTextFormatting.lockedPrefixRanges(in: textView.text as NSString, mode: parent.linePrefixMode)
           guard !locked.isEmpty else { return selection }

           var adjusted = selection
           for range in locked {
               if selection.length == 0 {
                   if selection.location >= range.location && selection.location < NSMaxRange(range) {
                       adjusted.location = NSMaxRange(range)
                   }
               } else if NSIntersectionRange(range, selection).length > 0 {
                   adjusted.location = max(adjusted.location, NSMaxRange(range))
                   adjusted.length = max(0, selection.length - NSIntersectionRange(range, selection).length)
               }
           }
           return adjusted
       }

       func syncTypingAlignment(in textView: UITextView) {
           textView.typingAttributes[.paragraphStyle] = RichTextEditor.paragraphStyle(for: parent.textAlignment)
       }
   }

   private static func paragraphStyle(for alignment: NoteTextAlignment) -> NSParagraphStyle {
       let paragraphStyle = NSMutableParagraphStyle()
       paragraphStyle.alignment = alignment.nsTextAlignment
       paragraphStyle.lineBreakMode = .byWordWrapping
       return paragraphStyle
   }
}
#endif
