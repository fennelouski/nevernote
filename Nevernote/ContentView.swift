//
//  ContentView.swift
//  Nevernote
//
//  Created by Nathan Fennel on 4/30/26.
//

import SwiftData
import SwiftUI
import UIKit

private enum NevernoteNotification {
    static let onboardingDidStart = Notification.Name("NNOnboardingDidStartNotification")
    static let onboardingDidComplete = Notification.Name("NNOnboardingDidCompleteNotification")
    static let shakeUndo = Notification.Name("NNShakeUndoNotification")
}

enum ScreenshotPromptStep {
    case chooseShareKind
    case chooseAspect
}

private enum EditorFont {
    /// SwiftUI app only; legacy Obj-C target uses its own defaults suite.
    static let appStorageKey = "nevernote.swiftui.editorFontName"
    static let recentFontsStorageKey = "nevernote.swiftui.recentEditorFontNames"
    static let systemBoldToken = "System Bold"
    static let editorPointSize: CGFloat = 24
    static let maxRecentCount = 5

    static func uiFont(forToken token: String, size: CGFloat) -> UIFont {
        if token == systemBoldToken {
            return UIFont.systemFont(ofSize: size, weight: .bold)
        }
        return UIFont(name: token, size: size)
            ?? UIFont.systemFont(ofSize: size, weight: .bold)
    }

    static var sortedPostScriptNames: [String] {
        let names = Set(UIFont.familyNames.flatMap { UIFont.fontNames(forFamilyName: $0) })
        return names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    static func recentTokens() -> [String] {
        let raw = UserDefaults.standard.stringArray(forKey: recentFontsStorageKey) ?? []
        let valid = Set(sortedPostScriptNames + [systemBoldToken])
        var seen = Set<String>()
        return raw.filter { token in
            guard valid.contains(token) else { return false }
            guard !seen.contains(token) else { return false }
            seen.insert(token)
            return true
        }
    }

    static func recordRecentToken(_ token: String) {
        guard Set(sortedPostScriptNames + [systemBoldToken]).contains(token) else { return }
        var updated = recentTokens().filter { $0 != token }
        updated.insert(token, at: 0)
        if updated.count > maxRecentCount {
            updated = Array(updated.prefix(maxRecentCount))
        }
        UserDefaults.standard.set(updated, forKey: recentFontsStorageKey)
    }
}

private enum NoteDataDetectors {
    static let appStorageKey = "nevernote.dataDetectorsEnabled"
    static let enabledTypes: UIDataDetectorTypes = .all

    static func textWouldTriggerDataDetectors(_ text: String, types: UIDataDetectorTypes = enabledTypes) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let checkingTypes = NSTextCheckingTypes(types.rawValue)
        guard let detector = try? NSDataDetector(types: checkingTypes) else { return false }
        let len = (text as NSString).length
        guard len > 0 else { return false }
        return detector.firstMatch(in: text, options: [], range: NSRange(location: 0, length: len)) != nil
    }
}

private enum EditorToolbarPlacement {
    case inline
    case keyboardAdjacent
}

private enum EditorToolbarChrome {
    /// Toolbar when shown inline in the editor stack (slightly lifted from the canvas).
    static var uiColor: UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark ? .systemGray5 : .systemGray6
        }
    }

    /// QuickType / keyboard plate — aligned lighter toward the system keyboard background.
    static var keyboardShelfUIColor: UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark ? .systemGray5 : .systemGray6
        }
    }
}

