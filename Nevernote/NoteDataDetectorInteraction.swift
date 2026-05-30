//
//  NoteDataDetectorInteraction.swift
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

struct NoteDataDetectorInteraction: Identifiable {
    let id = UUID()
    let displayText: String
    let copyText: String
    let primaryActionTitle: String
    private let actionURL: URL

    static func make(url: URL, range: NSRange, in noteText: String) -> NoteDataDetectorInteraction? {
        let nsText = noteText as NSString
        guard range.location != NSNotFound,
              range.length > 0,
              NSMaxRange(range) <= nsText.length else {
            return nil
        }
        let substring = nsText.substring(with: range).trimmingCharacters(in: .whitespacesAndNewlines)
        let display = substring.isEmpty ? url.absoluteString : substring
        let match = checkingResult(at: range, in: noteText)
        let title = primaryActionTitle(for: url, match: match)
        let copy = copyText(display: display, url: url, match: match)
        return NoteDataDetectorInteraction(
            displayText: display,
            copyText: copy,
            primaryActionTitle: title,
            actionURL: url
        )
    }

    func performPrimaryAction() {
        #if canImport(UIKit)
        UIApplication.shared.open(actionURL)
        #elseif canImport(AppKit)
        NSWorkspace.shared.open(actionURL)
        #endif
    }

    static func copyToPasteboard(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }

    private static func checkingResult(at range: NSRange, in text: String) -> NSTextCheckingResult? {
        guard let detector = try? NSDataDetector(types: NoteDataDetectors.enabledCheckingTypes) else { return nil }
        let len = (text as NSString).length
        guard len > 0 else { return nil }
        var found: NSTextCheckingResult?
        detector.enumerateMatches(in: text, options: [], range: NSRange(location: 0, length: len)) { match, _, stop in
            guard let match else { return }
            if NSIntersectionRange(match.range, range).length > 0 {
                found = match
                stop.pointee = true
            }
        }
        return found
    }

    private static func primaryActionTitle(for url: URL, match: NSTextCheckingResult?) -> String {
        if let match {
            if match.resultType.contains(.phoneNumber) {
                return String(localized: "Call")
            }
            if match.resultType.contains(.address) {
                return String(localized: "Show in Maps")
            }
            if match.resultType.contains(.date) {
                return String(localized: "Add to Calendar")
            }
        }
        let scheme = url.scheme?.lowercased() ?? ""
        switch scheme {
        case "tel":
            return String(localized: "Call")
        case "sms", "facetime":
            return String(localized: "Open")
        case "mailto":
            return String(localized: "Send Email")
        case "http", "https":
            return String(localized: "Open")
        case "maps", "mapitems":
            return String(localized: "Show in Maps")
        default:
            if scheme.hasPrefix("x-apple-data-detectors") {
                if match?.resultType.contains(.date) == true {
                    return String(localized: "Add to Calendar")
                }
                if match?.resultType.contains(.address) == true {
                    return String(localized: "Show in Maps")
                }
            }
            return String(localized: "Open")
        }
    }

    private static func copyText(display: String, url: URL, match: NSTextCheckingResult?) -> String {
        if !display.isEmpty, display != url.absoluteString {
            return display
        }
        if let phone = match?.phoneNumber, !phone.isEmpty {
            return phone
        }
        if let address = match?.addressComponents, !address.isEmpty {
            return display.isEmpty ? url.absoluteString : display
        }
        return url.absoluteString
    }
}
