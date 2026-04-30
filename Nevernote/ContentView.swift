//
//  ContentView.swift
//  Nevernote
//
//  Created by Nathan Fennel on 4/30/26.
//

import SwiftData
import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NoteDocument.lastEditedAt, order: .reverse) private var notes: [NoteDocument]

    @State private var attributedText = NSAttributedString(string: "")
    @State private var isEditing = false
    @State private var isKeyboardVisible = false
    @State private var editorHasFocus = false
    @State private var hasLoadedExistingNote = false
    @State private var commandCounter = 0
    @State private var editorCommand: EditorCommand?

    private var activeNote: NoteDocument? { notes.first }

    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.95, blue: 0.96).ignoresSafeArea()

            VStack(spacing: 0) {
                if isEditing {
                    topBar
                }

                Spacer(minLength: 20)

                noteCanvas

                Spacer(minLength: 20)

                if isEditing {
                    editorToolbar
                }
            }
        }
        .onAppear {
            ensureSingleNoteExists()
            loadNoteIfNeeded()
        }
        .onChange(of: notes.count) { _, _ in
            ensureSingleNoteExists()
            loadNoteIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
            isEditing = true
            editorHasFocus = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
            isEditing = false
            editorHasFocus = false
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 17, weight: .semibold))
            }

            Text("Nevernote")
                .font(.headline)
                .foregroundStyle(Color.black.opacity(0.95))

            Spacer()

            Button(action: {}) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
            }

            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
            }
        }
        .foregroundStyle(Color.blue)
        .padding(.horizontal, 18)
        .frame(height: 56)
        .background(Color.white.opacity(0.96))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(height: 1)
        }
    }

    private var noteCanvas: some View {
        VStack(spacing: 18) {
            if isEditing {
                RichTextEditor(
                    attributedText: $attributedText,
                    isFirstResponder: $editorHasFocus,
                    command: editorCommand,
                    onChange: persistNote
                )
                .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 360)
                .padding(.horizontal, 26)
            } else {
                FocusTextView(attributedText: attributedText)
                    .padding(.horizontal, 24)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editorHasFocus = true
                        isEditing = true
                    }
            }

            Text(footerText)
                .font(.system(size: 14, weight: .semibold, design: .default))
                .tracking(2)
                .foregroundStyle(Color.black.opacity(0.20))
        }
    }

    private var editorToolbar: some View {
        HStack(spacing: 20) {
            Button(action: { sendEditorCommand(.bold) }) {
                Image(systemName: "bold")
            }
            .accessibilityLabel("Bold")

            Button(action: { sendEditorCommand(.italic) }) {
                Image(systemName: "italic")
            }
            .accessibilityLabel("Italic")

            Button(action: { sendEditorCommand(.underline) }) {
                Image(systemName: "underline")
            }
            .accessibilityLabel("Underline")

            Spacer()

            Button("Done") {
                editorHasFocus = false
                isEditing = false
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(Color.blue)
        }
        .padding(.horizontal, 22)
        .frame(height: 56)
        .background(Color.white.opacity(0.97))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.black.opacity(0.05))
                .frame(height: 1)
        }
    }

    private var footerText: String {
        if let note = activeNote {
            return "LAST EDITED \(RelativeDateTimeFormatter().localizedString(for: note.lastEditedAt, relativeTo: .now))."
        }
        return "NEVERNOTE FOCUS"
    }

    private func ensureSingleNoteExists() {
        guard notes.isEmpty else { return }
        let newNote = NoteDocument()
        modelContext.insert(newNote)
        try? modelContext.save()
    }

    private func loadNoteIfNeeded() {
        guard let note = activeNote, !hasLoadedExistingNote else { return }
        if let decoded = decodeRichText(note.richTextData), decoded.length > 0 {
            attributedText = decoded
        } else if !note.plainText.isEmpty {
            attributedText = NSAttributedString(string: note.plainText)
        }
        hasLoadedExistingNote = true
    }

    private func persistNote() {
        guard let note = activeNote else { return }
        note.lastEditedAt = .now
        note.plainText = attributedText.string
        note.richTextData = encodeRichText(attributedText) ?? Data()
        try? modelContext.save()
    }

    private func sendEditorCommand(_ action: TextFormatAction) {
        commandCounter += 1
        editorCommand = EditorCommand(id: commandCounter, action: action)
    }

    private func decodeRichText(_ data: Data) -> NSAttributedString? {
        guard !data.isEmpty else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: data)
    }

    private func encodeRichText(_ value: NSAttributedString) -> Data? {
        try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: false)
    }
}

