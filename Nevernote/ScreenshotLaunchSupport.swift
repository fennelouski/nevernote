//
//  ScreenshotLaunchSupport.swift
//  Nevernote
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

struct ScreenshotLaunchConfig {
    let noteText: String
    let showKeyboard: Bool

    /// Attributed string with a device-appropriate font size for use in the editor.
    /// iPad gets a much larger size so screenshots aren't dwarfed by the screen.
    var attributedNoteText: NSAttributedString {
        let size: CGFloat = NeverNotePlatform.isPad ? 52 : 24
        let font = EditorFont.platformFont(forToken: EditorFont.systemBoldStorageToken, size: size)
        return NSAttributedString(string: noteText, attributes: [.font: font])
    }

    static func fromProcessArguments() -> ScreenshotLaunchConfig? {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains("--screenshot-mode") else { return nil }

        var noteText = ScreenshotDemoStrings.text(at: 0)
        if let idx = args.firstIndex(of: "--screenshot-text"),
           args.indices.contains(idx + 1),
           let n = Int(args[idx + 1]) {
            noteText = ScreenshotDemoStrings.text(at: n)
        }

        return ScreenshotLaunchConfig(
            noteText: noteText,
            showKeyboard: args.contains("--screenshot-keyboard")
        )
    }
}

enum ScreenshotMode {
    static let config: ScreenshotLaunchConfig? = ScreenshotLaunchConfig.fromProcessArguments()
    static var isActive: Bool { config != nil }
}
