//
//  NeverNoteTheme.swift
//  Nevernote
//

import SwiftUI
import UIKit

extension Color {
    static let brandBlue = Color(red: 28.0 / 255.0, green: 128.0 / 255.0, blue: 152.0 / 255.0)

    /// Full-bleed app canvas behind all content layers.
    static let noteCanvas = Color(UIColor.systemGroupedBackground)

    /// Editing top chrome; extends under the status bar.
    static let topBarBackground = Color(UIColor.systemBackground)

    static let topBarDivider = Color(UIColor.separator)

    /// Inline / unfocused bottom formatting toolbar.
    static let editorToolbarChrome = Color(UIColor.editorToolbarChrome)

    /// Keyboard-adjacent toolbar and shelf above the system keyboard.
    static let editorKeyboardShelf = Color(UIColor.editorKeyboardShelf)

    /// Screenshot share prompt scrim.
    static let screenshotOverlayDim = Color.black.opacity(0.55)
}

extension UIColor {
    static let brandBlueTint = UIColor(red: 28.0 / 255.0, green: 128.0 / 255.0, blue: 152.0 / 255.0, alpha: 1)

    static var noteBodyText: UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark ? .lightText : .darkText
        }
    }

    /// Export / renderer only — not used for on-screen canvas.
    static var noteExportBackground: UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? .secondarySystemGroupedBackground
                : UIColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1)
        }
    }

    static var editorToolbarChrome: UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark ? .systemGray5 : .systemGray6
        }
    }

    static var editorKeyboardShelf: UIColor {
        editorToolbarChrome
    }
}
