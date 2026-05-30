//
//  ScreenshotDemoStrings.swift
//  Nevernote
//

import Foundation

enum ScreenshotDemoStrings {
    private static let keys = [
        "screenshot.demo.0",
        "screenshot.demo.1",
        "screenshot.demo.2",
        "screenshot.demo.3",
        "screenshot.demo.4",
    ]

    static var all: [String] {
        keys.map { String(localized: String.LocalizationValue($0)) }
    }

    static func text(at index: Int) -> String {
        guard keys.indices.contains(index) else { return all[0] }
        return String(localized: String.LocalizationValue(keys[index]))
    }
}
