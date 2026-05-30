//
//  EditorFont.swift
//  NeverNote
//
//  Created by Nathan Fennel on 5/17/26.
//  Copyright © 2026 Nathan Fennel. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum EditorFont {
    /// SwiftUI app only; legacy Obj-C target uses its own defaults suite.
    static let appStorageKey = "nevernote.swiftui.editorFontName"
    static let recentFontsStorageKey = "nevernote.swiftui.recentEditorFontNames"
    /// Stable persisted token (not localized).
    static let systemBoldStorageToken = "__system_bold__"
    /// Legacy value from earlier builds before localization.
    static let legacySystemBoldToken = "System Bold"

    static func normalizedFontToken(_ token: String) -> String {
        if token == legacySystemBoldToken || token == systemBoldStorageToken {
            return systemBoldStorageToken
        }
        return token
    }

    static func displayName(forToken token: String) -> String {
        if normalizedFontToken(token) == systemBoldStorageToken {
            return String(localized: "System Bold")
        }
        return token
    }
    static let editorPointSize: CGFloat = 24
    static let fontSizeAppStorageKey = "nevernote.swiftui.editorFontSize"
    static let defaultFontSize: CGFloat = 24
    static let maxRecentCount = 5

    #if canImport(UIKit)
    static func uiFont(forToken token: String, size: CGFloat) -> UIFont {
        if normalizedFontToken(token) == systemBoldStorageToken {
            return UIFont.systemFont(ofSize: size, weight: .bold)
        }
        return UIFont(name: token, size: size)
            ?? UIFont.systemFont(ofSize: size, weight: .bold)
    }
    #endif

    static func platformFont(forToken token: String, size: CGFloat) -> PlatformFont {
        #if canImport(UIKit)
        uiFont(forToken: token, size: size)
        #else
        if normalizedFontToken(token) == systemBoldStorageToken {
            return NSFont.boldSystemFont(ofSize: size)
        }
        return NSFont(name: token, size: size) ?? NSFont.boldSystemFont(ofSize: size)
        #endif
    }

    static var sortedPostScriptNames: [String] {
        #if canImport(UIKit)
        let names = Set(UIFont.familyNames.flatMap { UIFont.fontNames(forFamilyName: $0) })
        #else
        let names = Set(NSFontManager.shared.availableFontFamilies.flatMap { NSFontManager.shared.availableMembers(ofFontFamily: $0)?.compactMap { $0[0] as? String } ?? [] })
        #endif
        return names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    static func recentTokens() -> [String] {
        let raw = UserDefaults.standard.stringArray(forKey: recentFontsStorageKey) ?? []
        let valid = Set(sortedPostScriptNames + [systemBoldStorageToken])
        var seen = Set<String>()
        return raw.filter { token in
            guard valid.contains(token) else { return false }
            guard !seen.contains(token) else { return false }
            seen.insert(token)
            return true
        }
    }

    static func recordRecentToken(_ token: String) {
        let normalized = normalizedFontToken(token)
        guard Set(sortedPostScriptNames + [systemBoldStorageToken]).contains(normalized) else { return }
        var updated = recentTokens().filter { normalizedFontToken($0) != normalized }
        updated.insert(normalized, at: 0)
        if updated.count > maxRecentCount {
            updated = Array(updated.prefix(maxRecentCount))
        }
        UserDefaults.standard.set(updated, forKey: recentFontsStorageKey)
    }
}
