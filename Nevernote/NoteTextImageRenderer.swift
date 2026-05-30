//
//  NoteTextImageRenderer.swift
//  Nevernote
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum NoteTextAlignment: String, CaseIterable, Identifiable {
    case left
    case center
    case right

    var id: String { rawValue }

    var nsTextAlignment: NSTextAlignment {
        switch self {
        case .left: return .left
        case .center: return .center
        case .right: return .right
        }
    }
}

enum NoteLinePrefixMode: String, CaseIterable, Identifiable {
    case none
    case bulleted
    case numbered

    var id: String { rawValue }

    mutating func cycle() {
        switch self {
        case .none: self = .bulleted
        case .bulleted: self = .numbered
        case .numbered: self = .none
        }
    }
}

enum NoteExportAspectRatio: String, CaseIterable, Identifiable {
    case portrait3_4
    case story9_16
    case square1_1
    case landscape16_9
    case landscape4_3

    var id: String { rawValue }

    /// Width ÷ height
    var widthToHeight: CGFloat {
        switch self {
        case .portrait3_4: return 3.0 / 4.0
        case .story9_16: return 9.0 / 16.0
        case .square1_1: return 1.0
        case .landscape16_9: return 16.0 / 9.0
        case .landscape4_3: return 4.0 / 3.0
        }
    }

    var displayLabel: String {
        switch self {
        case .portrait3_4: return String(localized: "Portrait")
        case .story9_16: return String(localized: "9:16")
        case .square1_1: return String(localized: "Square")
        case .landscape16_9: return String(localized: "16:9")
        case .landscape4_3: return String(localized: "Landscape")
        }
    }
}

enum NoteTextImageRenderer {
    private static let maxLongEdge: CGFloat = 2048
    private static let margin: CGFloat = 40

