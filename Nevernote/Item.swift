//
//  Item.swift
//  Nevernote
//
//  Created by Nathan Fennel on 4/30/26.
//

import Foundation
import SwiftData

@Model
final class NoteDocument {
    @Attribute(.unique) var id: UUID
    var richTextData: Data
    var plainText: String
    var lastEditedAt: Date

    init(
        id: UUID = UUID(),
        richTextData: Data = Data(),
        plainText: String = "",
        lastEditedAt: Date = .now
    ) {
        self.id = id
        self.richTextData = richTextData
        self.plainText = plainText
        self.lastEditedAt = lastEditedAt
    }
}
