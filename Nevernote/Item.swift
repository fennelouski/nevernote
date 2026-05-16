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
    @Attribute(.unique) var id: UUID
    var richTextData: Data
    var plainText: String
    var lastEditedAt: Date
    /// JSON array of `NoteURLImagePreviewEntry` — toggles "show image at bottom" for http(s) links.
    var urlImagePreviewStateJSON: Data
    var textAlignmentRawValue: String?
    var linePrefixModeRawValue: String?

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
