//
//  NeverNoteTheme.swift
//  Nevernote
//

import SwiftUI
import UIKit

extension Color {
    static let brandBlue = Color(red: 28.0 / 255.0, green: 128.0 / 255.0, blue: 152.0 / 255.0)
    static let noteCanvas = Color(UIColor.systemGroupedBackground)
    static let topBarBackground = Color(UIColor.systemBackground)
    static let topBarDivider = Color(UIColor.separator)
}

extension UIColor {
    static let brandBlueTint = UIColor(red: 28.0 / 255.0, green: 128.0 / 255.0, blue: 152.0 / 255.0, alpha: 1)
    static var noteBodyText: UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark ? .lightText : .darkText
        }
    }
    static var noteExportBackground: UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? .secondarySystemGroupedBackground
                : UIColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1)
        }
    }
}
