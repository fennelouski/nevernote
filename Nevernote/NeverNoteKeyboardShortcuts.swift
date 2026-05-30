//
//  NeverNoteKeyboardShortcuts.swift
//  Nevernote
//

import SwiftUI

/// Hardware keyboard shortcuts for macOS and iPad (external keyboard).
/// Every case maps to a unique (modifiers + key) pair — see `bindingID` and `assertAllBindingsAreUnique()`.
enum NeverNoteShortcut: CaseIterable {
    case selectAll
    case toggleSmartLinks
    case importPhoto
    case viewCapturedImage
    case undoDelete
    case deleteNote
    case shareNote
    case beginEditing
    case bold
    case italic
    case underline
    case fontPicker
    case togglePresentationSize
    case alignLeft
    case alignCenter
    case alignRight
    case linePrefixNone
    case linePrefixBulleted
    case linePrefixNumbered
    case cycleLinePrefix
    case dismissKeyboard
    case shareScreenshotText
    case shareScreenshotImage
    case screenshotAspect1
    case screenshotAspect2
    case screenshotAspect3
    case screenshotAspect4
    case screenshotAspect5
    case cancel
    case continueAction
    case resetFormatting
    case copy
    case openPhotoLibrary
    case openCamera
    case closeImage

    var key: KeyEquivalent {
        switch self {
        case .selectAll: return "a"
        case .toggleSmartLinks: return "k"
        case .importPhoto: return "i"
        case .viewCapturedImage: return "v"
        case .undoDelete: return "z"
        case .deleteNote: return KeyEquivalent.delete
        case .shareNote: return "s"
        case .beginEditing: return "e"
        case .bold: return "b"
        case .italic: return "i"
        case .underline: return "u"
        case .fontPicker: return "f"
        case .togglePresentationSize: return "m"
        case .alignLeft: return "l"
        case .alignCenter: return "e"
        case .alignRight: return "r"
        case .linePrefixNone: return "0"
        case .linePrefixBulleted: return "8"
        case .linePrefixNumbered: return "7"
        case .cycleLinePrefix: return "l"
        case .dismissKeyboard: return "k"
        case .shareScreenshotText: return "1"
        case .shareScreenshotImage: return "2"
        case .screenshotAspect1: return "1"
        case .screenshotAspect2: return "2"
        case .screenshotAspect3: return "3"
        case .screenshotAspect4: return "4"
        case .screenshotAspect5: return "5"
        case .cancel: return .escape
        case .continueAction: return .return
        case .resetFormatting: return "r"
        case .copy: return "c"
        case .openPhotoLibrary: return "p"
        case .openCamera: return "c"
        case .closeImage: return "w"
        }
    }

    var modifiers: EventModifiers {
        switch self {
        case .selectAll: return [.command, .shift]
        case .toggleSmartLinks: return [.command, .shift]
        case .importPhoto: return [.command, .shift]
        case .viewCapturedImage: return [.command, .option]
        case .undoDelete: return [.command, .shift]
        case .deleteNote: return .command
        case .shareNote: return [.command, .shift]
        case .beginEditing: return .command
        case .bold, .italic, .underline: return .command
        case .fontPicker: return [.command, .shift]
        case .togglePresentationSize: return [.command, .option]
        case .alignLeft, .alignCenter, .alignRight: return [.command, .option]
        case .linePrefixNone, .linePrefixBulleted, .linePrefixNumbered: return [.command, .shift]
        case .cycleLinePrefix: return [.command, .shift, .option]
        case .dismissKeyboard: return [.control, .command]
        case .shareScreenshotText, .shareScreenshotImage: return [.command, .shift]
        case .screenshotAspect1, .screenshotAspect2, .screenshotAspect3, .screenshotAspect4, .screenshotAspect5:
            return .command
        case .cancel: return []
        case .continueAction: return .command
        case .resetFormatting: return [.command, .shift]
        case .copy: return [.command, .shift]
        case .openPhotoLibrary: return [.command, .shift]
        case .openCamera: return [.command, .option]
        case .closeImage: return [.command, .option]
        }
    }

    /// Stable identifier for duplicate detection (not for display).
    var bindingID: String {
        let mod = modifiers.eventModifiersBits
        let keyChar: String = {
            if key == .delete { return "delete" }
            if key == .escape { return "escape" }
            if key == .return { return "return" }
            return String(key.character).lowercased()
        }()
        return "\(mod)|\(keyChar)"
    }

    #if DEBUG
    static func assertAllBindingsAreUnique(file: StaticString = #file, line: UInt = #line) {
        var seen: [String: NeverNoteShortcut] = [:]
        for shortcut in allCases {
            let id = shortcut.bindingID
            if let existing = seen[id] {
                assertionFailure(
                    "Duplicate keyboard shortcut \(id): \(existing) and \(shortcut)",
                    file: file,
                    line: line
                )
            }
            seen[id] = shortcut
        }
    }
    #endif
}

