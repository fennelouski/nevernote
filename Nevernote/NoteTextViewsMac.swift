#if os(macOS)
import AppKit
import SwiftUI

/// `NSTextView` + SwiftUI layout: pin the text container width to the view bounds.
final class NoteWrappingTextView: NSTextView {
    private static let pastedImageFontSize: CGFloat = 24
    static var customUndoAvailable = false
    var blocksResignUnlessCanvasHasContent = false
    var canvasHasNonWhitespaceContent: () -> Bool = { true }

    override func resignFirstResponder() -> Bool {
        if blocksResignUnlessCanvasHasContent, !canvasHasNonWhitespaceContent() {
            return false
        }
        return super.resignFirstResponder()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        syncTextContainerToBoundsWidth()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        syncTextContainerToBoundsWidth()
    }

    override func paste(_ sender: Any?) {
        if let image = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
            insertPastedImage(image)
            return
        }
        let insertionIndex = selectedRange().location
        let lengthBefore = textStorage?.length ?? 0
        super.paste(sender)
        let delta = (textStorage?.length ?? 0) - lengthBefore
        guard delta > 0 else { return }
        let pastedRange = NSRange(location: insertionIndex, length: delta)
        guard let storage = textStorage else { return }
        let mutable = NSMutableAttributedString(attributedString: attributedString())
        NoteHTTPPasteboardLinkFormatting.applyHTTPDetectedLinks(in: mutable, range: pastedRange)
        textStorage?.setAttributedString(mutable)
        delegate?.textDidChange?(Notification(name: NSText.didChangeNotification, object: self))
    }

    func insertPastedImage(_ image: NSImage) {
        let horizontalInset = textContainerInset.width
        let padding = (textContainer?.lineFragmentPadding ?? 0) * 2
        let maxW = max(1, bounds.width - horizontalInset - padding)
        let imageWidth = max(image.size.width, 1)
        let scale = min(1, maxW / imageWidth)
        let sz = NSSize(width: max(1, imageWidth * scale), height: max(1, image.size.height * scale))
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(origin: .zero, size: sz)
        let attr = NSMutableAttributedString(attachment: attachment)
        let baseFont = font ?? typingAttributes[.font] as? NSFont ?? NSFont.boldSystemFont(ofSize: Self.pastedImageFontSize)
        attr.addAttribute(.font, value: baseFont, range: NSRange(location: 0, length: attr.length))
        let mutable = NSMutableAttributedString(attributedString: attributedString())
        let insertAt = selectedRange()
        mutable.replaceCharacters(in: insertAt, with: attr)
        textStorage?.setAttributedString(mutable)
        setSelectedRange(NSRange(location: insertAt.location + attr.length, length: 0))
        delegate?.textDidChange?(Notification(name: NSText.didChangeNotification, object: self))
    }

    private func syncTextContainerToBoundsWidth() {
        guard bounds.width > 0, let container = textContainer else { return }
        let horizontalInset = textContainerInset.width
        let padding = container.lineFragmentPadding * 2
        let contentWidth = max(0, bounds.width - horizontalInset - padding)
        container.widthTracksTextView = false
        container.containerSize = NSSize(width: contentWidth, height: .greatestFiniteMagnitude)
    }

    override func layout() {
        super.layout()
        if bounds.width > 0 {
            syncTextContainerToBoundsWidth()
        }
    }

    override var intrinsicContentSize: NSSize {
        if isVerticallyResizable {
            return NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
        }
        let w = bounds.width
        guard w > 0 else {
            return NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
        }
        syncTextContainerToBoundsWidth()
        let height = layoutManager?.usedRect(for: textContainer!).height ?? 0
        return NSSize(width: NSView.noIntrinsicMetric, height: height + textContainerInset.height)
    }
}

struct RichTextEditor: NSViewRepresentable {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var attributedText: NSAttributedString
    @Binding var isFirstResponder: Bool
    var preferredFontName: String
    var pointSize: CGFloat
    var textAlignment: NoteTextAlignment
    var linePrefixMode: NoteLinePrefixMode
    let command: EditorCommand?
    let onHTTPSImageLinkLongPress: (URL, CGPoint, NSTextView) -> Void
    let onChange: () -> Void
    let onFormattingStateChange: (Bool, Bool, Bool) -> Void

