//
//  ContentView.swift
//  Nevernote
//
//  Created by Nathan Fennel on 4/30/26.
//

import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.locale) private var locale
    @Query(sort: \NoteDocument.lastEditedAt, order: .reverse) private var notes: [NoteDocument]

    @AppStorage(EditorFont.appStorageKey) private var editorFontName: String = EditorFont.systemBoldStorageToken
    @AppStorage(NoteDataDetectors.appStorageKey) private var dataDetectorsEnabled = false
    @AppStorage(EditorFont.fontSizeAppStorageKey) private var _editorStoredPointSizeRaw: Double = Double(EditorFont.defaultFontSize)
    private var editorStoredPointSize: CGFloat {
        get { CGFloat(_editorStoredPointSizeRaw) }
        nonmutating set { _editorStoredPointSizeRaw = Double(newValue) }
    }
    private var editorScaledPointSize: CGFloat { editorStoredPointSize }

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

    @State private var capturedImage: PlatformImage? = nil
    @State private var showEducationalModal = false
    @State private var showPhotoPicker = false
    @State private var showCameraPicker = false
    @State private var fullScreenImagePresentation: FullScreenImagePresentation?
    @State private var showImageSourceChooser = false
    @State private var pendingDataDetectorInteraction: NoteDataDetectorInteraction?
    @State private var isProcessingImage = false
    @State private var permissionManager = NoteImagePermissionManager()
    #if os(macOS)
    @State private var macSidePanel: MacInspectorPanel?
    @State private var macConfirmationOnConfirm: (() -> Void)?
    #endif

    private var activeNote: NoteDocument? { notes.first }
    private var displayAttributedText: NSAttributedString {
        let prefixFallback = EditorFont.platformFont(forToken: editorFontName, size: editorScaledPointSize)
        return NoteTextFormatting.makeDisplayAttributedText(
            from: attributedText,
            alignment: textAlignment,
            linePrefixMode: linePrefixMode,
            prefixFallbackFont: prefixFallback
        )
    }

    private var useLinePrefixSegmentedControl: Bool {
        NeverNotePlatform.isPad
    }

    private var hasContent: Bool {
        !attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasDeletableContent: Bool {
        hasContent || capturedImage != nil
    }

    private var hasDetectableContent: Bool {
        NoteDataDetectors.textWouldTriggerDataDetectors(attributedText.string)
    }

    private var bottomPreviewURLKeys: [String] {
        _ = urlPreviewRefreshToken
        guard let note = activeNote else { return [] }
        return NoteHTTPSLinkEnumeration.orderedLinkKeys(in: attributedText) { note.urlShowsImagePreview($0) }
    }

    private var noteExportBackground: PlatformColor {
        #if canImport(UIKit)
        .noteExportBackground
        #else
        .noteExportBackground
        #endif
    }

    var body: some View {
        ZStack {
            Color.noteCanvas.ignoresSafeArea()

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

            if !isEditing, NeverNoteKeyboardShortcuts.isEnabled {
                Button {
                    editorHasFocus = true
                    isEditing = true
                } label: {
                    EmptyView()
                }
                .neverNoteShortcut(.beginEditing)
                .frame(width: 0, height: 0)
                .opacity(0)
                .accessibilityHidden(true)
            }

            if showScreenshotPrompt {
                ScreenshotSharePromptOverlay(
                    step: screenshotPromptStep,
                    onShareText: {
                        activityItems = [attributedText.string]
                        dismissScreenshotPrompt()
                        showActivitySharePanel()
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
                        showActivitySharePanel()
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
        #if os(iOS)
        .statusBarHidden(!isEditing)
        #endif
        .animation(.easeInOut(duration: 0.22), value: showScreenshotPrompt)
        .animation(.easeInOut(duration: 0.2), value: softwareKeyboardVisible)
        .onAppear {
            migrateEditorFontStorageIfNeeded()
            ensureSingleNoteExists()
            loadNoteIfNeeded()
            permissionManager.refreshStatus()
            if let config = ScreenshotMode.config {
                isEditing = config.showKeyboard
                if config.showKeyboard {
                    DispatchQueue.main.async { editorHasFocus = true }
                }
            } else {
                scheduleLastEditedBannerAutoHide()
                focusEditorOnLaunch()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { permissionManager.refreshStatus() }
        }
        .onChange(of: notes.count) { _, _ in
            ensureSingleNoteExists()
            loadNoteIfNeeded()
        }
        .onChange(of: editorHasFocus) { _, focused in
            if !focused {
                softwareKeyboardVisible = false
                if !hasContent {
                    DispatchQueue.main.async { editorHasFocus = true }
                }
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
        #if canImport(UIKit)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            dismissLastEditedBannerForKeyboardOrTimeout()
            softwareKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            softwareKeyboardVisible = false
        }
        #endif
        .onReceive(NotificationCenter.default.publisher(for: NevernoteNotification.onboardingDidStart)) { _ in
            onboardingActive = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NevernoteNotification.onboardingDidComplete)) { _ in
            onboardingActive = false
        }
        .onReceive(NotificationCenter.default.publisher(for: NeverNotePlatform.screenshotNotification)) { _ in
            handleScreenshotDetected()
        }
        .onReceive(NotificationCenter.default.publisher(for: NevernoteNotification.shakeUndo)) { _ in
            restoreNote()
        }
        #if !os(macOS)
        .sheet(isPresented: $showFontPicker) {
            FontPickerSheet(
                currentToken: editorFontName,
                currentSize: editorStoredPointSize,
                recentTokens: EditorFont.recentTokens()
            ) { token in
                let normalized = EditorFont.normalizedFontToken(token)
                editorFontName = normalized
                EditorFont.recordRecentToken(normalized)
                sendEditorCommand(.font(token))
                showFontPicker = false
            } onSelectSize: { size in
                editorStoredPointSize = size
                sendEditorCommand(.fontSize(size))
            } onReset: {
                editorFontName = EditorFont.systemBoldStorageToken
                editorStoredPointSize = EditorFont.defaultFontSize
                textAlignment = .center
                linePrefixMode = .none
                isBoldActive = true
                isItalicActive = false
                isUnderlineActive = false
                sendEditorCommand(.resetFormatting)
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
        .sheet(isPresented: $showEducationalModal) {
            NoteImageEducationalModal(permissionManager: permissionManager) {
                launchImagePicker()
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            NotePhotoPicker { image in
                Task { await handleImageSelected(image) }
            }
        }
        #endif
        #if os(iOS)
        .sheet(isPresented: $showCameraPicker) {
            NoteCameraPicker { image in
                Task { await handleImageSelected(image) }
            }
        }
        .fullScreenCover(item: $fullScreenImagePresentation) { presentation in
            NoteImageFullScreenModal(image: presentation.image) {
                fullScreenImagePresentation = nil
            }
        }
        #elseif !os(macOS)
        .sheet(item: $fullScreenImagePresentation) { presentation in
            NoteImageFullScreenModal(image: presentation.image) {
                fullScreenImagePresentation = nil
            }
        }
        #endif
        #if os(macOS)
        .neverNoteMacInspector(
            panel: $macSidePanel,
            shareItems: $activityItems,
            permissionManager: permissionManager,
            editorFontName: editorFontName,
            editorStoredPointSize: editorStoredPointSize,
            onImageSelected: { image in
                Task { await handleImageSelected(image) }
            },
            onEducationComplete: {
                macSidePanel = .photoImport
            },
            onFontSelect: { token in
                let normalized = EditorFont.normalizedFontToken(token)
                editorFontName = normalized
                EditorFont.recordRecentToken(normalized)
                sendEditorCommand(.font(token))
                macSidePanel = nil
            },
            onFontSelectSize: { size in
                editorStoredPointSize = size
                sendEditorCommand(.fontSize(size))
            },
            onFontReset: {
                editorFontName = EditorFont.systemBoldStorageToken
                editorStoredPointSize = EditorFont.defaultFontSize
                textAlignment = .center
                linePrefixMode = .none
                isBoldActive = true
                isItalicActive = false
                isUnderlineActive = false
                sendEditorCommand(.resetFormatting)
                macSidePanel = nil
            },
            onConfirmationConfirm: {
                macConfirmationOnConfirm?()
                macConfirmationOnConfirm = nil
            }
        )
        #endif
        .confirmationDialog("Add Photo", isPresented: $showImageSourceChooser) {
            #if os(iOS)
            Button("Camera") { showCameraPicker = true }
                .neverNoteShortcut(.openCamera)
            #endif
            Button("Photo Library") { showPhotoPicker = true }
                .neverNoteShortcut(.openPhotoLibrary)
            Button("Cancel", role: .cancel) {}
                .neverNoteShortcut(.cancel)
        }
        .noteDataDetectorConfirmationDialog(item: $pendingDataDetectorInteraction)
        .focusedSceneValue(\.neverNoteCommandHandlers, neverNoteCommandHandlers)
    }

    private var neverNoteCommandHandlers: NeverNoteCommandHandlers {
        var handlers = NeverNoteCommandHandlers()

        handlers.selectAll = .when(hasContent) { sendEditorCommand(.selectAll) }
        handlers.toggleSmartLinks = .when(hasDetectableContent) { dataDetectorsEnabled.toggle() }
        handlers.importPhoto = .when(!hasContent && capturedImage == nil && permissionManager.state != .denied) {
            handleCameraButtonTapped()
        }
        #if os(iOS)
        handlers.openPhotoLibrary = .when(showImageSourceChooser) { showPhotoPicker = true }
        handlers.openCamera = .when(showImageSourceChooser) { showCameraPicker = true }
        #elseif os(macOS)
        handlers.openPhotoLibrary = .when(showImageSourceChooser) { macSidePanel = .photoImport }
        #endif
        if let capturedImage {
            handlers.viewCapturedImage = .when(true) { showCapturedImagePreview(capturedImage) }
        }
        handlers.undoDelete = .when(undoAttributedText != nil) { restoreNote() }
        handlers.deleteNote = .when(hasDeletableContent && undoAttributedText == nil) { clearNote() }
        handlers.shareNote = .when(hasContent && undoAttributedText == nil) {
            activityItems = [attributedText.string]
            showActivitySharePanel()
        }
        handlers.beginEditing = .when(!isEditing) {
            editorHasFocus = true
            isEditing = true
        }
        handlers.bold = .when(isEditing) { sendEditorCommand(.bold) }
        handlers.italic = .when(isEditing) { sendEditorCommand(.italic) }
        handlers.underline = .when(isEditing) { sendEditorCommand(.underline) }
        handlers.fontPicker = .when(isEditing) { showFontPickerPanel() }
        handlers.togglePresentationSize = .when(isEditing) { maximizePresentationSize.toggle() }
        handlers.alignLeft = .when(isEditing) { applyToolbarAlignment(.left) }
        handlers.alignCenter = .when(isEditing) { applyToolbarAlignment(.center) }
        handlers.alignRight = .when(isEditing) { applyToolbarAlignment(.right) }
        handlers.linePrefixNone = .when(isEditing) { applyToolbarLinePrefix(.none) }
        handlers.linePrefixBulleted = .when(isEditing) { applyToolbarLinePrefix(.bulleted) }
        handlers.linePrefixNumbered = .when(isEditing) { applyToolbarLinePrefix(.numbered) }
        handlers.cycleLinePrefix = .when(isEditing && !useLinePrefixSegmentedControl) {
            linePrefixMode.cycle()
            sendEditorCommand(.refreshDerivedDisplay)
        }
        handlers.dismissKeyboard = .when(isEditing && hasContent) { dismissEditorIfAllowed() }
        #if os(macOS)
        handlers.resetFormatting = .when(macSidePanel == .fontPicker) { resetEditorFormattingFromMenu() }
        #else
        handlers.resetFormatting = .when(showFontPicker) { resetEditorFormattingFromMenu() }
        #endif

        if showScreenshotPrompt {
            switch screenshotPromptStep {
            case .chooseShareKind:
                handlers.shareScreenshotText = .when(true) {
                    activityItems = [attributedText.string]
                    dismissScreenshotPrompt()
                    showActivitySharePanel()
                }
                handlers.shareScreenshotImage = .when(true) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        screenshotPromptStep = .chooseAspect
                    }
                }
            case .chooseAspect:
                handlers.screenshotAspectPortrait = screenshotAspectAction(.portrait3_4)
                handlers.screenshotAspectStory = screenshotAspectAction(.story9_16)
                handlers.screenshotAspectSquare = screenshotAspectAction(.square1_1)
                handlers.screenshotAspectLandscape16x9 = screenshotAspectAction(.landscape16_9)
                handlers.screenshotAspectLandscape4x3 = screenshotAspectAction(.landscape4_3)
            }
            handlers.cancel = .when(true) { dismissScreenshotPrompt() }
        }

        if let interaction = pendingDataDetectorInteraction {
            handlers.continueAction = .when(true) {
                interaction.performPrimaryAction()
                pendingDataDetectorInteraction = nil
            }
            handlers.copy = .when(true) {
                NoteDataDetectorInteraction.copyToPasteboard(interaction.copyText)
                pendingDataDetectorInteraction = nil
            }
            handlers.cancel = .when(true) { pendingDataDetectorInteraction = nil }
        }

        #if os(macOS)
        if macSidePanel == .imageEducation {
            handlers.continueAction = .when(true) { continueFromEducationalModal() }
            handlers.cancel = .when(true) { macSidePanel = nil }
        }
        if case .capturedImage = macSidePanel {
            handlers.closeImage = .when(true) { macSidePanel = nil }
        }
        if case .confirmation = macSidePanel {
            handlers.continueAction = .when(true) {
                macConfirmationOnConfirm?()
                macConfirmationOnConfirm = nil
                macSidePanel = nil
            }
            handlers.cancel = .when(true) {
                macConfirmationOnConfirm = nil
                macSidePanel = nil
            }
        }
        #else
        if showEducationalModal {
            handlers.continueAction = .when(true) { continueFromEducationalModal() }
            handlers.cancel = .when(true) { showEducationalModal = false }
        }
        if fullScreenImagePresentation != nil {
            handlers.closeImage = .when(true) { fullScreenImagePresentation = nil }
        }
        #endif

        return handlers
    }

    private func screenshotAspectAction(_ ratio: NoteExportAspectRatio) -> NeverNoteMenuAction {
        .when(showScreenshotPrompt && screenshotPromptStep == .chooseAspect) {
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
            showActivitySharePanel()
        }
    }

    private func resetEditorFormattingFromMenu() {
        editorFontName = EditorFont.systemBoldStorageToken
        editorStoredPointSize = EditorFont.defaultFontSize
        textAlignment = .center
        linePrefixMode = .none
        isBoldActive = true
        isItalicActive = false
        isUnderlineActive = false
        sendEditorCommand(.resetFormatting)
        #if os(macOS)
        macSidePanel = nil
        #else
        showFontPicker = false
        #endif
    }

    private func continueFromEducationalModal() {
        NoteImageEducationalModal.recordShown()
        #if os(macOS)
        macSidePanel = nil
        Task {
            await permissionManager.requestPhotoLibrary()
            await MainActor.run { macSidePanel = .photoImport }
        }
        #else
        showEducationalModal = false
        Task {
            await permissionManager.requestBoth()
            await MainActor.run { launchImagePicker() }
        }
        #endif
    }

    private func dismissScreenshotPrompt() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showScreenshotPrompt = false
            screenshotPromptStep = .chooseShareKind
        }
    }

    private func handleScreenshotDetected() {
        guard !onboardingActive else { return }
        #if os(macOS)
        guard macSidePanel == nil else { return }
        #else
        guard !showActivityShare else { return }
        #endif
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
                .foregroundStyle(dataDetectorsEnabled ? Color.brandBlue : Color.secondary)
                .accessibilityLabel("Smart links")
                .neverNoteShortcut(.toggleSmartLinks)
            }

            if let capturedImage {
                Button {
                    showCapturedImagePreview(capturedImage)
                } label: {
                    platformThumbnail(capturedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.3), lineWidth: 1))
                }
                .accessibilityLabel("View captured image")
                .neverNoteShortcut(.viewCapturedImage)
            } else if !hasContent && permissionManager.state != .denied {
                Button {
                    handleCameraButtonTapped()
                } label: {
                    if isProcessingImage {
                        ProgressView()
                            .tint(Color.brandBlue)
                    } else {
                        Image(systemName: cameraButtonIcon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .accessibilityLabel("Import text from photo")
                .neverNoteShortcut(.importPhoto)
            }

            if undoAttributedText != nil {
                Button {
                    restoreNote()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 16, weight: .semibold))
                }
                .accessibilityLabel("Undo delete")
                .neverNoteShortcut(.undoDelete)
            } else if hasDeletableContent {
                Button(role: .destructive) {
                    clearNote()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .semibold))
                }
                .accessibilityLabel("Delete note")
                .neverNoteShortcut(.deleteNote)

                if hasContent {
                    ShareLink(item: attributedText.string) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .accessibilityLabel("Share note")
                    .neverNoteShortcut(.shareNote)
                }
            }
        }
        .foregroundStyle(Color.brandBlue)
        .padding(.horizontal, 18)
        .frame(minHeight: 56)
        .background {
            Color.topBarBackground
                .ignoresSafeArea(edges: .top)
        }
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
                        onDataDetectorInteraction: { interaction in
                            pendingDataDetectorInteraction = interaction
                        },
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
                    .tracking(footerLetterSpacing)
                    .foregroundStyle(.secondary)
                    .neverNoteWrappingLabel()
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
        ViewThatFits(in: .horizontal) {
            editorToolbarFullRow
            editorToolbarCompactRow
        }
    }

    private var editorToolbarFullRow: some View {
        HStack(spacing: 12) {
            primaryFormattingButtons
            alignmentSegmentedControl
            linePrefixControl
            editorDoneButton
        }
    }

    private var editorToolbarCompactRow: some View {
        HStack(spacing: 8) {
            primaryFormattingButtons
            Spacer(minLength: 8)
            formattingOverflowMenu
            editorDoneButton
        }
    }

    @ViewBuilder
    private var primaryFormattingButtons: some View {
        Button(action: { sendEditorCommand(.bold) }) {
            Image(systemName: "bold")
                .foregroundStyle(isBoldActive ? Color.accentColor : Color.primary)
        }
        .accessibilityLabel("Bold")
        .neverNoteShortcut(.bold)

        Button(action: { sendEditorCommand(.underline) }) {
            Image(systemName: "underline")
                .foregroundStyle(isUnderlineActive ? Color.accentColor : Color.primary)
        }
        .accessibilityLabel("Underline")
        .neverNoteShortcut(.underline)

        Button(action: { sendEditorCommand(.italic) }) {
            Image(systemName: "italic")
                .foregroundStyle(isItalicActive ? Color.accentColor : Color.primary)
        }
        .accessibilityLabel("Italic")
        .neverNoteShortcut(.italic)

        Button(action: showFontPickerPanel) {
            Image(systemName: "textformat")
        }
        .accessibilityLabel("Font")
        .neverNoteShortcut(.fontPicker)

        Button(action: {
            maximizePresentationSize.toggle()
        }) {
            Image(systemName: maximizePresentationSize ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
        }
        .accessibilityLabel("Maximize presentation size")
        .neverNoteShortcut(.togglePresentationSize)
    }

    private var alignmentSegmentedControl: some View {
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
    }

    @ViewBuilder
    private var linePrefixControl: some View {
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
            .neverNoteShortcut(.cycleLinePrefix)
        }
    }

    private var formattingOverflowMenu: some View {
        Menu {
            Button {
                applyToolbarAlignment(.left)
            } label: {
                overflowMenuRow(symbol: "text.alignleft", isSelected: textAlignment == .left)
            }
            .accessibilityLabel("Align left")
            .neverNoteShortcut(.alignLeft)

            Button {
                applyToolbarAlignment(.center)
            } label: {
                overflowMenuRow(symbol: "text.aligncenter", isSelected: textAlignment == .center)
            }
            .accessibilityLabel("Align center")
            .neverNoteShortcut(.alignCenter)

            Button {
                applyToolbarAlignment(.right)
            } label: {
                overflowMenuRow(symbol: "text.alignright", isSelected: textAlignment == .right)
            }
            .accessibilityLabel("Align right")
            .neverNoteShortcut(.alignRight)

            Divider()

            Button {
                applyToolbarLinePrefix(.none)
            } label: {
                overflowMenuRow(symbol: "paragraph", isSelected: linePrefixMode == .none)
            }
            .accessibilityLabel("Plain lines")
            .neverNoteShortcut(.linePrefixNone)

            Button {
                applyToolbarLinePrefix(.bulleted)
            } label: {
                overflowMenuRow(symbol: "list.bullet", isSelected: linePrefixMode == .bulleted)
            }
            .accessibilityLabel("Bulleted list")
            .neverNoteShortcut(.linePrefixBulleted)

            Button {
                applyToolbarLinePrefix(.numbered)
            } label: {
                overflowMenuRow(symbol: "list.number", isSelected: linePrefixMode == .numbered)
            }
            .accessibilityLabel("Numbered list")
            .neverNoteShortcut(.linePrefixNumbered)
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundStyle(Color.primary)
        }
        .accessibilityLabel("More formatting")
    }

    private var editorDoneButton: some View {
        Button(action: dismissEditorIfAllowed) {
            Image(systemName: "keyboard.chevron.compact.down")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(hasContent ? Color.brandBlue : Color.brandBlue.opacity(0.35))
        }
        .disabled(!hasContent)
        .accessibilityLabel("Done")
        .accessibilityHint(hasContent ? "Hide keyboard" : "Enter text before dismissing the keyboard")
        .neverNoteShortcut(.dismissKeyboard)
    }

    private func dismissEditorIfAllowed() {
        guard hasContent else { return }
        editorHasFocus = false
        isEditing = false
        NeverNotePlatform.resignFirstResponder()
    }

    private func overflowMenuRow(symbol: String, isSelected: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
            if isSelected {
                Image(systemName: "checkmark")
            }
        }
        .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
    }

    private func applyToolbarAlignment(_ alignment: NoteTextAlignment) {
        textAlignment = alignment
        sendEditorCommand(.alignment(alignment))
    }

    private func applyToolbarLinePrefix(_ mode: NoteLinePrefixMode) {
        linePrefixMode = mode
        sendEditorCommand(.refreshDerivedDisplay)
    }

    @ViewBuilder
    private func editorToolbarChromeBackground(placement: EditorToolbarPlacement, shelfActive: Bool) -> some View {
        let fill = (placement == .keyboardAdjacent && shelfActive)
            ? Color.editorKeyboardShelf
            : Color.editorToolbarChrome

        if placement == .keyboardAdjacent && shelfActive {
            Rectangle()
                .fill(fill)
                .ignoresSafeArea(.container, edges: .bottom)
                .ignoresSafeArea(.keyboard, edges: .bottom)
        } else {
            Rectangle()
                .fill(fill)
                .ignoresSafeArea(.container, edges: .bottom)
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

    /// Wide letter-spacing suits Latin footer labels; tighter spacing for CJK and RTL scripts.
    private var footerLetterSpacing: CGFloat {
        let code = locale.language.languageCode?.identifier ?? locale.identifier
        switch code {
        case "ar", "he", "ja", "ko", "zh", "th", "hi":
            return 0
        default:
            return locale.identifier.hasPrefix("zh") || locale.identifier.hasPrefix("ja") ? 0 : 1.5
        }
    }

    private var footerText: String {
        if let note = activeNote {
            let relative = RelativeDateTimeFormatter().localizedString(for: note.lastEditedAt, relativeTo: .now)
            return String(format: String(localized: "LAST EDITED %@."), relative)
        }
        return String(localized: "NEVERNOTE FOCUS")
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

    private func migrateEditorFontStorageIfNeeded() {
        let normalized = EditorFont.normalizedFontToken(editorFontName)
        if normalized != editorFontName {
            editorFontName = normalized
        }
    }

    private func ensureSingleNoteExists() {
        guard notes.isEmpty else { return }
        let newNote = NoteDocument()
        modelContext.insert(newNote)
        try? modelContext.save()
    }

    private func loadNoteIfNeeded() {
        guard !hasLoadedExistingNote else { return }
        hasLoadedExistingNote = true

        if let config = ScreenshotMode.config {
            attributedText = config.attributedNoteText
            return
        }

        guard let note = activeNote else { return }
        if let decoded = NoteRichTextCodec.decode(note.richTextData), decoded.length > 0 {
            attributedText = decoded
        } else if !note.plainText.isEmpty {
            attributedText = NSAttributedString(string: note.plainText)
        }
        textAlignment = NoteTextAlignment(rawValue: note.textAlignmentRawValue ?? "center") ?? .center
        linePrefixMode = NoteLinePrefixMode(rawValue: note.linePrefixModeRawValue ?? "none") ?? .none
        if let data = note.capturedImageData {
            capturedImage = NeverNotePlatform.platformImage(from: data)
        }
    }

    private func removeCapturedImage() {
        capturedImage = nil
        #if os(macOS)
        if case .capturedImage = macSidePanel {
            macSidePanel = nil
        }
        #else
        fullScreenImagePresentation = nil
        #endif
        if let note = activeNote {
            note.capturedImageData = nil
        }
        try? modelContext.save()
    }

    private func clearNote() {
        undoAttributedText = attributedText
        NoteWrappingTextView.customUndoAvailable = true
        attributedText = NSAttributedString(string: "")
        removeCapturedImage()
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
        if !hasContent, capturedImage != nil {
            removeCapturedImage()
        }
        note.lastEditedAt = .now
        note.plainText = attributedText.string
        note.pruneURLImagePreviewEntries(notContainedIn: note.plainText)
        note.richTextData = NoteRichTextCodec.encode(attributedText) ?? Data()
        note.textAlignmentRawValue = textAlignment.rawValue
        note.linePrefixModeRawValue = linePrefixMode.rawValue
        try? modelContext.save()
    }

    private var cameraButtonIcon: String {
        #if os(macOS)
        return "photo.on.rectangle"
        #else
        switch permissionManager.state {
        case .photoOnly: return "photo.on.rectangle"
        default: return "camera.fill"
        }
        #endif
    }

    private func handleCameraButtonTapped() {
        if !NoteImageEducationalModal.hasBeenShown || permissionManager.state == .notDetermined {
            #if os(macOS)
            macSidePanel = .imageEducation
            #else
            showEducationalModal = true
            #endif
        } else {
            launchImagePicker()
        }
    }

    private func launchImagePicker() {
        #if os(macOS)
        macSidePanel = .photoImport
        #else
        switch permissionManager.state {
        case .cameraOnly:
            showCameraPicker = true
        case .photoOnly:
            showPhotoPicker = true
        case .both:
            showImageSourceChooser = true
        case .notDetermined:
            showEducationalModal = true
        case .denied:
            break
        }
        #endif
    }

    private func handleImageSelected(_ image: PlatformImage) async {
        capturedImage = image
        if let jpeg = NeverNotePlatform.jpegData(from: image, compressionQuality: 0.7), let note = activeNote {
            note.capturedImageData = jpeg
            try? modelContext.save()
        }
        isProcessingImage = true
        defer { isProcessingImage = false }

        async let ocrTextTask = NoteImageOCR.recognizeText(in: image)
        async let qrPayloadsTask = NoteImageQRDetection.detectQRPayloads(in: image)

        let ocrText = ((try? await ocrTextTask) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let qrPayloads = await qrPayloadsTask
        let combined = NoteImportedImageText.compose(ocr: ocrText, qrPayloads: qrPayloads)
        guard !combined.isEmpty else { return }

        let font = EditorFont.platformFont(forToken: editorFontName, size: editorScaledPointSize)
        #if canImport(UIKit)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.noteBodyText]
        #else
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.noteBodyText]
        #endif
        attributedText = NSAttributedString(string: combined, attributes: attrs)
        persistNote()
    }

    private func handleHTTPSImageLinkLongPress(url: URL, point: CGPoint, textView: PlatformTextView) {
        let key = NoteDocument.normalizedURLKey(url)
        NoteImageURLPrefetcher.prefetchImage(from: url) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    let current = activeNote?.urlShowsImagePreview(key) ?? false
                    let toggleTitle = current
                        ? String(localized: "Hide image at bottom")
                        : String(localized: "Show image at bottom")
                    presentImageLinkPrompt(
                        title: String(localized: "Image link"),
                        message: String(localized: "Show this image below the note?"),
                        confirmTitle: toggleTitle
                    ) {
                        activeNote?.setURLShowsImagePreview(key, show: !current)
                        urlPreviewRefreshToken &+= 1
                        persistNote()
                    }
                case .failure(let error):
                    presentImageLinkPrompt(
                        title: String(localized: "Can't use this link as an image"),
                        message: error.localizedDescription,
                        confirmTitle: String(localized: "OK")
                    ) {}
                }
            }
        }
    }

    #if os(macOS)
    private func showFontPickerPanel() {
        macSidePanel = .fontPicker
    }

    private func showActivitySharePanel() {
        macSidePanel = .share(MacSharePayload(items: activityItems))
    }

    private func showCapturedImagePreview(_ image: PlatformImage) {
        macSidePanel = .capturedImage(id: UUID(), image: image)
    }
    #else
    private func showFontPickerPanel() {
        showFontPicker = true
    }

    private func showActivitySharePanel() {
        showActivityShare = true
    }

    private func showCapturedImagePreview(_ image: PlatformImage) {
        fullScreenImagePresentation = FullScreenImagePresentation(image: image)
    }
    #endif

    private func presentImageLinkPrompt(
        title: String,
        message: String,
        confirmTitle: String,
        onConfirm: @escaping () -> Void
    ) {
        #if os(macOS)
        macConfirmationOnConfirm = onConfirm
        macSidePanel = .confirmation(
            MacConfirmationRequest(title: title, message: message, confirmTitle: confirmTitle)
        )
        #elseif canImport(UIKit)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: confirmTitle, style: .default) { _ in onConfirm() })
        alert.addAction(UIAlertAction(title: String(localized: "Cancel"), style: .cancel))
        root.present(alert, animated: true)
        #endif
    }

    private func sendEditorCommand(_ action: TextFormatAction) {
        commandCounter += 1
        editorCommand = EditorCommand(id: commandCounter, action: action)
    }

    @ViewBuilder
    private func platformThumbnail(_ image: PlatformImage) -> Image {
        #if canImport(UIKit)
        Image(uiImage: image)
        #else
        Image(nsImage: image)
        #endif
    }
}

#Preview {
    ContentView()
        .modelContainer(for: NoteDocument.self, inMemory: true)
}
