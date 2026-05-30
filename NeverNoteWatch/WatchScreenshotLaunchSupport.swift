//
//  WatchScreenshotLaunchSupport.swift
//  NeverNote Watch App
//

import Foundation

struct WatchScreenshotLaunchConfig {
    let noteText: String

    static func fromProcessArguments() -> WatchScreenshotLaunchConfig? {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains("--screenshot-mode") else { return nil }

        var noteText = ScreenshotDemoStrings.text(at: 0)
        if let idx = args.firstIndex(of: "--screenshot-text"),
           args.indices.contains(idx + 1),
           let n = Int(args[idx + 1]) {
            noteText = ScreenshotDemoStrings.text(at: n)
        }

        return WatchScreenshotLaunchConfig(noteText: noteText)
    }
}

enum WatchScreenshotMode {
    static let config: WatchScreenshotLaunchConfig? = WatchScreenshotLaunchConfig.fromProcessArguments()
}