    private var hasCanvasContent: Bool {
        !attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        scrollView.contentView.postsBoundsChangedNotifications = true

        let textView = NoteWrappingTextView()
        textView.isEditable = true
        textView.isRichText = true
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.lineBreakMode = .byWordWrapping
        textView.textContainer?.lineFragmentPadding = 0
        textView.delegate = context.coordinator
        textView.blocksResignUnlessCanvasHasContent = true
        textView.canvasHasNonWhitespaceContent = { [attributedText] in
            !attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        textView.alignment = textAlignment.nsTextAlignment
        let initial = EditorFont.platformFont(forToken: preferredFontName, size: pointSize)
        textView.font = initial
        textView.typingAttributes = Coordinator.typingAttributes(
            font: initial,
            alignment: textAlignment,
            colorScheme: colorScheme
        )
        textView.textColor = .noteBodyText(for: colorScheme)
        textView.textContainerInset = NSSize(width: 0, height: 12)
        let prefixFallback = EditorFont.platformFont(forToken: preferredFontName, size: pointSize)
        let initialDisplay = NoteTextFormatting.makeDisplayAttributedText(
            from: attributedText,
            alignment: textAlignment,
            linePrefixMode: linePrefixMode,
            prefixFallbackFont: prefixFallback,
            colorScheme: colorScheme
        )
        textView.textStorage?.setAttributedString(initialDisplay)
        context.coordinator.lastSyncedPreferredFont = preferredFontName
        context.coordinator.lastColorScheme = colorScheme
        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView
        let longPress = NSPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLinkLongPress(_:)))
        longPress.minimumPressDuration = 0.45
        textView.addGestureRecognizer(longPress)
        scrollView.documentView = textView
        return scrollView
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSScrollView, context: Context) -> CGSize? {
        let width = proposal.width ?? max(nsView.contentSize.width, 320)
        if let proposedHeight = proposal.height, proposedHeight.isFinite, proposedHeight > 0 {
            return CGSize(width: width, height: proposedHeight)
        }
        let display = NoteTextFormatting.makeDisplayAttributedText(
            from: attributedText,
            alignment: textAlignment,
            linePrefixMode: linePrefixMode,
            prefixFallbackFont: EditorFont.platformFont(forToken: preferredFontName, size: pointSize),
            colorScheme: colorScheme
        )
        let textHeight = NoteTextLayout.measuredHeight(of: display, width: width)
        return CGSize(width: width, height: max(120, textHeight + 24))
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        context.coordinator.parent = self
        context.coordinator.focusBinding = $isFirstResponder
        textView.blocksResignUnlessCanvasHasContent = true
        textView.canvasHasNonWhitespaceContent = { [attributedText] in
            !attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        textView.alignment = textAlignment.nsTextAlignment
        context.coordinator.syncTypingAlignment(in: textView, colorScheme: colorScheme)

        let bodyColor = NSColor.noteBodyText(for: colorScheme)
        textView.textColor = bodyColor

        let prefixFallback = EditorFont.platformFont(forToken: preferredFontName, size: pointSize)
        let display = NoteTextFormatting.makeDisplayAttributedText(
            from: attributedText,
            alignment: textAlignment,
            linePrefixMode: linePrefixMode,
            prefixFallbackFont: prefixFallback,
            colorScheme: colorScheme
        )
        let current = textView.attributedString()
        let colorSchemeChanged = context.coordinator.lastColorScheme != colorScheme
        context.coordinator.lastColorScheme = colorScheme
        if current != display || colorSchemeChanged {
            let savedRange = textView.selectedRange()
            var savedTypingAttrs = textView.typingAttributes
            textView.textStorage?.setAttributedString(display)
            savedTypingAttrs[.foregroundColor] = bodyColor
            if savedRange.location + savedRange.length <= display.length {
                textView.setSelectedRange(savedRange)
                textView.typingAttributes = savedTypingAttrs
            } else {
                textView.typingAttributes = Coordinator.typingAttributes(
                    font: (savedTypingAttrs[.font] as? NSFont) ?? prefixFallback,
                    alignment: textAlignment,
                    colorScheme: colorScheme
                )
            }
        }

        if context.coordinator.lastSyncedPreferredFont != preferredFontName {
            context.coordinator.lastSyncedPreferredFont = preferredFontName
            context.coordinator.syncPreferredFont(to: textView)
        }

        if isFirstResponder && textView.window?.firstResponder !== textView {
            DispatchQueue.main.async { textView.window?.makeFirstResponder(textView) }
        } else if !isFirstResponder && textView.window?.firstResponder === textView {
            if hasCanvasContent {
                DispatchQueue.main.async { textView.window?.makeFirstResponder(nil) }
            } else {
                DispatchQueue.main.async { context.coordinator.focusBinding?.wrappedValue = true }
            }
        }

        if let command, context.coordinator.lastAppliedCommandId != command.id {
            context.coordinator.lastAppliedCommandId = command.id
            context.coordinator.apply(command: command.action, to: textView)
            context.coordinator.emitFormattingState(textView)
            guard command.action != .selectAll else { return }
            let updatedDisplay = textView.attributedString()
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

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditor
        var lastAppliedCommandId: Int = 0
        var lastSyncedPreferredFont: String = ""
        var lastColorScheme: ColorScheme = .light
        var focusBinding: Binding<Bool>?
        weak var textView: NoteWrappingTextView?
        weak var scrollView: NSScrollView?

        init(parent: RichTextEditor) {
            self.parent = parent
        }

        @objc func handleLinkLongPress(_ gesture: NSPressGestureRecognizer) {
            guard gesture.state == .began, let textView = gesture.view as? NSTextView else { return }
            let point = gesture.location(in: textView)
            guard let layoutManager = textView.layoutManager, let container = textView.textContainer else { return }
            let glyphIndex = layoutManager.glyphIndex(for: point, in: container)
            let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
            guard textView.textStorage?.length ?? 0 > 0 else { return }
            let safeIdx = min(max(0, charIndex), (textView.textStorage?.length ?? 1) - 1)
            var effective = NSRange()
            let link = textView.textStorage?.attribute(.link, at: safeIdx, effectiveRange: &effective)
            guard let url = link as? URL ?? (link as? String).flatMap(URL.init(string:)) else { return }
            guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return }
            parent.onHTTPSImageLinkLongPress(url, point, textView)
        }

        func textDidBeginEditing(_ notification: Notification) {
            focusBinding?.wrappedValue = true
        }

        func textDidEndEditing(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            guard parent.hasCanvasContent else {
                DispatchQueue.main.async { textView.window?.makeFirstResponder(textView) }
                return
            }
            focusBinding?.wrappedValue = false
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            textView.invalidateIntrinsicContentSize()
            let stripped = NoteTextFormatting.stripPrefixesFromDisplayString(textView.attributedString(), mode: parent.linePrefixMode)
            parent.attributedText = stripped
            parent.onChange()
            emitFormattingState(textView)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            emitFormattingState(textView)
            guard parent.linePrefixMode != .none else { return }
            let clamped = clampedSelection(textView.selectedRange(), in: textView)
            if !NSEqualRanges(clamped, textView.selectedRange()) {
                textView.setSelectedRange(clamped)
            }
        }

        func emitFormattingState(_ textView: NSTextView) {
            let attrs = textView.typingAttributes
            let font = attrs[.font] as? NSFont
            let isBold = font?.fontDescriptor.symbolicTraits.contains(.bold) ?? false
            let isItalic = font?.fontDescriptor.symbolicTraits.contains(.italic) ?? false
            let isUnderline = (attrs[.underlineStyle] as? Int ?? 0) != 0
            parent.onFormattingStateChange(isBold, isItalic, isUnderline)
        }

        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            guard parent.linePrefixMode != .none else { return true }
            let locked = NoteTextFormatting.lockedPrefixRanges(in: textView.string as NSString, mode: parent.linePrefixMode)
            if locked.contains(where: { NSIntersectionRange($0, affectedCharRange).length > 0 }) {
                return (replacementString ?? "").isEmpty
            }
            return true
        }

        func syncPreferredFont(to textView: NSTextView) {
            let token = parent.preferredFontName
            let size = (textView.typingAttributes[.font] as? NSFont)?.pointSize ?? parent.pointSize
            let font = EditorFont.platformFont(forToken: token, size: size)
            if textView.string.isEmpty {
                textView.font = font
            }
            textView.typingAttributes[.font] = font
            textView.typingAttributes[.foregroundColor] = NSColor.noteBodyText(for: parent.colorScheme)
            textView.invalidateIntrinsicContentSize()
        }

        func apply(command: TextFormatAction, to textView: NSTextView) {
            let selection = textView.selectedRange()
            let mutable = NSMutableAttributedString(attributedString: textView.attributedString())

            switch command {
            case .bold:
                toggleTrait(.bold, in: mutable, selection: selection, typingAttributes: &textView.typingAttributes)
            case .italic:
                toggleTrait(.italic, in: mutable, selection: selection, typingAttributes: &textView.typingAttributes)
            case .underline:
                toggleUnderline(in: mutable, selection: selection, typingAttributes: &textView.typingAttributes)
            case .font(let token):
                applyFontToken(token, in: mutable, selection: selection, typingAttributes: &textView.typingAttributes)
            case .alignment(let alignment):
                applyAlignment(alignment, in: mutable, selection: selection, typingAttributes: &textView.typingAttributes)
                textView.alignment = alignment.nsTextAlignment
            case .refreshDerivedDisplay:
                break
            case .selectAll:
                DispatchQueue.main.async { [weak textView] in
                    guard let textView else { return }
                    textView.setSelectedRange(NSRange(location: 0, length: textView.textStorage?.length ?? 0))
                    self.emitFormattingState(textView)
                }
                return
            case .fontSize(let size):
                let fullRange = NSRange(location: 0, length: mutable.length)
                mutable.enumerateAttribute(.font, in: fullRange) { value, range, _ in
                    let old = (value as? NSFont) ?? defaultFallbackFont()
                    mutable.addAttribute(.font, value: NSFont(descriptor: old.fontDescriptor, size: size), range: range)
                }
                let currentFont = textView.typingAttributes[.font] as? NSFont ?? defaultFallbackFont()
                let newTypingFont = NSFont(descriptor: currentFont.fontDescriptor, size: size)
                textView.typingAttributes[.font] = newTypingFont
                textView.font = newTypingFont
            case .resetFormatting:
                let fullRange = NSRange(location: 0, length: mutable.length)
                let resetFont = EditorFont.platformFont(forToken: EditorFont.systemBoldStorageToken, size: EditorFont.defaultFontSize)
                mutable.setAttributes(
                    [
                        .font: resetFont,
                        .foregroundColor: NSColor.noteBodyText(for: parent.colorScheme),
                    ],
                    range: fullRange
                )
                textView.typingAttributes = Self.typingAttributes(
                    font: resetFont,
                    alignment: .center,
                    colorScheme: parent.colorScheme
                )
                textView.alignment = .center
                textView.font = resetFont
            }

            textView.textStorage?.setAttributedString(mutable)
            textView.setSelectedRange(selection)
            textView.invalidateIntrinsicContentSize()
        }

        private func defaultFallbackFont() -> NSFont {
            EditorFont.platformFont(forToken: parent.preferredFontName, size: parent.pointSize)
        }

        private func applyFontToken(
            _ token: String,
            in text: NSMutableAttributedString,
            selection: NSRange,
            typingAttributes: inout [NSAttributedString.Key: Any]
        ) {
            if selection.length == 0 {
                let size = (typingAttributes[.font] as? NSFont)?.pointSize ?? parent.pointSize
                typingAttributes[.font] = EditorFont.platformFont(forToken: token, size: size)
                return
            }
            text.enumerateAttribute(.font, in: selection) { value, range, _ in
                let old = (value as? NSFont) ?? defaultFallbackFont()
                let size = old.pointSize
                let base = EditorFont.platformFont(forToken: token, size: size)
                let traits = old.fontDescriptor.symbolicTraits
                let descriptor = base.fontDescriptor.withSymbolicTraits(traits)
                text.addAttribute(.font, value: NSFont(descriptor: descriptor, size: size) ?? base, range: range)
            }
        }

        private func toggleTrait(
            _ trait: NSFontDescriptor.SymbolicTraits,
            in text: NSMutableAttributedString,
            selection: NSRange,
            typingAttributes: inout [NSAttributedString.Key: Any]
        ) {
            guard selection.length > 0 else {
                let currentFont = (typingAttributes[.font] as? NSFont) ?? defaultFallbackFont()
                typingAttributes[.font] = toggledFont(from: currentFont, trait: trait)
                return
            }
            text.enumerateAttribute(.font, in: selection) { value, range, _ in
                let existing = (value as? NSFont) ?? defaultFallbackFont()
                text.addAttribute(.font, value: toggledFont(from: existing, trait: trait), range: range)
            }
        }

        private func toggledFont(from font: NSFont, trait: NSFontDescriptor.SymbolicTraits) -> NSFont {
            var traits = font.fontDescriptor.symbolicTraits
            if traits.contains(trait) {
                traits.remove(trait)
            } else {
                traits.insert(trait)
            }
            let descriptor = font.fontDescriptor.withSymbolicTraits(traits)
            return NSFont(descriptor: descriptor, size: font.pointSize) ?? font
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
            let paragraphStyle = Self.paragraphStyle(for: alignment)
            let applyRange = selection.length > 0 ? selection : NSRange(location: 0, length: text.length)
            if applyRange.length > 0 {
                text.addAttribute(.paragraphStyle, value: paragraphStyle, range: applyRange)
            }
            typingAttributes[.paragraphStyle] = paragraphStyle
        }

        private func clampedSelection(_ selection: NSRange, in textView: NSTextView) -> NSRange {
            let locked = NoteTextFormatting.lockedPrefixRanges(in: textView.string as NSString, mode: parent.linePrefixMode)
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

        func syncTypingAlignment(in textView: NSTextView, colorScheme: ColorScheme) {
            textView.typingAttributes[.paragraphStyle] = Self.paragraphStyle(for: parent.textAlignment)
            textView.typingAttributes[.foregroundColor] = NSColor.noteBodyText(for: colorScheme)
        }

        static func typingAttributes(
            font: NSFont,
            alignment: NoteTextAlignment,
            colorScheme: ColorScheme
        ) -> [NSAttributedString.Key: Any] {
            [
                .font: font,
                .foregroundColor: NSColor.noteBodyText(for: colorScheme),
                .paragraphStyle: paragraphStyle(for: alignment),
            ]
        }

        private static func paragraphStyle(for alignment: NoteTextAlignment) -> NSParagraphStyle {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = alignment.nsTextAlignment
            paragraphStyle.lineBreakMode = .byWordWrapping
            return paragraphStyle
        }
    }

    private static func paragraphStyle(for alignment: NoteTextAlignment) -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment.nsTextAlignment
        paragraphStyle.lineBreakMode = .byWordWrapping
        return paragraphStyle
    }
}