private extension EventModifiers {
    var eventModifiersBits: Int {
        var bits = 0
        if contains(.command) { bits |= 1 << 0 }
        if contains(.shift) { bits |= 1 << 1 }
        if contains(.option) { bits |= 1 << 2 }
        if contains(.control) { bits |= 1 << 3 }
        return bits
    }
}

enum NeverNoteKeyboardShortcuts {
    static var isEnabled: Bool {
        #if os(macOS)
        true
        #elseif os(iOS)
        NeverNotePlatform.isPad
        #else
        false
        #endif
    }
}

extension View {
    @ViewBuilder
    func neverNoteShortcut(_ shortcut: NeverNoteShortcut) -> some View {
        if NeverNoteKeyboardShortcuts.isEnabled {
            keyboardShortcut(shortcut.key, modifiers: shortcut.modifiers)
        } else {
            self
        }
    }
}

// MARK: - Scene command routing

struct NeverNoteMenuAction {
    var isEnabled: Bool
    var perform: () -> Void

    static let disabled = NeverNoteMenuAction(isEnabled: false, perform: {})

    static func when(_ condition: Bool, perform: @escaping () -> Void) -> NeverNoteMenuAction {
        NeverNoteMenuAction(isEnabled: condition, perform: perform)
    }
}

struct NeverNoteCommandHandlers {
    var selectAll = NeverNoteMenuAction.disabled
    var toggleSmartLinks = NeverNoteMenuAction.disabled
    var importPhoto = NeverNoteMenuAction.disabled
    var openPhotoLibrary = NeverNoteMenuAction.disabled
    var openCamera = NeverNoteMenuAction.disabled
    var viewCapturedImage = NeverNoteMenuAction.disabled
    var undoDelete = NeverNoteMenuAction.disabled
    var deleteNote = NeverNoteMenuAction.disabled
    var shareNote = NeverNoteMenuAction.disabled
    var beginEditing = NeverNoteMenuAction.disabled
    var bold = NeverNoteMenuAction.disabled
    var italic = NeverNoteMenuAction.disabled
    var underline = NeverNoteMenuAction.disabled
    var fontPicker = NeverNoteMenuAction.disabled
    var togglePresentationSize = NeverNoteMenuAction.disabled
    var alignLeft = NeverNoteMenuAction.disabled
    var alignCenter = NeverNoteMenuAction.disabled
    var alignRight = NeverNoteMenuAction.disabled
    var linePrefixNone = NeverNoteMenuAction.disabled
    var linePrefixBulleted = NeverNoteMenuAction.disabled
    var linePrefixNumbered = NeverNoteMenuAction.disabled
    var cycleLinePrefix = NeverNoteMenuAction.disabled
    var dismissKeyboard = NeverNoteMenuAction.disabled
    var shareScreenshotText = NeverNoteMenuAction.disabled
    var shareScreenshotImage = NeverNoteMenuAction.disabled
    var screenshotAspectPortrait = NeverNoteMenuAction.disabled
    var screenshotAspectStory = NeverNoteMenuAction.disabled
    var screenshotAspectSquare = NeverNoteMenuAction.disabled
    var screenshotAspectLandscape16x9 = NeverNoteMenuAction.disabled
    var screenshotAspectLandscape4x3 = NeverNoteMenuAction.disabled
    var continueAction = NeverNoteMenuAction.disabled
    var copy = NeverNoteMenuAction.disabled
    var cancel = NeverNoteMenuAction.disabled
    var resetFormatting = NeverNoteMenuAction.disabled
    var closeImage = NeverNoteMenuAction.disabled
}

private struct NeverNoteCommandHandlersKey: FocusedValueKey {
    typealias Value = NeverNoteCommandHandlers
}

extension FocusedValues {
    var neverNoteCommandHandlers: NeverNoteCommandHandlers? {
        get { self[NeverNoteCommandHandlersKey.self] }
        set { self[NeverNoteCommandHandlersKey.self] = newValue }
    }
}

#if os(macOS)
struct NeverNoteAppCommands: Commands {
    @FocusedValue(\.neverNoteCommandHandlers) private var handlers

    private var h: NeverNoteCommandHandlers { handlers ?? NeverNoteCommandHandlers() }

    init() {
        #if DEBUG
        NeverNoteShortcut.assertAllBindingsAreUnique()
        #endif
    }

