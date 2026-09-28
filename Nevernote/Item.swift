//
//  Item.swift
//  Nevernote
//
//  Created by Nathan Fennel on 4/30/26.
//

import Foundation
import SwiftData

struct NoteURLImagePreviewEntry: Codable, Equatable {
    var url: String
    var showPreview: Bool
}

enum NoteURLImagePreviewStore {
    static let emptyJSON = Data("[]".utf8)

    static func decodeEntries(from data: Data) -> [NoteURLImagePreviewEntry] {
        guard !data.isEmpty, let decoded = try? JSONDecoder().decode([NoteURLImagePreviewEntry].self, from: data) else {
            return []
        }
        return decoded
    }

    static func encodeEntries(_ entries: [NoteURLImagePreviewEntry]) -> Data {
        (try? JSONEncoder().encode(entries)) ?? emptyJSON
    }
}

@Model
final class NoteDocument {
    var id: UUID = UUID()
    var richTextData: Data = Data()
    var plainText: String = ""
    var lastEditedAt: Date = Date()
    /// JSON array of `NoteURLImagePreviewEntry` — toggles "show image at bottom" for http(s) links.
    var urlImagePreviewStateJSON: Data = Data("[]".utf8)
    var textAlignmentRawValue: String?
    var linePrefixModeRawValue: String?
    var capturedImageData: Data?

    init(
        id: UUID = UUID(),
        richTextData: Data = Data(),
        plainText: String = "",
        lastEditedAt: Date = .now,
        urlImagePreviewStateJSON: Data = NoteURLImagePreviewStore.emptyJSON
    ) {
        self.id = id
        self.richTextData = richTextData
        self.plainText = plainText
        self.lastEditedAt = lastEditedAt
        self.urlImagePreviewStateJSON = urlImagePreviewStateJSON
    }
}

extension NoteDocument {
    /// Normalized key for storing preview preference (matches link `absoluteString` after trim).
    static func normalizedURLKey(_ url: URL) -> String {
        url.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var urlImagePreviewEntries: [NoteURLImagePreviewEntry] {
        get { NoteURLImagePreviewStore.decodeEntries(from: urlImagePreviewStateJSON) }
        set { urlImagePreviewStateJSON = NoteURLImagePreviewStore.encodeEntries(newValue) }
    }

    func urlShowsImagePreview(_ urlKey: String) -> Bool {
        urlImagePreviewEntries.first(where: { $0.url == urlKey })?.showPreview ?? false
    }

    func setURLShowsImagePreview(_ urlKey: String, show: Bool) {
        var entries = urlImagePreviewEntries
        if let i = entries.firstIndex(where: { $0.url == urlKey }) {
            entries[i].showPreview = show
        } else {
            entries.append(NoteURLImagePreviewEntry(url: urlKey, showPreview: show))
        }
        urlImagePreviewEntries = entries
    }

    func pruneURLImagePreviewEntries(notContainedIn plainText: String) {
        var entries = urlImagePreviewEntries
        let before = entries.count
        entries.removeAll { !plainText.contains($0.url) }
        if entries.count != before {
            urlImagePreviewEntries = entries
        }
    }
}

/// A complete editor draft, also used to restore a failed write without discarding other notes.
struct NoteDocumentSnapshot: Equatable {
    var richTextData: Data
    var plainText: String
    var lastEditedAt: Date
    var urlImagePreviewStateJSON: Data
    var textAlignmentRawValue: String?
    var linePrefixModeRawValue: String?
    var capturedImageData: Data?

    init(_ note: NoteDocument) {
        richTextData = note.richTextData
        plainText = note.plainText
        lastEditedAt = note.lastEditedAt
        urlImagePreviewStateJSON = note.urlImagePreviewStateJSON
        textAlignmentRawValue = note.textAlignmentRawValue
        linePrefixModeRawValue = note.linePrefixModeRawValue
        capturedImageData = note.capturedImageData
    }

    func apply(to note: NoteDocument) {
        note.richTextData = richTextData
        note.plainText = plainText
        note.lastEditedAt = lastEditedAt
        note.urlImagePreviewStateJSON = urlImagePreviewStateJSON
        note.textAlignmentRawValue = textAlignmentRawValue
        note.linePrefixModeRawValue = linePrefixModeRawValue
        note.capturedImageData = capturedImageData
    }

    func hasSameContent(as other: NoteDocumentSnapshot) -> Bool {
        var lhs = self
        lhs.lastEditedAt = other.lastEditedAt
        return lhs == other
    }

    @MainActor
    func save(to note: NoteDocument, in context: ModelContext, expected: NoteDocumentSnapshot? = nil) throws {
        guard !note.isDeleted, note.modelContext != nil else { throw NoteSaveError.removedElsewhere }
        let previous = NoteDocumentSnapshot(note)
        if let expected, !previous.hasSameContent(as: expected) {
            throw NoteSaveError.changedElsewhere
        }
        apply(to: note)
        do { try context.save() }
        catch {
            previous.apply(to: note)
            throw error
        }
    }
}

enum NoteSaveError: LocalizedError {
    case changedElsewhere
    case removedElsewhere
    var errorDescription: String? {
        switch self {
        case .changedElsewhere:
            "This note changed elsewhere while you were editing. Keep your draft as a separate note to preserve both versions."
        case .removedElsewhere:
            "This saved note was removed elsewhere. Keep your draft as a separate note to save it."
        }
    }
}
