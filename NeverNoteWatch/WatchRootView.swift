//
//  WatchRootView.swift
//  Nevernote
//

import SwiftData
import SwiftUI

struct WatchRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NoteDocument.lastEditedAt, order: .reverse) private var notes: [NoteDocument]

    @State private var showAddText = false
    @State private var draftText = ""

    @State private var activeNote: NoteDocument?
    @State private var addingToNote: NoteDocument?
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    if let saveError {
                        Text("Not saved: " + saveError).font(.caption)
                    }
                    if notes.count > 1 {
                        Picker("Saved note", selection: $activeNote) {
                            ForEach(notes) { note in
                                Text(note.plainText.isEmpty ? "Photo or empty note" : String(note.plainText.prefix(30)))
                                    .tag(Optional(note))
                            }
                        }
                    }
                    Text(displayString)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 6)
                }
            }
            .navigationTitle("Nevernote")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addingToNote = activeNote
                        draftText = ""
                        showAddText = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add text")
                }
            }
            .sheet(isPresented: $showAddText) {
                NavigationStack {
                    VStack {
                        TextField("Dictate or type", text: $draftText)
                        if let saveError { Text("Not saved: " + saveError).font(.caption) }
                        Spacer(minLength: 0)
                    }
                    .padding()
                    .navigationTitle("Add")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showAddText = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                if let note = addingToNote, appendFragment(draftText, to: note) {
                                    addingToNote = nil
                                    showAddText = false
                                }
                            }
                            .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                .interactiveDismissDisabled(!draftText.isEmpty)
            }
        }
        .onAppear(perform: ensureSingleNoteExists)
    }

    private var displayString: String {
        if let config = WatchScreenshotMode.config {
            return config.noteText
        }
        let text = activeNote?.plainText ?? ""
        return text.isEmpty ? " " : text
    }

    private func ensureSingleNoteExists() {
        guard activeNote == nil else { return }
        if let existing = notes.first { activeNote = existing; return }
        let note = NoteDocument()
        modelContext.insert(note)
        activeNote = note
        do { try modelContext.save(); saveError = nil }
        catch { saveError = error.localizedDescription }
    }

    private func appendFragment(_ fragment: String, to note: NoteDocument) -> Bool {
        let trimmed = fragment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let base: NSAttributedString
        if let decoded = NoteRichTextCodec.decode(note.richTextData), decoded.length > 0 {
            base = decoded
        } else if !note.plainText.isEmpty {
            base = NSAttributedString(string: note.plainText)
        } else {
            base = NSAttributedString(string: "")
        }

        let mutable = NSMutableAttributedString(attributedString: base)
        if mutable.length > 0 {
            mutable.append(NSAttributedString(string: "\n"))
        }
        mutable.append(NSAttributedString(string: trimmed))

        guard let encoded = NoteRichTextCodec.encode(mutable) else {
            saveError = "The text could not be encoded. Your draft is still here."
            return false
        }
        var draft = NoteDocumentSnapshot(note)
        draft.plainText = mutable.string
        draft.richTextData = encoded
        draft.lastEditedAt = .now
        do {
            try draft.save(to: note, in: modelContext)
            saveError = nil
            return true
        } catch {
            saveError = error.localizedDescription
            return false
        }
    }
}