    var body: some Commands {
        CommandGroup(replacing: .newItem) {}

        CommandMenu(String(localized: "Note")) {
            menuItem(String(localized: "Edit Note"), shortcut: .beginEditing, action: h.beginEditing)
            menuItem(String(localized: "Select All"), shortcut: .selectAll, action: h.selectAll)
            Divider()
            menuItem(String(localized: "Import Text from Photo"), shortcut: .importPhoto, action: h.importPhoto)
            menuItem(String(localized: "Photo Library"), shortcut: .openPhotoLibrary, action: h.openPhotoLibrary)
            menuItem(String(localized: "View Captured Image"), shortcut: .viewCapturedImage, action: h.viewCapturedImage)
            menuItem(String(localized: "Smart Links"), shortcut: .toggleSmartLinks, action: h.toggleSmartLinks)
            Divider()
            menuItem(String(localized: "Share Note"), shortcut: .shareNote, action: h.shareNote)
            menuItem(String(localized: "Undo Delete"), shortcut: .undoDelete, action: h.undoDelete)
            menuItem(String(localized: "Delete Note"), shortcut: .deleteNote, action: h.deleteNote)
            Divider()
            menuItem(String(localized: "Hide Keyboard"), shortcut: .dismissKeyboard, action: h.dismissKeyboard)
        }

        CommandMenu(String(localized: "Format")) {
            menuItem(String(localized: "Bold"), shortcut: .bold, action: h.bold)
            menuItem(String(localized: "Italic"), shortcut: .italic, action: h.italic)
            menuItem(String(localized: "Underline"), shortcut: .underline, action: h.underline)
            menuItem(String(localized: "Font…"), shortcut: .fontPicker, action: h.fontPicker)
            menuItem(
                String(localized: "Maximize Presentation Size"),
                shortcut: .togglePresentationSize,
                action: h.togglePresentationSize
            )
            Divider()
            menuItem(String(localized: "Align Left"), shortcut: .alignLeft, action: h.alignLeft)
            menuItem(String(localized: "Align Center"), shortcut: .alignCenter, action: h.alignCenter)
            menuItem(String(localized: "Align Right"), shortcut: .alignRight, action: h.alignRight)
            Divider()
            menuItem(String(localized: "Plain Lines"), shortcut: .linePrefixNone, action: h.linePrefixNone)
            menuItem(String(localized: "Bulleted List"), shortcut: .linePrefixBulleted, action: h.linePrefixBulleted)
            menuItem(String(localized: "Numbered List"), shortcut: .linePrefixNumbered, action: h.linePrefixNumbered)
            menuItem(String(localized: "Toggle Line Markers"), shortcut: .cycleLinePrefix, action: h.cycleLinePrefix)
            Divider()
            menuItem(String(localized: "Reset Formatting"), shortcut: .resetFormatting, action: h.resetFormatting)
        }

        CommandMenu(String(localized: "Screenshot Share")) {
            menuItem(String(localized: "Share Note Text"), shortcut: .shareScreenshotText, action: h.shareScreenshotText)
            menuItem(String(localized: "Share as Image of Text"), shortcut: .shareScreenshotImage, action: h.shareScreenshotImage)
            Divider()
            menuItem(String(localized: "Portrait"), shortcut: .screenshotAspect1, action: h.screenshotAspectPortrait)
            menuItem(String(localized: "9:16"), shortcut: .screenshotAspect2, action: h.screenshotAspectStory)
            menuItem(String(localized: "Square"), shortcut: .screenshotAspect3, action: h.screenshotAspectSquare)
            menuItem(String(localized: "16:9"), shortcut: .screenshotAspect4, action: h.screenshotAspectLandscape16x9)
            menuItem(String(localized: "Landscape"), shortcut: .screenshotAspect5, action: h.screenshotAspectLandscape4x3)
        }

        CommandMenu(String(localized: "Actions")) {
            menuItem(String(localized: "Continue"), shortcut: .continueAction, action: h.continueAction)
            menuItem(String(localized: "Copy"), shortcut: .copy, action: h.copy)
            menuItem(String(localized: "Cancel"), shortcut: .cancel, action: h.cancel)
            Divider()
            menuItem(String(localized: "Close Image"), shortcut: .closeImage, action: h.closeImage)
        }

        #if DEBUG
        CommandMenu(String(localized: "Developer")) {
            Button(String(localized: "Feature Flags…")) {
                NotificationCenter.default.post(name: NevernoteNotification.showFeatureFlags, object: nil)
            }
        }
        #endif
    }

    private func menuItem(
        _ title: String,
        shortcut: NeverNoteShortcut,
        action: NeverNoteMenuAction
    ) -> some View {
        Button(title) {
            action.perform()
        }
        .keyboardShortcut(shortcut.key, modifiers: shortcut.modifiers)
        .disabled(!action.isEnabled)
    }
}
#endif