    static func renderImage(
        attributedText: NSAttributedString,
        backgroundColor: PlatformColor,
        aspect: NoteExportAspectRatio,
        alignment: NoteTextAlignment,
        linePrefixMode: NoteLinePrefixMode,
        maximizePresentationSize: Bool
    ) -> PlatformImage? {
        let ratio = aspect.widthToHeight
        let pixelWidth: CGFloat
        let pixelHeight: CGFloat
        if ratio >= 1 {
            pixelWidth = maxLongEdge
            pixelHeight = max(1, maxLongEdge / ratio)
        } else {
            pixelHeight = maxLongEdge
            pixelWidth = max(1, maxLongEdge * ratio)
        }

        let bounds = CGRect(origin: .zero, size: CGSize(width: pixelWidth, height: pixelHeight))
        let inner = bounds.insetBy(dx: margin, dy: margin)
        guard inner.width > 4, inner.height > 4 else { return nil }

        let prefixFallback: PlatformFont
        if attributedText.length > 0,
           let font = attributedText.attribute(.font, at: 0, effectiveRange: nil) as? PlatformFont {
            prefixFallback = font
        } else {
            prefixFallback = EditorFont.platformFont(forToken: EditorFont.systemBoldStorageToken, size: 24)
        }
        let styled = NoteTextFormatting.makeDisplayAttributedText(
            from: attributedText,
            alignment: alignment,
            linePrefixMode: linePrefixMode,
            prefixFallbackFont: prefixFallback
        )
        let fitted = fitTextToBounds(
            styled,
            maxWidth: inner.width,
            maxHeight: inner.height,
            maximize: maximizePresentationSize
        )
        #if canImport(UIKit)
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = true
        format.scale = 1

        let renderer = UIGraphicsImageRenderer(bounds: bounds, format: format)
        return renderer.image { ctx in
            backgroundColor.setFill()
            ctx.fill(bounds)

            let textRect = fitted.boundingRect(
                with: CGSize(width: inner.width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )
            let drawY = inner.midY - textRect.height / 2
            let drawRect = CGRect(x: inner.minX, y: drawY, width: inner.width, height: textRect.height)
            ctx.cgContext.saveGState()
            ctx.cgContext.clip(to: inner)
            fitted.draw(with: drawRect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            ctx.cgContext.restoreGState()
        }
        #else
        let image = NSImage(size: bounds.size)
        image.lockFocus()
        backgroundColor.setFill()
        bounds.fill()
        let textRect = fitted.boundingRect(
            with: CGSize(width: inner.width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        let drawY = inner.midY - textRect.height / 2
        let drawRect = CGRect(x: inner.minX, y: drawY, width: inner.width, height: textRect.height)
        fitted.draw(with: drawRect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        image.unlockFocus()
        return image
        #endif
    }

    private static func fitTextToBounds(
        _ attributed: NSAttributedString,
        maxWidth: CGFloat,
        maxHeight: CGFloat,
        maximize: Bool
    ) -> NSAttributedString {
        if maximize {
            var low: CGFloat = 0.08
            var high: CGFloat = 10.0
            for _ in 0 ..< 22 {
                let mid = (low + high) / 2
                let candidate = scaleFonts(in: attributed, scale: mid)
                if measureHeight(candidate, width: maxWidth) <= maxHeight
                    && measureWidestWord(candidate) <= maxWidth {
                    low = mid
                } else {
                    high = mid
                }
            }
            return scaleFonts(in: attributed, scale: low)
        }

        var scale: CGFloat = 1.0
        var scaled = attributed
        for _ in 0 ..< 48 {
            let h = measureHeight(scaled, width: maxWidth)
            if h <= maxHeight || scale < 0.08 { break }
            scale *= 0.94
            scaled = scaleFonts(in: attributed, scale: scale)
        }
        return scaled
    }

    private static func measureHeight(_ attributed: NSAttributedString, width: CGFloat) -> CGFloat {
        let r = attributed.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return ceil(r.height)
    }

    private static func measureWidestWord(_ attributed: NSAttributedString) -> CGFloat {
        var maxWidth: CGFloat = 0
        (attributed.string as NSString).enumerateSubstrings(
            in: NSRange(location: 0, length: attributed.length),
            options: [.byWords, .substringNotRequired]
        ) { _, range, _, _ in
            guard range.length > 0 else { return }
            let substr = attributed.attributedSubstring(from: range)
            let bounds = substr.boundingRect(
                with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )
            maxWidth = max(maxWidth, ceil(bounds.width))
        }
        return maxWidth
    }

    private static func scaleFonts(in attributed: NSAttributedString, scale: CGFloat) -> NSAttributedString {
        let m = NSMutableAttributedString(attributedString: attributed)
        let full = NSRange(location: 0, length: m.length)
        m.enumerateAttribute(.font, in: full) { value, range, _ in
            guard let font = value as? PlatformFont else { return }
            let newSize = max(6, font.pointSize * scale)
            let desc = font.fontDescriptor
            #if canImport(UIKit)
            let newFont = UIFont(descriptor: desc, size: newSize)
            #else
            let newFont = NSFont(descriptor: desc, size: newSize) ?? font
            #endif
            m.addAttribute(.font, value: newFont, range: range)
        }
        return m
    }
}

enum NoteTextFormatting {
    static let bulletPrefix = "\u{2022} "

    static func makeDisplayAttributedText(
        from base: NSAttributedString,
        alignment: NoteTextAlignment,
        linePrefixMode: NoteLinePrefixMode,
        prefixFallbackFont: PlatformFont
    ) -> NSAttributedString {
        guard linePrefixMode != .none else {
            return strippingForegroundColor(applyingAlignment(base, alignment: alignment))
        }

        let baseNSString = base.string as NSString
        let result = NSMutableAttributedString()
        var nonEmptyLineCount = 0
        var idx = 0

        while idx < baseNSString.length {
            let lineRange = baseNSString.lineRange(for: NSRange(location: idx, length: 0))
            let hasTrailingNewline = lineRange.length > 0 && baseNSString.character(at: lineRange.location + lineRange.length - 1) == 10
            let contentLength = hasTrailingNewline ? max(lineRange.length - 1, 0) : lineRange.length
            let contentRange = NSRange(location: lineRange.location, length: contentLength)
            let lineContent = baseNSString.substring(with: contentRange)
            let isBlank = lineContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

            if !isBlank {
                nonEmptyLineCount += 1
                let prefix = prefixString(for: linePrefixMode, lineNumber: nonEmptyLineCount)
                let prefixFont = resolvedPrefixFont(in: base, contentRange: contentRange, fallback: prefixFallbackFont)
                let prefixAttr = NSMutableAttributedString(string: prefix)
                prefixAttr.addAttribute(.font, value: prefixFont, range: NSRange(location: 0, length: prefixAttr.length))
                result.append(prefixAttr)
            }

            if contentRange.length > 0 {
                result.append(base.attributedSubstring(from: contentRange))
            }
            if hasTrailingNewline {
                result.append(NSAttributedString(string: "\n"))
            }

            idx = NSMaxRange(lineRange)
        }

        return strippingForegroundColor(applyingAlignment(result, alignment: alignment))
    }

    private static func resolvedPrefixFont(
        in base: NSAttributedString,
        contentRange: NSRange,
        fallback: PlatformFont
    ) -> PlatformFont {
        guard contentRange.length > 0 else { return fallback }
        if let font = base.attribute(.font, at: contentRange.location, effectiveRange: nil) as? PlatformFont {
            return font
        }
        var found: PlatformFont?
        base.enumerateAttribute(.font, in: contentRange) { value, _, stop in
            if let font = value as? PlatformFont {
                found = font
                stop.pointee = true
            }
        }
        return found ?? fallback
    }

    private static func strippingForegroundColor(_ attributed: NSAttributedString) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: attributed)
        mutable.removeAttribute(.foregroundColor, range: NSRange(location: 0, length: mutable.length))
        return mutable
    }

    /// Re-applies body text color after attributed-string transforms (e.g. font scaling) that break `textView.textColor` inheritance.
    static func applyingBodyTextColor(_ attributed: NSAttributedString) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: attributed)
        let full = NSRange(location: 0, length: mutable.length)
        guard full.length > 0 else { return mutable }
        mutable.addAttribute(.foregroundColor, value: PlatformColor.noteBodyText, range: full)
        return mutable
    }

    private static func applyingAlignment(_ attributed: NSAttributedString, alignment: NoteTextAlignment) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: attributed)
        let full = NSRange(location: 0, length: mutable.length)
        guard full.length > 0 else { return mutable }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment.nsTextAlignment
        paragraphStyle.lineBreakMode = .byWordWrapping
        mutable.addAttribute(.paragraphStyle, value: paragraphStyle, range: full)
        return mutable
    }

    static func stripPrefixesFromDisplayString(_ display: NSAttributedString, mode: NoteLinePrefixMode) -> NSAttributedString {
        guard mode != .none else { return display }
        let source = display.string as NSString
        let result = NSMutableAttributedString()
        var idx = 0

        while idx < source.length {
            let lineRange = source.lineRange(for: NSRange(location: idx, length: 0))
            let hasTrailingNewline = lineRange.length > 0 && source.character(at: lineRange.location + lineRange.length - 1) == 10
            let contentLength = hasTrailingNewline ? max(lineRange.length - 1, 0) : lineRange.length
            var contentRange = NSRange(location: lineRange.location, length: contentLength)
            let line = source.substring(with: contentRange)
            let isBlank = line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

            if !isBlank {
                let prefixLength = detectedPrefixLength(in: line, mode: mode)
                if prefixLength > 0 && contentRange.length >= prefixLength {
                    contentRange = NSRange(location: contentRange.location + prefixLength, length: contentRange.length - prefixLength)
                }
            }

            if contentRange.length > 0 {
                result.append(display.attributedSubstring(from: contentRange))
            }
            if hasTrailingNewline {
                result.append(NSAttributedString(string: "\n"))
            }
            idx = NSMaxRange(lineRange)
        }

        return strippingForegroundColor(result)
    }

    static func lockedPrefixRanges(in display: NSString, mode: NoteLinePrefixMode) -> [NSRange] {
        guard mode != .none else { return [] }
        var ranges: [NSRange] = []
        var idx = 0

        while idx < display.length {
            let lineRange = display.lineRange(for: NSRange(location: idx, length: 0))
            let hasTrailingNewline = lineRange.length > 0 && display.character(at: lineRange.location + lineRange.length - 1) == 10
            let contentLength = hasTrailingNewline ? max(lineRange.length - 1, 0) : lineRange.length
            let contentRange = NSRange(location: lineRange.location, length: contentLength)
            let line = display.substring(with: contentRange)
            let isBlank = line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            if !isBlank {
                let prefixLength = detectedPrefixLength(in: line, mode: mode)
                if prefixLength > 0 {
                    ranges.append(NSRange(location: lineRange.location, length: min(prefixLength, contentLength)))
                }
            }
            idx = NSMaxRange(lineRange)
        }

        return ranges
    }

    private static func prefixString(for mode: NoteLinePrefixMode, lineNumber: Int) -> String {
        switch mode {
        case .none:
            return ""
        case .bulleted:
            return bulletPrefix
        case .numbered:
            return "\(lineNumber). "
        }
    }

    private static func detectedPrefixLength(in line: String, mode: NoteLinePrefixMode) -> Int {
        switch mode {
        case .none:
            return 0
        case .bulleted:
            return line.hasPrefix(bulletPrefix) ? bulletPrefix.count : 0
        case .numbered:
            var idx = line.startIndex
            var digitCount = 0
            while idx < line.endIndex, line[idx].isNumber {
                digitCount += 1
                idx = line.index(after: idx)
            }
            guard digitCount > 0 else { return 0 }
            guard idx < line.endIndex, line[idx] == "." else { return 0 }
            idx = line.index(after: idx)
            guard idx < line.endIndex, line[idx] == " " else { return 0 }
            return digitCount + 2
        }
    }
}
