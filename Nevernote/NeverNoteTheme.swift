//
//  NeverNoteTheme.swift
//  Nevernote
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
    static let brandBlue = Color(red: 28.0 / 255.0, green: 128.0 / 255.0, blue: 152.0 / 255.0)

    /// Full-bleed app canvas behind all content layers.
    static let noteCanvas: Color = {
        #if canImport(UIKit)
        Color(UIColor.systemGroupedBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }()

    /// Editing top chrome; extends under the status bar.
    static let topBarBackground: Color = {
        #if canImport(UIKit)
        Color(UIColor.systemBackground)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }()

    static let topBarDivider: Color = {
        #if canImport(UIKit)
        Color(UIColor.separator)
        #else
        Color(nsColor: .separatorColor)
        #endif
    }()

    /// Inline / unfocused bottom formatting toolbar.
    static let editorToolbarChrome: Color = {
        #if canImport(UIKit)
        Color(UIColor.editorToolbarChrome)
        #else
        Color(nsColor: .editorToolbarChrome)
        #endif
    }()

    /// Keyboard-adjacent toolbar and shelf above the system keyboard.
    static let editorKeyboardShelf: Color = {
        #if canImport(UIKit)
        Color(UIColor.editorKeyboardShelf)
        #else
        Color(nsColor: .editorKeyboardShelf)
        #endif
    }()

    /// Screenshot share prompt scrim.
    static let screenshotOverlayDim = Color.black.opacity(0.55)
}

#if canImport(UIKit)
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
#endif

extension DynamicTypeSize {
    var isAccessibilitySize: Bool {
        switch self {
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            true
        default:
            false
        }
    }
}

extension Text {
    /// User-facing copy that wraps to multiple lines instead of truncating.
    func neverNoteWrappingLabel(alignment: TextAlignment = .center) -> some View {
        multilineTextAlignment(alignment)
            .fixedSize(horizontal: false, vertical: true)
    }
}
