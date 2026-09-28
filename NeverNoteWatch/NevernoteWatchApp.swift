//
//  NevernoteWatchApp.swift
//  Nevernote
//

import SwiftData
import SwiftUI

@main
struct NevernoteWatchApp: App {

    var body: some Scene {
        WindowGroup {
            NevernoteStorageView {
                WatchRootView()
            }
        }
    }
}
