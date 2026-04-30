//
//  NevernoteApp.swift
//  Nevernote
//
//  Created by Nathan Fennel on 4/30/26.
//

import SwiftUI
import SwiftData

@main
struct NevernoteApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            NoteDocument.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
