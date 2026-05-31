//
//  NeverNotePlatform.swift
//  Nevernote
//

import Foundation
import SwiftUI
import SwiftUI

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
public typealias PlatformColor = UIColor
public typealias PlatformFont = UIFont
public typealias PlatformTextView = UITextView
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
public typealias PlatformColor = NSColor
public typealias PlatformFont = NSFont
public typealias PlatformTextView = NSTextView
#endif

enum NeverNotePlatform {
    static var isPad: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad
        #else
        false
        #endif
    }

    static func resignFirstResponder() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #elseif canImport(AppKit)
        NSApp.keyWindow?.makeFirstResponder(nil)
        #endif
    }

    static var screenshotNotification: Notification.Name {
        #if canImport(UIKit)
        UIApplication.userDidTakeScreenshotNotification
        #else
        Notification.Name("NeverNote.macScreenshotUnavailable")
        #endif
    }

    static func platformImage(from data: Data) -> PlatformImage? {
        #if canImport(UIKit)
        UIImage(data: data)
        #elseif canImport(AppKit)
        NSImage(data: data)
        #endif
    }

    static func jpegData(from image: PlatformImage, compressionQuality: CGFloat) -> Data? {
        #if canImport(UIKit)
        image.jpegData(compressionQuality: compressionQuality)
        #elseif canImport(AppKit)
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
        #endif
    }
}

extension Color {
    static var nevernoteBrandBlue: Color {
        #if canImport(UIKit)
        Color(UIColor.brandBlueTint)
        #else
        Color(nsColor: .brandBlueTint)
        #endif
    }
}

#if canImport(AppKit)
extension NSColor {
    static let brandBlueTint = NSColor(red: 28.0 / 255.0, green: 128.0 / 255.0, blue: 152.0 / 255.0, alpha: 1)

    /// Explicit body color for AppKit text storage. Prefer `noteBodyText(for:)` from SwiftUI where possible —
    /// dynamic catalog colors often resolve incorrectly inside `NSViewRepresentable`.
    static func noteBodyText(for colorScheme: ColorScheme) -> NSColor {
        colorScheme == .dark
            ? NSColor(calibratedWhite: 1, alpha: 1)
            : NSColor(calibratedWhite: 0, alpha: 1)
    }

    static var noteBodyText: NSColor {
        noteBodyText(for: .light)
    }

    static var noteExportBackground: NSColor {
        NSColor.windowBackgroundColor
    }

    static var editorToolbarChrome: NSColor {
        NSColor.controlBackgroundColor
    }

    static var editorKeyboardShelf: NSColor {
        editorToolbarChrome
    }
}
#endif
