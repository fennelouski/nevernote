# Nevernote

Nevernote is an iOS note-taking app focused on a single distraction-free note with rich text formatting and local persistence.

## Features

- Single-note workspace with centered reading mode
- Rich text editing with bold, italic, and underline controls
- Automatic persistence of plain text and attributed text
- `SwiftData` model storage with CloudKit-enabled configuration
- Keyboard-aware editing UI with lightweight toolbar controls

## Tech Stack

- SwiftUI
- SwiftData
- UIKit bridge (`UITextView`) for rich text editing
- Xcode project: `NeverNote.xcodeproj`

## Project Structure

- `NeverNote/NevernoteApp.swift` - app entry point and `ModelContainer` setup
- `NeverNote/ContentView.swift` - primary UI, editor flow, and persistence hooks
- `NeverNote/Item.swift` - `SwiftData` `@Model` (`NoteDocument`)
- `NeverNote1/` - legacy Objective-C code and assets retained in the repo

## Getting Started

1. Open `NeverNote.xcodeproj` in Xcode.
2. Select a simulator or device.
3. Build and run.

## Data Model

`NoteDocument` stores:

- `id` (`UUID`, unique)
- `richTextData` (`Data`)
- `plainText` (`String`)
- `lastEditedAt` (`Date`)

## Notes

- Existing modernization and onboarding docs are in `MODERNIZATION_TODO.md` and `ONBOARDING.md`.
- The app currently prioritizes a single active note experience rather than multi-note navigation.
