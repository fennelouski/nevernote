//
//  NevernoteApp.swift
//  Nevernote
//
//  Created by Nathan Fennel on 4/30/26.
//

import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@main
struct NevernoteApp: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(NNAppDelegate.self) private var appDelegate
    #endif
    var sharedModelContainer: ModelContainer = NevernoteModelContainerFactory.makeContainer()

    init() {
        #if DEBUG
        NeverNoteShortcut.assertAllBindingsAreUnique()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(Color.nevernoteBrandBlue)
        }
        .modelContainer(sharedModelContainer)
        #if os(macOS)
        .commands {
            NeverNoteAppCommands()
        }
        #endif
    }
}
