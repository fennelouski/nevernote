#if canImport(UIKit)
//
//  NoteWrappingTextView.swift
//  NeverNote
//
//  Created by Nathan Fennel on 5/17/26.
//  Copyright © 2026 Nathan Fennel. All rights reserved.
//

import SwiftUI
import UIKit

/// `UITextView` + SwiftUI often reports a huge intrinsic width (single-line width), so the editor grows past the screen.
/// This subclass pins the text container to the laid-out width and only contributes intrinsic height.
final class NoteWrappingTextView: UITextView {
    private static let pastedImageFontSize: CGFloat = 24
    static var customUndoAvailable = false
    /// When true, keyboard dismissal requires non-whitespace canvas content.
    var blocksResignUnlessCanvasHasContent = false
    var canvasHasNonWhitespaceContent: () -> Bool = { true }

    override func resignFirstResponder() -> Bool {
        if blocksResignUnlessCanvasHasContent, !canvasHasNonWhitespaceContent() {
            return false
        }
        return super.resignFirstResponder()
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake && Self.customUndoAvailable {
            NotificationCenter.default.post(name: NevernoteNotification.shakeUndo, object: nil)
            return
        }
        super.motionEnded(motion, with: event)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        syncTextContainerToBoundsWidth()
        invalidateIntrinsicContentSize()
    }

    override func paste(_ sender: Any?) {
        if let image = UIPasteboard.general.image ?? UIPasteboard.general.images?.first {
            insertPastedImage(image)
            return
        }
        let insertionIndex = selectedRange.location
        let lengthBefore = textStorage.length
        super.paste(sender)
        let delta = textStorage.length - lengthBefore
        guard delta > 0 else { return }
        let pastedRange = NSRange(location: insertionIndex, length: delta)
        let mutable = NSMutableAttributedString(attributedString: attributedText)
        NoteHTTPPasteboardLinkFormatting.applyHTTPDetectedLinks(in: mutable, range: pastedRange)
        attributedText = mutable
        delegate?.textViewDidChange?(self)
    }

    func insertPastedImage(_ image: UIImage) {
        let horizontalInset = textContainerInset.left + textContainerInset.right
        let padding = textContainer.lineFragmentPadding * 2
        let maxW = max(1, bounds.width - horizontalInset - padding)
        let scale = min(1, maxW / max(image.size.width, 1))
        let sz = CGSize(width: max(1, image.size.width * scale), height: max(1, image.size.height * scale))
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(origin: .zero, size: sz)
        let attr = NSMutableAttributedString(attachment: attachment)
        let baseFont = font ?? typingAttributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: Self.pastedImageFontSize, weight: .bold)
        attr.addAttribute(.font, value: baseFont, range: NSRange(location: 0, length: attr.length))
        let mutable = NSMutableAttributedString(attributedString: attributedText)
        let insertAt = selectedRange
        mutable.replaceCharacters(in: insertAt, with: attr)
        attributedText = mutable
        selectedRange = NSRange(location: insertAt.location + attr.length, length: 0)
        delegate?.textViewDidChange?(self)
    }

    private func syncTextContainerToBoundsWidth() {
        guard bounds.width > 0 else { return }
        let horizontalInset = textContainerInset.left + textContainerInset.right
        let padding = textContainer.lineFragmentPadding * 2
        let contentWidth = max(0, bounds.width - horizontalInset - padding)
        textContainer.widthTracksTextView = false
        textContainer.size = CGSize(width: contentWidth, height: .greatestFiniteMagnitude)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        if isScrollEnabled {
            return CGSize(width: size.width, height: size.height)
        }
        return super.sizeThatFits(size)
    }

    override var intrinsicContentSize: CGSize {
        if isScrollEnabled {
            return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
        }
        let w = bounds.width
        guard w > 0 else {
            return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
        }
        syncTextContainerToBoundsWidth()
        let height = sizeThatFits(CGSize(width: w, height: .greatestFiniteMagnitude)).height
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }

    override var attributedText: NSAttributedString! {
        get { super.attributedText }
        set {
            super.attributedText = newValue
            invalidateIntrinsicContentSize()
        }
    }
}
#endif
