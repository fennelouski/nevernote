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

    private var activeNote: NoteDocument? { notes.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(displayString)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)
            }
            .navigationTitle("Nevernote")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
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
                    TextField("Dictate or type", text: $draftText)
                        .padding()
                    Spacer(minLength: 0)
                }
                .navigationTitle("Add")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showAddText = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if let note = activeNote {
                                appendFragment(draftText, to: note)
                            }
                            showAddText = false
                        }
                    }
                }
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
        guard notes.isEmpty else { return }
        modelContext.insert(NoteDocument())
        try? modelContext.save()
    }

    private func appendFragment(_ fragment: String, to note: NoteDocument) {
        let trimmed = fragment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

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

        note.plainText = mutable.string
        note.richTextData = NoteRichTextCodec.encode(NSAttributedString(attributedString: mutable)) ?? Data()
        note.lastEditedAt = .now
        try? modelContext.save()
    }
}
