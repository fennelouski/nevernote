//
//  TextFormatAction.swift
//  NeverNote
//
//  Created by Nathan Fennel on 5/17/26.
//  Copyright © 2026 Nathan Fennel. All rights reserved.
//

import Foundation

enum TextFormatAction: Equatable {
    case bold
    case italic
    case underline
    case font(String)
    case alignment(NoteTextAlignment)
    case refreshDerivedDisplay
    case selectAll
    case fontSize(CGFloat)
    case resetFormatting
}

struct EditorCommand: Equatable {
    let id: Int
    let action: TextFormatAction
}
