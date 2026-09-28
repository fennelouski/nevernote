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

- The app currently prioritizes a single active note experience rather than multi-note navigation.

## Release 1.2 storage and privacy notes

The app keeps the existing `NevernoteSwiftData/notes.store` and any earlier
`notes-local.store` in Application Support. It creates a one-time `-before-1.2`
recovery copy before opening each existing store. If both stores exist, launch
asks which to open; neither is merged or deleted. An unreadable store presents
recovery choices instead of silently opening an empty or in-memory note.
Opening the primary store without iCloud is an explicit recovery option.

The editor holds a stable note identity. When several notes are present, the
saved-note menu makes them accessible. Save failures keep the editor or watch
input open; conflicting incoming changes can be kept alongside the local draft
as a separate note. Clear/Undo preserves the photo, rich text and preview
preferences. Photo-only notes remain saved. On-device recognition and
translation must not overwrite text changed while they were running.

CloudKit requires the app and watch identifiers to have iCloud and Push
Notifications provisioning for `iCloud.com.nathanfennel.NeverNote`. Production
CloudKit schema deployment and cross-device behavior still require a signed,
authenticated device check; a local store test does not verify that service.

Linked images contact the user-selected website after confirmation. Enabled
previews may load again when a note reopens. The site's privacy policy applies;
notes are not sent to a developer backend. Translation uses Apple's on-device
framework on supported iOS/macOS versions and is unavailable on visionOS.

Run `scripts/check-persistence.sh` for actual old-schema SQLite migration,
photo-only/undo/conflict and disk-failure checks in isolated temporary stores.
Run `scripts/check-logic.py` for the existing 24 logic tests without opening the
app or a Simulator. These checks do not replace camera, watch input, VoiceOver,
real UI, CloudKit or App Store distribution validation.