/// Full-width layer behind the editor so keyboard-adjacent chrome can read continuous with the system keyboard.
private struct EditorKeyboardShelfBackdrop: View {
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                Rectangle()
                    .fill(Color(uiColor: EditorToolbarChrome.keyboardShelfUIColor))
                    .frame(height: max(360, geo.size.height * 0.42))
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .ignoresSafeArea(.container, edges: .bottom)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NoteDocument.lastEditedAt, order: .reverse) private var notes: [NoteDocument]

    @AppStorage(EditorFont.appStorageKey) private var editorFontName: String = EditorFont.systemBoldToken
    @AppStorage(NoteDataDetectors.appStorageKey) private var dataDetectorsEnabled = false
    @ScaledMetric(relativeTo: .body) private var editorScaledPointSize: CGFloat = EditorFont.editorPointSize

    @State private var attributedText = NSAttributedString(string: "")
    @State private var isEditing = false
    @State private var editorHasFocus = false
    @State private var hasLoadedExistingNote = false
    @State private var commandCounter = 0
    @State private var editorCommand: EditorCommand?
    @State private var showFontPicker = false
    @State private var showLastEditedBanner = true
    @State private var lastEditedBannerScheduleID = UUID()

    @State private var onboardingActive = false
    @State private var showScreenshotPrompt = false
    @State private var screenshotPromptStep: ScreenshotPromptStep = .chooseShareKind
    @State private var lastScreenshotHandledAt = Date.distantPast
    @State private var showActivityShare = false
    @State private var activityItems: [Any] = []
    @State private var textAlignment: NoteTextAlignment = .center
    @State private var maximizePresentationSize = true
    @State private var linePrefixMode: NoteLinePrefixMode = .none
    @State private var isBoldActive = true
    @State private var isItalicActive = false
    @State private var isUnderlineActive = false
    @State private var urlPreviewRefreshToken = 0
    /// When false, keyboard shelf chrome is hidden so a focused field without a visible keyboard does not show a large gray slab.
    @State private var softwareKeyboardVisible = false
    @State private var undoAttributedText: NSAttributedString? = nil

    private var activeNote: NoteDocument? { notes.first }
    private var displayAttributedText: NSAttributedString {
        let prefixFallback = EditorFont.uiFont(forToken: editorFontName, size: editorScaledPointSize)
        return NoteTextFormatting.makeDisplayAttributedText(
            from: attributedText,
            alignment: textAlignment,
            linePrefixMode: linePrefixMode,
            prefixFallbackFont: prefixFallback
        )
    }

    private var useLinePrefixSegmentedControl: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var hasContent: Bool {
        !attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasDetectableContent: Bool {
        NoteDataDetectors.textWouldTriggerDataDetectors(attributedText.string)
    }

    private var bottomPreviewURLKeys: [String] {
        _ = urlPreviewRefreshToken
        guard let note = activeNote else { return [] }
        return NoteHTTPSLinkEnumeration.orderedLinkKeys(in: attributedText) { note.urlShowsImagePreview($0) }
    }

    private var noteExportBackground: UIColor { .noteExportBackground }

    var body: some View {
        ZStack {
            Color.noteCanvas.ignoresSafeArea()

            if isEditing && editorHasFocus && softwareKeyboardVisible {
                EditorKeyboardShelfBackdrop()
            }

            VStack(spacing: 0) {
                if isEditing {
                    topBar
                }

                noteCanvas
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                if isEditing && !editorHasFocus {
                    editorToolbar(placement: .inline)
                }
            }

            if showScreenshotPrompt {
                ScreenshotSharePromptOverlay(
                    step: screenshotPromptStep,
                    onShareText: {
                        activityItems = [attributedText.string]
                        dismissScreenshotPrompt()
                        showActivityShare = true
                    },
                    onChooseImage: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            screenshotPromptStep = .chooseAspect
                        }
                    },
                    onPickAspect: { ratio in
                        if let image = NoteTextImageRenderer.renderImage(
                            attributedText: attributedText,
                            backgroundColor: noteExportBackground,
                            aspect: ratio,
                            alignment: textAlignment,
                            linePrefixMode: linePrefixMode,
                            maximizePresentationSize: maximizePresentationSize
                        ) {
                            activityItems = [image]
                        } else {
                            activityItems = [attributedText.string]
                        }
                        dismissScreenshotPrompt()
                        showActivityShare = true
                    },
                    onCancel: { dismissScreenshotPrompt() }
                )
                .zIndex(2)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isEditing && editorHasFocus {
                editorToolbar(placement: .keyboardAdjacent)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showScreenshotPrompt)
        .animation(.easeInOut(duration: 0.2), value: softwareKeyboardVisible)
        .onAppear {
            ensureSingleNoteExists()
            loadNoteIfNeeded()
            scheduleLastEditedBannerAutoHide()
            focusEditorOnLaunch()
        }
        .onChange(of: notes.count) { _, _ in
            ensureSingleNoteExists()
            loadNoteIfNeeded()
        }
        .onChange(of: editorHasFocus) { _, focused in
            if !focused {
                softwareKeyboardVisible = false
            }
        }
        .onChange(of: textAlignment) { _, _ in persistNote() }
        .onChange(of: linePrefixMode) { _, _ in persistNote() }
        .onChange(of: attributedText) { _, newValue in
            if undoAttributedText != nil && !newValue.string.isEmpty {
                undoAttributedText = nil
                NoteWrappingTextView.customUndoAvailable = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            dismissLastEditedBannerForKeyboardOrTimeout()
            softwareKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            softwareKeyboardVisible = false
        }
        .onReceive(NotificationCenter.default.publisher(for: NevernoteNotification.onboardingDidStart)) { _ in
            onboardingActive = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NevernoteNotification.onboardingDidComplete)) { _ in
            onboardingActive = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
            handleScreenshotDetected()
        }
        .onReceive(NotificationCenter.default.publisher(for: NevernoteNotification.shakeUndo)) { _ in
            restoreNote()
        }
        .sheet(isPresented: $showFontPicker) {
            FontPickerSheet(
                currentToken: editorFontName,
                recentTokens: EditorFont.recentTokens()
            ) { token in
                editorFontName = token
                EditorFont.recordRecentToken(token)
                sendEditorCommand(.font(token))
                showFontPicker = false
            }
        }
        .sheet(isPresented: $showActivityShare) {
            ActivityShareSheet(
                activityItems: activityItems,
                isPresented: $showActivityShare,
                sourceRect: Optional<CGRect>.none
            )
        }
    }

    private func dismissScreenshotPrompt() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showScreenshotPrompt = false
            screenshotPromptStep = .chooseShareKind
        }
    }

    private func handleScreenshotDetected() {
        guard !onboardingActive else { return }
        guard !showActivityShare else { return }
        let now = Date()
        guard now.timeIntervalSince(lastScreenshotHandledAt) > 1.5 else { return }
        lastScreenshotHandledAt = now
        screenshotPromptStep = .chooseShareKind
        withAnimation(.easeInOut(duration: 0.22)) {
            showScreenshotPrompt = true
        }
    }

    private var topBar: some View {
        HStack(spacing: 16) {
            Text("Nevernote")
                .font(.headline)
                .foregroundStyle(.primary)
                .onTapGesture {
                    guard hasContent else { return }
                    if !editorHasFocus {
                        editorHasFocus = true
                    }
                    sendEditorCommand(.selectAll)
                }

            Spacer()

            if hasDetectableContent {
                Button {
                    dataDetectorsEnabled.toggle()
                } label: {
                    Image(systemName: dataDetectorsEnabled ? "link.circle.fill" : "link.circle")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(dataDetectorsEnabled ? Color.brandBlue : Color(.systemGray))
                .accessibilityLabel("Smart links")
            }

            if undoAttributedText != nil {
                Button {
                    restoreNote()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 16, weight: .semibold))
                }
                .accessibilityLabel("Undo delete")
            } else if hasContent {
                Button(role: .destructive) {
                    clearNote()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .semibold))
                }
                .accessibilityLabel("Delete note")

                ShareLink(item: attributedText.string) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                }
                .accessibilityLabel("Share note")
            }
        }
        .foregroundStyle(Color.brandBlue)
        .padding(.horizontal, 18)
        .frame(height: 56)
        .background(Color.topBarBackground.opacity(0.96))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.topBarDivider)
                .frame(height: 1)
        }
    }

    private var noteCanvas: some View {
        VStack(spacing: 18) {
            Group {
                if isEditing {
                    RichTextEditor(
                        attributedText: $attributedText,
                        isFirstResponder: $editorHasFocus,
                        preferredFontName: editorFontName,
                        pointSize: editorScaledPointSize,
                        textAlignment: textAlignment,
                        linePrefixMode: linePrefixMode,
                        command: editorCommand,
                        onHTTPSImageLinkLongPress: { url, point, tv in
                            handleHTTPSImageLinkLongPress(url: url, point: point, textView: tv)
                        },
                        onChange: persistNote,
                        onFormattingStateChange: { bold, italic, underline in
                            DispatchQueue.main.async {
                                isBoldActive = bold
                                isItalicActive = italic
                                isUnderlineActive = underline
                            }
                        }
                    )
                } else {
                    FocusTextView(
                        attributedText: displayAttributedText,
                        textAlignment: textAlignment,
                        maximizePresentationSize: maximizePresentationSize,
                        dataDetectorsEnabled: dataDetectorsEnabled,
                        onHTTPSImageLinkLongPress: { url, point, tv in
                            handleHTTPSImageLinkLongPress(url: url, point: point, textView: tv)
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editorHasFocus = true
                        isEditing = true
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 24)

            if !bottomPreviewURLKeys.isEmpty {
                NoteBottomURLImagePreviews(urlKeys: bottomPreviewURLKeys)
                    .padding(.horizontal, 24)
            }

            if showLastEditedBanner {
                Text(footerText)
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .tracking(2)
                    .foregroundStyle(.secondary)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.96)).combined(with: .offset(y: 4)),
                            removal: .opacity.combined(with: .scale(scale: 0.88)).combined(with: .offset(y: 14))
                        )
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.spring(response: 0.52, dampingFraction: 0.78, blendDuration: 0.15), value: showLastEditedBanner)
    }

    private var editorToolbarControls: some View {
        HStack(spacing: 12) {
            Button(action: { sendEditorCommand(.bold) }) {
                Image(systemName: "bold")
                    .foregroundStyle(isBoldActive ? Color.accentColor : Color.primary)
            }
            .accessibilityLabel("Bold")

            Button(action: { sendEditorCommand(.italic) }) {
                Image(systemName: "italic")
                    .foregroundStyle(isItalicActive ? Color.accentColor : Color.primary)
            }
            .accessibilityLabel("Italic")

            Button(action: { sendEditorCommand(.underline) }) {
                Image(systemName: "underline")
                    .foregroundStyle(isUnderlineActive ? Color.accentColor : Color.primary)
            }
            .accessibilityLabel("Underline")

            Button(action: { showFontPicker = true }) {
                Image(systemName: "textformat")
            }
            .accessibilityLabel("Font")

            Picker("Alignment", selection: $textAlignment) {
                Image(systemName: "text.alignleft").tag(NoteTextAlignment.left)
                Image(systemName: "text.aligncenter").tag(NoteTextAlignment.center)
                Image(systemName: "text.alignright").tag(NoteTextAlignment.right)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 150)
            .onChange(of: textAlignment) { _, value in
                sendEditorCommand(.alignment(value))
            }

            Button(action: {
                maximizePresentationSize.toggle()
            }) {
                Image(systemName: maximizePresentationSize ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
            }
            .accessibilityLabel("Maximize presentation size")

            if useLinePrefixSegmentedControl {
                Picker("Line markers", selection: $linePrefixMode) {
                    Image(systemName: "paragraph").tag(NoteLinePrefixMode.none)
                        .accessibilityLabel("Plain lines")
                    Image(systemName: "list.bullet").tag(NoteLinePrefixMode.bulleted)
                        .accessibilityLabel("Bulleted list")
                    Image(systemName: "list.number").tag(NoteLinePrefixMode.numbered)
                        .accessibilityLabel("Numbered list")
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 150)
                .onChange(of: linePrefixMode) { _, _ in
                    sendEditorCommand(.refreshDerivedDisplay)
                }
            } else {
                Button(action: {
                    linePrefixMode.cycle()
                    sendEditorCommand(.refreshDerivedDisplay)
                }) {
                    Image(systemName: linePrefixMode == .none ? "list.bullet" : (linePrefixMode == .bulleted ? "list.number" : "text.badge.xmark"))
                }
                .accessibilityLabel("Toggle line markers")
            }

            Button("Done") {
                editorHasFocus = false
                isEditing = false
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(Color.brandBlue)
        }
    }

    @ViewBuilder
    private func editorToolbarChromeBackground(placement: EditorToolbarPlacement, shelfActive: Bool) -> some View {
        switch placement {
        case .keyboardAdjacent:
            if shelfActive {
                Rectangle()
                    .fill(Color(uiColor: EditorToolbarChrome.keyboardShelfUIColor))
                    .ignoresSafeArea(.container, edges: .bottom)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            } else {
                Rectangle()
                    .fill(Color(uiColor: EditorToolbarChrome.uiColor))
            }
        case .inline:
            Rectangle()
                .fill(Color(uiColor: EditorToolbarChrome.uiColor))
        }
    }

    @ViewBuilder
    private func editorToolbar(placement: EditorToolbarPlacement) -> some View {
        let shelfActive = placement == .keyboardAdjacent && softwareKeyboardVisible
        let chrome = editorToolbarControls
            .padding(.horizontal, 22)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background { editorToolbarChromeBackground(placement: placement, shelfActive: shelfActive) }

        switch placement {
        case .keyboardAdjacent:
            chrome.clipShape(Rectangle())
        case .inline:
            chrome
        }
    }

    private var footerText: String {
        if let note = activeNote {
            return "LAST EDITED \(RelativeDateTimeFormatter().localizedString(for: note.lastEditedAt, relativeTo: .now))."
        }
        return "NEVERNOTE FOCUS"
    }

    private func scheduleLastEditedBannerAutoHide() {
        showLastEditedBanner = true
        let scheduleID = UUID()
        lastEditedBannerScheduleID = scheduleID
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            guard lastEditedBannerScheduleID == scheduleID else { return }
            withAnimation(.spring(response: 0.52, dampingFraction: 0.78, blendDuration: 0.15)) {
                showLastEditedBanner = false
            }
        }
    }

    private func dismissLastEditedBannerForKeyboardOrTimeout() {
        lastEditedBannerScheduleID = UUID()
        guard showLastEditedBanner else { return }
        withAnimation(.spring(response: 0.52, dampingFraction: 0.78, blendDuration: 0.15)) {
            showLastEditedBanner = false
        }
    }

    private func focusEditorOnLaunch() {
        isEditing = true
        // Delay one run-loop so the UITextView exists before requesting first responder.
        DispatchQueue.main.async {
            editorHasFocus = true
        }
    }

    private func ensureSingleNoteExists() {
        guard notes.isEmpty else { return }
        let newNote = NoteDocument()
        modelContext.insert(newNote)
        try? modelContext.save()
    }

    private func loadNoteIfNeeded() {
        guard let note = activeNote, !hasLoadedExistingNote else { return }
        if let decoded = NoteRichTextCodec.decode(note.richTextData), decoded.length > 0 {
            attributedText = decoded
        } else if !note.plainText.isEmpty {
            attributedText = NSAttributedString(string: note.plainText)
        }
        textAlignment = NoteTextAlignment(rawValue: note.textAlignmentRawValue ?? "center") ?? .center
        linePrefixMode = NoteLinePrefixMode(rawValue: note.linePrefixModeRawValue ?? "none") ?? .none
        hasLoadedExistingNote = true
    }

    private func clearNote() {
        undoAttributedText = attributedText
        NoteWrappingTextView.customUndoAvailable = true
        attributedText = NSAttributedString(string: "")
        persistNote()
    }

    private func restoreNote() {
        guard let saved = undoAttributedText else { return }
        undoAttributedText = nil
        NoteWrappingTextView.customUndoAvailable = false
        attributedText = saved
        persistNote()
    }

    private func persistNote() {
        guard let note = activeNote else { return }
        note.lastEditedAt = .now
        note.plainText = attributedText.string
        note.pruneURLImagePreviewEntries(notContainedIn: note.plainText)
        note.richTextData = NoteRichTextCodec.encode(attributedText) ?? Data()
        note.textAlignmentRawValue = textAlignment.rawValue
        note.linePrefixModeRawValue = linePrefixMode.rawValue
        try? modelContext.save()
    }

    private func handleHTTPSImageLinkLongPress(url: URL, point: CGPoint, textView: UITextView) {
        let key = NoteDocument.normalizedURLKey(url)
        guard let vc = textView.nearestViewController() else { return }

        let loading = UIAlertController(title: nil, message: "Checking image…", preferredStyle: .alert)
        vc.present(loading, animated: true)

        NoteImageURLPrefetcher.prefetchImage(from: url) { result in
            loading.dismiss(animated: true) {
                switch result {
                case .success:
                    let current = activeNote?.urlShowsImagePreview(key) ?? false
                    let sheet = UIAlertController(
                        title: "Image link",
                        message: "Show this image below the note?",
                        preferredStyle: .actionSheet
                    )
                    let toggleTitle = current ? "Hide image at bottom" : "Show image at bottom"
                    sheet.addAction(UIAlertAction(title: toggleTitle, style: .default) { _ in
                        activeNote?.setURLShowsImagePreview(key, show: !current)
                        urlPreviewRefreshToken &+= 1
                        persistNote()
                    })
                    sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                    if let pop = sheet.popoverPresentationController {
                        pop.sourceView = textView
                        pop.sourceRect = CGRect(x: point.x, y: point.y, width: 1, height: 1)
                        pop.permittedArrowDirections = [.up, .down]
                    }
                    vc.present(sheet, animated: true)
                case .failure(let error):
                    let alert = UIAlertController(
                        title: "Can't use this link as an image",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    vc.present(alert, animated: true)
                }
            }
        }
    }

    private func sendEditorCommand(_ action: TextFormatAction) {
        commandCounter += 1
        editorCommand = EditorCommand(id: commandCounter, action: action)
    }

}

private struct NoteBottomURLImagePreviews: View {
    let urlKeys: [String]

    var body: some View {
        VStack(spacing: 14) {
            ForEach(urlKeys, id: \.self) { key in
                if let url = URL(string: key) {
                    NoteBottomURLImageRow(url: url)
                }
            }
        }
    }
}

private struct NoteBottomURLImageRow: View {
    let url: URL
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity)
        .task(id: url) {
            if let cached = NoteImageURLPrefetcher.cachedImage(for: url) {
                image = cached
                return
            }
            NoteImageURLPrefetcher.prefetchImage(from: url) { result in
                if case .success(let img) = result {
                    image = img
                }
            }
        }
    }
}

