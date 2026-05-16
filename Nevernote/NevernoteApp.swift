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
                .tint(Color(UIColor.brandBlueTint))
        }
        .modelContainer(sharedModelContainer)
    }
}
