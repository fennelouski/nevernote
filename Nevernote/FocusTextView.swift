//
//  FocusTextView.swift
//  NeverNote
//
//  Created by Nathan Fennel on 5/17/26.
//  Copyright © 2026 Nathan Fennel. All rights reserved.
//

import SwiftUI

struct FocusTextView: View {
    let attributedText: NSAttributedString
    let textAlignment: NoteTextAlignment
    let maximizePresentationSize: Bool
    var dataDetectorsEnabled: Bool
    var onDataDetectorInteraction: ((NoteDataDetectorInteraction) -> Void)?
    var onHTTPSImageLinkLongPress: ((URL, CGPoint, PlatformTextView) -> Void)?

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let availableHeight = max(proxy.size.height, 1)
            let fitted = fittedAttributedText(maxWidth: width, maxHeight: availableHeight)

            Group {
                #if canImport(UIKit)
                ReadOnlyNoteTextView(
                    attributedText: fitted,
                    textAlignment: textAlignment.nsTextAlignment,
                    dataDetectorTypes: dataDetectorsEnabled ? NoteDataDetectors.enabledTypes : [],
                    onDataDetectorInteraction: onDataDetectorInteraction,
                    onHTTPSImageLinkLongPress: onHTTPSImageLinkLongPress
                )
                #else
                ReadOnlyNoteTextView(
                    attributedText: fitted,
                    textAlignment: textAlignment.nsTextAlignment,
                    dataDetectorsEnabled: dataDetectorsEnabled,
                    onDataDetectorInteraction: onDataDetectorInteraction,
                    onHTTPSImageLinkLongPress: onHTTPSImageLinkLongPress
                )
                #endif
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: frameAlignment)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var frameAlignment: Alignment {
        switch textAlignment {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        }
    }

    private func fittedAttributedText(maxWidth: CGFloat, maxHeight: CGFloat) -> NSAttributedString {
        let fitted: NSAttributedString
        if maximizePresentationSize {
            fitted = maximizeToFit(maxWidth: maxWidth, maxHeight: maxHeight)
        } else {
            let measuredHeight = max(measureHeight(of: attributedText, constrainedTo: maxWidth), 1)
            let scale = min(1.0, maxHeight / measuredHeight)
            fitted = scaleFonts(in: attributedText, scale: scale)
        }
        return NoteTextFormatting.applyingBodyTextColor(fitted)
    }

    private func maximizeToFit(maxWidth: CGFloat, maxHeight: CGFloat) -> NSAttributedString {
        var low: CGFloat = 0.08
        var high: CGFloat = 10.0
        for _ in 0 ..< 22 {
            let mid = (low + high) / 2
            let candidate = scaleFonts(in: attributedText, scale: mid)
            if measureHeight(of: candidate, constrainedTo: maxWidth) <= maxHeight
                && measureWidestWord(of: candidate) <= maxWidth {
                low = mid
            } else {
                high = mid
            }
        }
        return scaleFonts(in: attributedText, scale: low)
    }

    private func measureHeight(of text: NSAttributedString, constrainedTo width: CGFloat) -> CGFloat {
        let bounds = text.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return ceil(bounds.height)
    }

    private func measureWidestWord(of text: NSAttributedString) -> CGFloat {
        var maxWidth: CGFloat = 0
        (text.string as NSString).enumerateSubstrings(
            in: NSRange(location: 0, length: text.length),
            options: [.byWords, .substringNotRequired]
        ) { _, range, _, _ in
            guard range.length > 0 else { return }
            let substr = text.attributedSubstring(from: range)
            let bounds = substr.boundingRect(
                with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )
            maxWidth = max(maxWidth, ceil(bounds.width))
        }
        return maxWidth
    }

    private func scaleFonts(in text: NSAttributedString, scale: CGFloat) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: text)
        let full = NSRange(location: 0, length: mutable.length)
        mutable.enumerateAttribute(.font, in: full) { value, range, _ in
            guard let font = value as? PlatformFont else { return }
            let newSize = max(6, font.pointSize * scale)
            #if canImport(UIKit)
            mutable.addAttribute(.font, value: UIFont(descriptor: font.fontDescriptor, size: newSize), range: range)
            #else
            mutable.addAttribute(.font, value: NSFont(descriptor: font.fontDescriptor, size: newSize), range: range)
            #endif
        }
        return mutable
    }
}