private struct FocusTextView: View {
    let attributedText: NSAttributedString

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let availableHeight = max(proxy.size.height * 0.65, 1)
            let measuredHeight = max(measureHeight(constrainedTo: width), 1)
            let scale = min(1.0, availableHeight / measuredHeight)
            let rendered = (try? AttributedString(attributedText, including: \.uiKit)) ?? AttributedString(attributedText.string)

            Text(rendered)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .scaleEffect(scale, anchor: .center)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: 420)
    }

    private func measureHeight(constrainedTo width: CGFloat) -> CGFloat {
        let bounds = attributedText.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return ceil(bounds.height)
    }
}

private enum TextFormatAction {
    case bold
    case italic
    case underline
}

private struct EditorCommand: Equatable {
    let id: Int
    let action: TextFormatAction
}

private struct RichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var isFirstResponder: Bool
    let command: EditorCommand?
    let onChange: () -> Void

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textAlignment = .center
        textView.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        textView.tintColor = .systemBlue
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        textView.attributedText = attributedText
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.attributedText != attributedText {
            uiView.attributedText = attributedText
        }

        if isFirstResponder && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFirstResponder && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }

        if let command, context.coordinator.lastAppliedCommandId != command.id {
            context.coordinator.lastAppliedCommandId = command.id
            context.coordinator.apply(command: command.action, to: uiView)
            attributedText = uiView.attributedText
            onChange()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        var lastAppliedCommandId: Int = 0

        init(parent: RichTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.attributedText = textView.attributedText
            parent.onChange()
        }

        func apply(command: TextFormatAction, to textView: UITextView) {
            let selection = textView.selectedRange
            let mutable = NSMutableAttributedString(attributedString: textView.attributedText)

            switch command {
            case .bold:
                toggleTrait(.traitBold, in: mutable, selection: selection, typingAttributes: &textView.typingAttributes)
            case .italic:
                toggleTrait(.traitItalic, in: mutable, selection: selection, typingAttributes: &textView.typingAttributes)
            case .underline:
                toggleUnderline(in: mutable, selection: selection, typingAttributes: &textView.typingAttributes)
            }

            textView.attributedText = mutable
            textView.selectedRange = selection
        }

        private func toggleTrait(
            _ trait: UIFontDescriptor.SymbolicTraits,
            in text: NSMutableAttributedString,
            selection: NSRange,
            typingAttributes: inout [NSAttributedString.Key: Any]
        ) {
            guard selection.length > 0 else {
                let currentFont = (typingAttributes[.font] as? UIFont) ?? UIFont.systemFont(ofSize: 24, weight: .bold)
                typingAttributes[.font] = toggledFont(from: currentFont, trait: trait)
                return
            }

            text.enumerateAttribute(.font, in: selection) { value, range, _ in
                let existing = (value as? UIFont) ?? UIFont.systemFont(ofSize: 24, weight: .bold)
                text.addAttribute(.font, value: toggledFont(from: existing, trait: trait), range: range)
            }
        }

        private func toggledFont(from font: UIFont, trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
            var traits = font.fontDescriptor.symbolicTraits
            if traits.contains(trait) {
                traits.remove(trait)
            } else {
                traits.insert(trait)
            }

            guard let descriptor = font.fontDescriptor.withSymbolicTraits(traits) else { return font }
            return UIFont(descriptor: descriptor, size: font.pointSize)
        }

        private func toggleUnderline(
            in text: NSMutableAttributedString,
            selection: NSRange,
            typingAttributes: inout [NSAttributedString.Key: Any]
        ) {
            guard selection.length > 0 else {
                let current = typingAttributes[.underlineStyle] as? Int ?? 0
                typingAttributes[.underlineStyle] = current == 0 ? NSUnderlineStyle.single.rawValue : 0
                return
            }

            text.enumerateAttribute(.underlineStyle, in: selection) { value, range, _ in
                let current = value as? Int ?? 0
                let next = current == 0 ? NSUnderlineStyle.single.rawValue : 0
                text.addAttribute(.underlineStyle, value: next, range: range)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: NoteDocument.self, inMemory: true)
}
