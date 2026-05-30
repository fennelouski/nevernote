//
//  NoteDataDetectors.swift
//  NeverNote
//
//  Created by Nathan Fennel on 5/17/26.
//  Copyright © 2026 Nathan Fennel. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum NoteDataDetectors {
    static let appStorageKey = "nevernote.dataDetectorsEnabled"
    #if canImport(UIKit)
    static let enabledTypes: UIDataDetectorTypes = .all
    #endif
    static let enabledCheckingTypes: NSTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue
        | NSTextCheckingResult.CheckingType.phoneNumber.rawValue
        | NSTextCheckingResult.CheckingType.address.rawValue
        | NSTextCheckingResult.CheckingType.date.rawValue

    static func textWouldTriggerDataDetectors(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        #if canImport(UIKit)
        let checkingTypes = NSTextCheckingTypes(enabledTypes.rawValue)
        #else
        let checkingTypes = enabledCheckingTypes
        #endif
        guard let detector = try? NSDataDetector(types: checkingTypes) else { return false }
        let len = (text as NSString).length
        guard len > 0 else { return false }
        return detector.firstMatch(in: text, options: [], range: NSRange(location: 0, length: len)) != nil
    }
}
