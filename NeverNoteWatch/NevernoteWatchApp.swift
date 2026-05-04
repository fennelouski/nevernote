//
//  NevernoteWatchApp.swift
//  Nevernote
//

import SwiftData
import SwiftUI

@main
struct NevernoteWatchApp: App {
    var sharedModelContainer: ModelContainer = NevernoteModelContainerFactory.makeContainer()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
