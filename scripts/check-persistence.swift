import Foundation
import SwiftData

@main
struct PersistenceChecks {
    @MainActor static func main() throws {
        let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        let id = UUID(uuidString: "12345678-1234-1234-1234-123456789abc")!
        let image = Data([1, 4, 9, 16, 25])
        #if LEGACY_FIXTURE
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for (name, text) in [("notes.store", "Primary legacy text"), ("notes-local.store", "Local legacy text")] {
            let schema = Schema([NoteDocument.self])
            let config = ModelConfiguration(name == "notes.store" ? "nevernote" : "nevernote-local", schema: schema, url: directory.appendingPathComponent(name), cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [config])
            let note = NoteDocument(id: id, richTextData: NoteRichTextCodec.encode(NSAttributedString(string: text))!, plainText: text, lastEditedAt: Date(timeIntervalSince1970: 1234567))
            note.capturedImageData = image
            note.textAlignmentRawValue = "trailing"
            note.linePrefixModeRawValue = "bullet"
            note.setURLShowsImagePreview("https://example.com/photo.jpg", show: true)
            container.mainContext.insert(note)
            try container.mainContext.save()
        }
        print("PASS: legacy unique-ID schema wrote two independent disk stores")
        #else
        func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
            if !condition() { throw NSError(domain: "PersistenceChecks", code: 1, userInfo: [NSLocalizedDescriptionKey: message]) }
        }
        try require(NevernoteModelContainerFactory.existingStores(in: directory) == [.primary, .legacyLocal], "Both legacy stores must remain visible")
        for (store, text) in [(NevernoteModelContainerFactory.Store.primary, "Primary legacy text"), (.legacyLocal, "Local legacy text")] {
            let container = try NevernoteModelContainerFactory.makeContainer(store: store, directory: directory, sync: false)
            let context = container.mainContext
            let records = try context.fetch(FetchDescriptor<NoteDocument>())
            try require(records.count == 1, "Migration changed count")
            let note = records[0]
            try require(note.id == id && note.plainText == text && note.capturedImageData == image, "Migration changed identity/text/photo")
            try require(note.textAlignmentRawValue == "trailing" && note.linePrefixModeRawValue == "bullet" && note.urlShowsImagePreview("https://example.com/photo.jpg"), "Migration lost formatting/preview")
            try require(note.lastEditedAt == Date(timeIntervalSince1970: 1234567), "Migration changed date")
            let original = NoteDocumentSnapshot(note)
            var photoOnly = original
            photoOnly.plainText = ""
            photoOnly.richTextData = NoteRichTextCodec.encode(NSAttributedString(string: ""))!
            try photoOnly.save(to: note, in: context)
            let reader = ModelContext(container)
            let persistedPhoto = try reader.fetch(FetchDescriptor<NoteDocument>())[0]
            try require(persistedPhoto.plainText.isEmpty && persistedPhoto.capturedImageData == image, "Photo-only save lost content")
            var cleared = photoOnly
            cleared.capturedImageData = nil
            try cleared.save(to: note, in: context)
            try original.save(to: note, in: context)
            let restored = try ModelContext(container).fetch(FetchDescriptor<NoteDocument>())[0]
            try require(NoteDocumentSnapshot(restored) == original && restored.id == id, "Complete undo changed fields/identity")
            let newer = NoteDocument(plainText: "Newer remote note", lastEditedAt: .now)
            context.insert(newer)
            try context.save()
            var draft = original
            draft.plainText = "Changed original only"
            try draft.save(to: note, in: context)
            try require(newer.plainText == "Newer remote note" && note.id == id, "Stable target updated other note")
            let beforeRemoteEdit = NoteDocumentSnapshot(note)
            note.plainText = "Incoming remote edit"
            try context.save()
            var conflictCaught = false
            do { try draft.save(to: note, in: context, expected: beforeRemoteEdit) }
            catch NoteSaveError.changedElsewhere { conflictCaught = true }
            try require(conflictCaught && note.plainText == "Incoming remote edit" && draft.plainText == "Changed original only", "Conflict overwrote incoming edit or discarded local draft")
            let backup = directory.appendingPathComponent(store.rawValue + "-before-1.2").appendingPathComponent(store.rawValue)
            try require(FileManager.default.fileExists(atPath: backup.path), "Missing original backup")
            print("PASS: \(store.rawValue) migration, full undo, photo-only persistence, stable target and backup")
        }
        let schema = Schema([NoteDocument.self])
        let config = ModelConfiguration("readonly", schema: schema, url: directory.appendingPathComponent("notes.store"), allowsSave: false, cloudKitDatabase: .none)
        let readonly = try ModelContainer(for: schema, configurations: [config])
        readonly.mainContext.autosaveEnabled = false
        let note = try readonly.mainContext.fetch(FetchDescriptor<NoteDocument>()).first { $0.id == id }!
        let before = NoteDocumentSnapshot(note)
        var draft = before
        draft.plainText = "Unsaved watch addition"
        var failed = false
        do { try draft.save(to: note, in: readonly.mainContext) } catch { failed = true }
        try require(failed && NoteDocumentSnapshot(note) == before && draft.plainText == "Unsaved watch addition", "Failure must restore model and preserve retry draft")
        print("PASS: actual read-only-store save throws, restores model and retains retry draft")
        let damaged = directory.appendingPathComponent("damaged", isDirectory: true)
        try FileManager.default.createDirectory(at: damaged, withIntermediateDirectories: true)
        let corrupt = Data("not a SQLite store".utf8)
        try corrupt.write(to: damaged.appendingPathComponent("notes.store"))
        var rejected = false
        do { _ = try NevernoteModelContainerFactory.makeContainer(store: .primary, directory: damaged, sync: false) } catch { rejected = true }
        try require(rejected, "Corrupt disk must not open blank memory store")
        let preserved = try Data(contentsOf: damaged.appendingPathComponent("notes.store"))
        try require(preserved == corrupt, "Corrupt original changed")
        try require(!FileManager.default.fileExists(atPath: damaged.appendingPathComponent("notes-local.store").path), "Unexpected alternate file")
        print("PASS: corrupt store retained; no alternate or in-memory fallback")
        #endif
    }
}
