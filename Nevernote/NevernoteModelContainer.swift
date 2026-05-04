//
//  NevernoteModelContainer.swift
//  Nevernote
//

import Foundation
import SwiftData

enum NevernoteModelContainerFactory {
    private static let cloudConfigurationName = "nevernote"
    private static let localConfigurationName = "nevernote-local"
    private static let storeDirectoryName = "NevernoteSwiftData"
    private static let cloudStoreFileName = "notes.store"
    private static let localStoreFileName = "notes-local.store"

    private static var storeDirectoryURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent(storeDirectoryName, isDirectory: true)
    }

    private static func cloudStoreURL() -> URL {
        storeDirectoryURL.appendingPathComponent(cloudStoreFileName, isDirectory: false)
    }

    private static func localStoreURL() -> URL {
        storeDirectoryURL.appendingPathComponent(localStoreFileName, isDirectory: false)
    }

    private static func prepareStoreDirectory() {
        let fm = FileManager.default
        try? fm.createDirectory(at: storeDirectoryURL, withIntermediateDirectories: true)
    }

    private static func wipeStoreDirectory() {
        let fm = FileManager.default
        if fm.fileExists(atPath: storeDirectoryURL.path) {
            try? fm.removeItem(at: storeDirectoryURL)
        }
        try? fm.createDirectory(at: storeDirectoryURL, withIntermediateDirectories: true)
    }

    /// Prefer CloudKit sync, then local disk, then an in-memory store so launch never depends on migration or CloudKit succeeding.
    static func makeContainer() -> ModelContainer {
        let schema = Schema([
            NoteDocument.self,
        ])
        prepareStoreDirectory()

        let cloudConfiguration = ModelConfiguration(
            cloudConfigurationName,
            schema: schema,
            url: cloudStoreURL(),
            cloudKitDatabase: .private(NevernoteCloudKit.containerIdentifier)
        )

        if let container = try? ModelContainer(for: schema, configurations: [cloudConfiguration]) {
            return container
        }

        wipeStoreDirectory()
        if let container = try? ModelContainer(for: schema, configurations: [cloudConfiguration]) {
            return container
        }

        wipeStoreDirectory()
        let localConfiguration = ModelConfiguration(
            localConfigurationName,
            schema: schema,
            url: localStoreURL(),
            cloudKitDatabase: .none
        )
        if let container = try? ModelContainer(for: schema, configurations: [localConfiguration]) {
            return container
        }

        wipeStoreDirectory()
        if let container = try? ModelContainer(for: schema, configurations: [localConfiguration]) {
            return container
        }

        let memoryConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        if let container = try? ModelContainer(for: schema, configurations: [memoryConfiguration]) {
            return container
        }

        preconditionFailure("SwiftData could not create an in-memory ModelContainer (last-resort).")
    }
}
