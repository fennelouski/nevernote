//
//  NevernoteApp.swift
//  Nevernote
//
//  Created by Nathan Fennel on 4/30/26.
//

import SwiftData
import SwiftUI
import UIKit

@main
struct NevernoteApp: App {
    @UIApplicationDelegateAdaptor(NNAppDelegate.self) private var appDelegate
    var sharedModelContainer: ModelContainer = NevernoteModelContainerFactory.makeContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(Color(red: 28.0 / 255.0, green: 128.0 / 255.0, blue: 152.0 / 255.0))
        }
        .modelContainer(sharedModelContainer)
    }
}
