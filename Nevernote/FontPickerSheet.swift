//
//  FontPickerSheet.swift
//  NeverNote
//
//  Created by Nathan Fennel on 5/17/26.
//  Copyright © 2026 Nathan Fennel. All rights reserved.
//

import SwiftUI

struct FontPickerSheet: View {
    let currentToken: String
    let currentSize: CGFloat
    let recentTokens: [String]
    let onSelect: (String) -> Void
    let onSelectSize: (CGFloat) -> Void
    let onReset: () -> Void
    var onClose: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @ScaledMetric(relativeTo: .body) private var previewPointSize: CGFloat = EditorFont.editorPointSize

    private var filteredRecentFonts: [String] {
        recentTokens
            .filter { EditorFont.normalizedFontToken($0) != EditorFont.systemBoldStorageToken }
            .filter { EditorFont.sortedPostScriptNames.contains($0) }
            .filter(matchesQuery)
    }

    private var filteredAllFonts: [String] {
        let excluded = Set(filteredRecentFonts)
        let all = EditorFont.sortedPostScriptNames.filter { !excluded.contains($0) }
        guard !searchQuery.isEmpty else { return all }
        return all.filter(matchesQuery)
    }

    private var searchQuery: String {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return q
    }

    private var shouldShowSystemBold: Bool {
        searchQuery.isEmpty
            || EditorFont.displayName(forToken: EditorFont.systemBoldStorageToken)
                .localizedCaseInsensitiveContains(searchQuery)
    }

    private func matchesQuery(_ token: String) -> Bool {
        guard !searchQuery.isEmpty else { return true }
        return token.localizedCaseInsensitiveContains(searchQuery)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Size") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach([14, 18, 20, 24, 28, 32, 36, 48, 64] as [CGFloat], id: \.self) { size in
                                let isSelected = currentSize == size
                                Button {
                                    onSelectSize(size)
                                } label: {
                                    Text(String(Int(size)))
                                        .font(.system(size: 14, weight: .medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(isSelected ? Color.brandBlue : Color.clear)
                                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(isSelected ? Color.clear : Color.secondary.opacity(0.5), lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }

                if shouldShowSystemBold {
                    Section {
                        fontRow(
                            title: EditorFont.displayName(forToken: EditorFont.systemBoldStorageToken),
                            token: EditorFont.systemBoldStorageToken
                        )
                    }
                }

                if !filteredRecentFonts.isEmpty {
                    Section("Recent") {
                        ForEach(filteredRecentFonts, id: \.self) { name in
                            fontRow(title: name, token: name)
                        }
                    }
                }

                if !filteredAllFonts.isEmpty {
                    Section("All Fonts") {
                        ForEach(filteredAllFonts, id: \.self) { name in
                            fontRow(title: name, token: name)
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "Search fonts")
            .navigationTitle("Font")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: closePanel)
                        .neverNoteShortcut(.cancel)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Reset") {
                        onReset()
                        closePanel()
                    }
                    .neverNoteShortcut(.resetFormatting)
                }
            }
        }
    }

    private func closePanel() {
        #if os(macOS)
        onClose?()
        #else
        dismiss()
        #endif
    }

    private func fontRow(title: String, token: String) -> some View {
        Button {
            onSelect(token)
        } label: {
            HStack {
                Text(title)
                    .font(Font(EditorFont.platformFont(forToken: token, size: previewPointSize)))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                Spacer()
                if token == currentToken {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.brandBlue)
                }
            }
        }
    }
}