private extension UIView {
    func nearestViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let vc = current as? UIViewController { return vc }
            responder = current.next
        }
        return nil
    }
}

private struct FontPickerSheet: View {
    let currentToken: String
    let recentTokens: [String]
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @ScaledMetric(relativeTo: .body) private var previewPointSize: CGFloat = EditorFont.editorPointSize

    private var filteredRecentFonts: [String] {
        recentTokens
            .filter { $0 != EditorFont.systemBoldToken }
            .filter { EditorFont.sortedPostScriptNames.contains($0) }
            .filter(matchesQuery)
    }

    private var filteredAllFonts: [String] {
        let excluded = Set(filteredRecentFonts)
        let all = EditorFont.sortedPostScriptNames.filter { !excluded.contains($0) }
        guard !searchQuery.isEmpty else { return all }
        return all.filter(matchesQuery)
    }

    private var searchQuery: String {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return q
    }

    private var shouldShowSystemBold: Bool {
        searchQuery.isEmpty || EditorFont.systemBoldToken.localizedCaseInsensitiveContains(searchQuery)
    }

    private func matchesQuery(_ token: String) -> Bool {
        guard !searchQuery.isEmpty else { return true }
        return token.localizedCaseInsensitiveContains(searchQuery)
    }

    var body: some View {
        NavigationStack {
            List {
                if shouldShowSystemBold {
                    Section {
                        fontRow(title: EditorFont.systemBoldToken, token: EditorFont.systemBoldToken)
                    }
                }

                if !filteredRecentFonts.isEmpty {
                    Section("Recent") {
                        ForEach(filteredRecentFonts, id: \.self) { name in
                            fontRow(title: name, token: name)
                        }
                    }
                }

                if !filteredAllFonts.isEmpty {
                    Section("All Fonts") {
                        ForEach(filteredAllFonts, id: \.self) { name in
                            fontRow(title: name, token: name)
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "Search fonts")
            .navigationTitle("Font")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func fontRow(title: String, token: String) -> some View {
        Button {
            onSelect(token)
        } label: {
            HStack {
                Text(title)
                    .font(Font(EditorFont.uiFont(forToken: token, size: previewPointSize)))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                Spacer()
                if token == currentToken {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.brandBlue)
                }
            }
        }
    }
}

private struct ReadOnlyNoteTextView: UIViewRepresentable {
    var attributedText: NSAttributedString
    var textAlignment: NSTextAlignment
    var dataDetectorTypes: UIDataDetectorTypes
    var onHTTPSImageLinkLongPress: ((URL, CGPoint, UITextView) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator()
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
        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLinkLongPress(_:)))
        longPress.minimumPressDuration = 0.45
        textView.addGestureRecognizer(longPress)
        context.coordinator.onHTTPSImageLinkLongPress = onHTTPSImageLinkLongPress
        return textView
    }

    func updateUIView(_ uiView: NoteWrappingTextView, context: Context) {
        context.coordinator.onHTTPSImageLinkLongPress = onHTTPSImageLinkLongPress
        uiView.textAlignment = textAlignment
        uiView.dataDetectorTypes = dataDetectorTypes
        if !(uiView.attributedText?.isEqual(to: attributedText) ?? false) {
            uiView.attributedText = attributedText
            uiView.textColor = .noteBodyText
        }
    }

    final class Coordinator: NSObject {
        var onHTTPSImageLinkLongPress: ((URL, CGPoint, UITextView) -> Void)?

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

private struct FocusTextView: View {
    let attributedText: NSAttributedString
    let textAlignment: NoteTextAlignment
    let maximizePresentationSize: Bool
    var dataDetectorsEnabled: Bool
    var onHTTPSImageLinkLongPress: ((URL, CGPoint, UITextView) -> Void)?

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let availableHeight = max(proxy.size.height, 1)
            let fitted = fittedAttributedText(maxWidth: width, maxHeight: availableHeight)

            ReadOnlyNoteTextView(
                attributedText: fitted,
                textAlignment: textAlignment.nsTextAlignment,
                dataDetectorTypes: dataDetectorsEnabled ? NoteDataDetectors.enabledTypes : [],
                onHTTPSImageLinkLongPress: onHTTPSImageLinkLongPress
            )
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
        if maximizePresentationSize {
            return maximizeToFit(maxWidth: maxWidth, maxHeight: maxHeight)
        }

        let measuredHeight = max(measureHeight(of: attributedText, constrainedTo: maxWidth), 1)
        let scale = min(1.0, maxHeight / measuredHeight)
        return scaleFonts(in: attributedText, scale: scale)
    }

    private func maximizeToFit(maxWidth: CGFloat, maxHeight: CGFloat) -> NSAttributedString {
        var low: CGFloat = 0.08
        var high: CGFloat = 10.0
        for _ in 0 ..< 22 {
            let mid = (low + high) / 2
            let candidate = scaleFonts(in: attributedText, scale: mid)
            if measureHeight(of: candidate, constrainedTo: maxWidth) <= maxHeight {
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

    private func scaleFonts(in text: NSAttributedString, scale: CGFloat) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: text)
        let full = NSRange(location: 0, length: mutable.length)
        mutable.enumerateAttribute(.font, in: full) { value, range, _ in
            guard let font = value as? UIFont else { return }
            let newSize = max(6, font.pointSize * scale)
            mutable.addAttribute(.font, value: UIFont(descriptor: font.fontDescriptor, size: newSize), range: range)
        }
        return mutable
    }
}

private enum TextFormatAction: Equatable {
    case bold
    case italic
    case underline
    case font(String)
    case alignment(NoteTextAlignment)
    case refreshDerivedDisplay
    case selectAll
}

private struct EditorCommand: Equatable {
    let id: Int
    let action: TextFormatAction
}

/// `UITextView` + SwiftUI often reports a huge intrinsic width (single-line width), so the editor grows past the screen.
/// This subclass pins the text container to the laid-out width and only contributes intrinsic height.
private final class NoteWrappingTextView: UITextView {
    private static let pastedImageFontSize: CGFloat = 24
    static var customUndoAvailable = false

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

private struct RichTextEditor: UIViewRepresentable {
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

    func makeUIView(context: Context) -> NoteWrappingTextView {
        let textView = NoteWrappingTextView()
        textView.delegate = context.coordinator
        textView.allowsEditingTextAttributes = true
        textView.isScrollEnabled = true
        textView.showsVerticalScrollIndicator = false
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
            uiView.attributedText = display
            uiView.textColor = .noteBodyText
        }

        if context.coordinator.lastSyncedPreferredFont != preferredFontName {
            context.coordinator.lastSyncedPreferredFont = preferredFontName
            context.coordinator.syncPreferredFont(to: uiView)
        }

        if isFirstResponder && !uiView.isFirstResponder {
            DispatchQueue.main.async { uiView.becomeFirstResponder() }
        } else if !isFirstResponder && uiView.isFirstResponder {
            DispatchQueue.main.async { uiView.resignFirstResponder() }
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

#Preview {
    ContentView()
        .modelContainer(for: NoteDocument.self, inMemory: true)
}
