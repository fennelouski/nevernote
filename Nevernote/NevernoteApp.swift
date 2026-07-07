//
//  NevernoteApp.swift
//  Nevernote
//
//  Created by Nathan Fennel on 4/30/26.
//

import SwiftData
import SwiftUI

@main
struct NevernoteApp: App {
    var sharedModelContainer: ModelContainer = NevernoteModelContainerFactory.makeContainer()

    @State private var featureFlags = FeatureFlags()
    #if DEBUG
    @State private var showFeatureFlagsDebug = false
    #endif

    init() {
        #if DEBUG
        NeverNoteShortcut.assertAllBindingsAreUnique()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(Color.nevernoteBrandBlue)
                .environment(featureFlags)
                #if DEBUG
                .sheet(isPresented: $showFeatureFlagsDebug) {
                    FeatureFlagsDebugSheet(featureFlags: featureFlags)
                }
                .onReceive(NotificationCenter.default.publisher(for: NevernoteNotification.showFeatureFlags)) { _ in
                    showFeatureFlagsDebug = true
                }
                .onAppear {
                    if FeatureFlagLaunchOverrides.shouldShowFeatureFlagsPanel {
                        showFeatureFlagsDebug = true
                    }
                }
                #endif
        }
        .modelContainer(sharedModelContainer)
        #if os(macOS)
        .commands {
            NeverNoteAppCommands()
        }
        #endif
    }
}
