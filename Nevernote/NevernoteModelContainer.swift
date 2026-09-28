import Foundation
import SwiftData
import SwiftUI

enum NevernoteModelContainerFactory {
    enum Store: String, CaseIterable, Identifiable {
        case primary = "notes.store"
        case legacyLocal = "notes-local.store"
        var id: String { rawValue }
        var title: String { self == .primary ? "Primary notes" : "Earlier local notes" }
    }

    static var storeDirectoryURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("NevernoteSwiftData", isDirectory: true)
    }

    static func existingStores(in directory: URL = storeDirectoryURL) -> [Store] {
        Store.allCases.filter { FileManager.default.fileExists(atPath: directory.appendingPathComponent($0.rawValue).path) }
    }

    /// Never replace an unreadable store with an empty or temporary store.
    @MainActor
    static func makeContainer(store: Store, directory: URL = storeDirectoryURL, sync: Bool = true) throws -> ModelContainer {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let storeURL = directory.appendingPathComponent(store.rawValue)
        let backupURL = directory.appendingPathComponent(store.rawValue + "-before-1.2", isDirectory: true)
        if FileManager.default.fileExists(atPath: storeURL.path), !FileManager.default.fileExists(atPath: backupURL.path) {
            let staging = directory.appendingPathComponent(UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: false)
            do {
                for suffix in ["", "-wal", "-shm"] {
                    let source = URL(fileURLWithPath: storeURL.path + suffix)
                    if FileManager.default.fileExists(atPath: source.path) {
                        try FileManager.default.copyItem(at: source, to: staging.appendingPathComponent(store.rawValue + suffix))
                    }
                }
                try FileManager.default.moveItem(at: staging, to: backupURL)
            } catch {
                try? FileManager.default.removeItem(at: staging)
                throw error
            }
        }
        let schema = Schema([NoteDocument.self])
        let configuration = ModelConfiguration(
            store == .primary ? "nevernote" : "nevernote-local",
            schema: schema,
            url: directory.appendingPathComponent(store.rawValue),
            cloudKitDatabase: sync && store == .primary ? .private(NevernoteCloudKit.containerIdentifier) : .none
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        container.mainContext.autosaveEnabled = false
        return container
    }
}

/// Both historical store files remain selectable; no implicit merging or deletion occurs.
struct NevernoteStorageView<Content: View>: View {
    @ViewBuilder var content: () -> Content
    @State private var container: ModelContainer?
    @State private var selectedStore: NevernoteModelContainerFactory.Store?
    @State private var errorMessage: String?
    @State private var openedLocally = false
    @State private var didAttemptOpen = false

    var body: some View {
        Group {
            if let container {
                VStack(spacing: 0) {
                    if openedLocally {
                        Text("These notes are saved on this device. iCloud sync is not active for this store.")
                            .font(.caption).padding(8)
                    }
                    content().modelContainer(container)
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        Text(errorMessage == nil ? "Choose saved notes" : "Unable to open saved notes")
                            .font(.headline)
                        if let errorMessage {
                            Text("Your existing files have been kept. No temporary note has been opened.")
                            Text(errorMessage).font(.caption)
                            if let selectedStore {
                                Button("Try again") { open(selectedStore) }
                                if selectedStore == .primary {
                                    Button("Open these notes without iCloud") { open(selectedStore, sync: false) }
                                }
                            }
                        } else {
                            Text("An earlier version used two separate note files. Choose which to open; both are kept. Restart the app to choose the other file.")
                        }
                        ForEach(NevernoteModelContainerFactory.existingStores()) { store in
                            Button(store.title) { open(store) }
                        }
                    }.padding()
                }
            }
        }
        .onAppear {
            guard !didAttemptOpen else { return }
            didAttemptOpen = true
            let stores = NevernoteModelContainerFactory.existingStores()
            if stores.count < 2 { open(stores.first ?? .primary) }
        }
    }

    private func open(_ store: NevernoteModelContainerFactory.Store, sync: Bool = true) {
        selectedStore = store
        do {
            container = try NevernoteModelContainerFactory.makeContainer(store: store, sync: sync)
            openedLocally = !sync || store == .legacyLocal
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