struct ReadOnlyNoteTextView: NSViewRepresentable {
    var attributedText: NSAttributedString
    var textAlignment: NSTextAlignment
    var dataDetectorsEnabled: Bool
    var onDataDetectorInteraction: ((NoteDataDetectorInteraction) -> Void)?
    var onHTTPSImageLinkLongPress: ((URL, CGPoint, NSTextView) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(dataDetectorsEnabled: dataDetectorsEnabled)
    }

    func makeNSView(context: Context) -> NoteWrappingTextView {
        let textView = NoteWrappingTextView()
        textView.isEditable = false
        textView.isRichText = true
        textView.isSelectable = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.alignment = textAlignment
        textView.textContainer?.lineBreakMode = .byWordWrapping
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainerInset = NSSize(width: 0, height: 12)
        textView.isAutomaticLinkDetectionEnabled = dataDetectorsEnabled
        textView.enabledTextCheckingTypes = dataDetectorsEnabled ? NoteDataDetectors.enabledCheckingTypes : 0
        textView.textColor = .noteBodyText
        textView.textStorage?.setAttributedString(attributedText)
        textView.delegate = context.coordinator
        let longPress = NSPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLinkLongPress(_:)))
        longPress.minimumPressDuration = 0.45
        textView.addGestureRecognizer(longPress)
        context.coordinator.onHTTPSImageLinkLongPress = onHTTPSImageLinkLongPress
        context.coordinator.onDataDetectorInteraction = onDataDetectorInteraction
        return textView
    }

    func updateNSView(_ textView: NoteWrappingTextView, context: Context) {
        context.coordinator.dataDetectorsEnabled = dataDetectorsEnabled
        context.coordinator.onHTTPSImageLinkLongPress = onHTTPSImageLinkLongPress
        context.coordinator.onDataDetectorInteraction = onDataDetectorInteraction
        textView.alignment = textAlignment
        textView.isAutomaticLinkDetectionEnabled = dataDetectorsEnabled
        textView.enabledTextCheckingTypes = dataDetectorsEnabled ? NoteDataDetectors.enabledCheckingTypes : 0
        let current = textView.attributedString()
        if !current.isEqual(to: attributedText) {
            textView.textStorage?.setAttributedString(
                NoteTextFormatting.applyingBodyTextColor(attributedText)
            )
            textView.textColor = .noteBodyText
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var dataDetectorsEnabled: Bool
        var onDataDetectorInteraction: ((NoteDataDetectorInteraction) -> Void)?
        var onHTTPSImageLinkLongPress: ((URL, CGPoint, NSTextView) -> Void)?

        init(dataDetectorsEnabled: Bool) {
            self.dataDetectorsEnabled = dataDetectorsEnabled
        }

        func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
            guard dataDetectorsEnabled else { return false }
            let url: URL?
            if let linkURL = link as? URL {
                url = linkURL
            } else if let linkString = link as? String {
                url = URL(string: linkString)
            } else {
                url = nil
            }
            guard let url else { return false }
            var effective = NSRange()
            let storageLength = textView.textStorage?.length ?? 0
            guard storageLength > 0 else { return false }
            let safeIdx = min(max(0, charIndex), storageLength - 1)
            _ = textView.textStorage?.attribute(.link, at: safeIdx, effectiveRange: &effective)
            if effective.length == 0 {
                effective = NSRange(location: safeIdx, length: 1)
            }
            guard let interactionModel = NoteDataDetectorInteraction.make(
                url: url,
                range: effective,
                in: textView.string
            ) else { return false }
            DispatchQueue.main.async { [onDataDetectorInteraction] in
                onDataDetectorInteraction?(interactionModel)
            }
            return true
        }

        @objc fileprivate func handleLinkLongPress(_ gesture: NSPressGestureRecognizer) {
            guard gesture.state == .began, let textView = gesture.view as? NSTextView else { return }
            let point = gesture.location(in: textView)
            guard let layoutManager = textView.layoutManager, let container = textView.textContainer else { return }
            let glyphIndex = layoutManager.glyphIndex(for: point, in: container)
            let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
            guard textView.textStorage?.length ?? 0 > 0 else { return }
            let safeIdx = min(max(0, charIndex), (textView.textStorage?.length ?? 1) - 1)
            var effective = NSRange()
            let link = textView.textStorage?.attribute(.link, at: safeIdx, effectiveRange: &effective)
            guard let url = link as? URL ?? (link as? String).flatMap(URL.init(string:)) else { return }
            guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return }
            onHTTPSImageLinkLongPress?(url, point, textView)
        }
    }
}
#endif
