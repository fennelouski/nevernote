//
//  NevernoteNotification.swift
//  NeverNote
//
//  Created by Nathan Fennel on 5/17/26.
//  Copyright © 2026 Nathan Fennel. All rights reserved.
//

import Foundation

enum NevernoteNotification {
    static let shakeUndo = Notification.Name("NNShakeUndoNotification")
    #if DEBUG
    static let showFeatureFlags = Notification.Name("NNShowFeatureFlagsNotification")
    #endif
}
