//
//  NoteDataDetectorConfirmationDialog.swift
//  NeverNote
//
//  Created by Nathan Fennel on 5/17/26.
//  Copyright © 2026 Nathan Fennel. All rights reserved.
//

import SwiftUI

extension View {
    func noteDataDetectorConfirmationDialog(
        item: Binding<NoteDataDetectorInteraction?>
    ) -> some View {
        confirmationDialog(
            String(localized: "Smart link"),
            isPresented: Binding(
                get: { item.wrappedValue != nil },
                set: { if !$0 { item.wrappedValue = nil } }
            ),
            presenting: item.wrappedValue
        ) { interaction in
            Button(interaction.primaryActionTitle) {
                interaction.performPrimaryAction()
                item.wrappedValue = nil
            }
            .neverNoteShortcut(.continueAction)
            Button(String(localized: "Copy")) {
                NoteDataDetectorInteraction.copyToPasteboard(interaction.copyText)
                item.wrappedValue = nil
            }
            .neverNoteShortcut(.copy)
            Button(String(localized: "Cancel"), role: .cancel) {
                item.wrappedValue = nil
            }
            .neverNoteShortcut(.cancel)
        } message: { interaction in
            Text(interaction.displayText)
        }
    }
}
