import SwiftUI

private enum NoteImageEducation {
    static let hasShownKey = "NeverNote.hasShownImageEducationalModal"

    static var hasBeenShown: Bool {
        UserDefaults.standard.bool(forKey: hasShownKey)
    }

    static func markShown() {
        UserDefaults.standard.set(true, forKey: hasShownKey)
    }
}

struct NoteImageEducationalModal: View {
    let permissionManager: NoteImagePermissionManager
    let onComplete: () -> Void
    var onClose: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedDetent: PresentationDetent = .medium

    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(spacing: 32) {
                    Image(systemName: educationIconName)
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(Color.brandBlue)

                    VStack(spacing: 12) {
                        Text("Import Text from a Photo")
                            .font(.title2.bold())
                            .neverNoteWrappingLabel()

                        Text(educationBodyText)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .neverNoteWrappingLabel()
                            .padding(.horizontal, 8)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            Button {
                NoteImageEducation.markShown()
                closePanel()
                Task {
                    #if os(macOS)
                    await permissionManager.requestPhotoLibrary()
                    #else
                    await permissionManager.requestBoth()
                    #endif
                    await MainActor.run { onComplete() }
                }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .neverNoteWrappingLabel()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.brandBlue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .neverNoteShortcut(.continueAction)

            Button("Not Now") {
                NoteImageEducation.markShown()
                closePanel()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .neverNoteShortcut(.cancel)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        #if os(iOS)
        .presentationDetents([.medium, .large], selection: $selectedDetent)
        .presentationDragIndicator(.visible)
        .onAppear {
            if dynamicTypeSize.isAccessibilitySize {
                selectedDetent = .large
            }
        }
        #endif
    }

    private func closePanel() {
        #if os(macOS)
        onClose?()
        #else
        dismiss()
        #endif
    }
}

extension NoteImageEducationalModal {
    static var hasBeenShown: Bool { NoteImageEducation.hasBeenShown }

    static func recordShown() {
        NoteImageEducation.markShown()
    }

    private var educationIconName: String {
        #if os(macOS)
        "photo.on.rectangle"
        #else
        "camera.viewfinder"
        #endif
    }

    private var educationBodyText: String {
        #if os(macOS)
        "Choose a photo from your library or files. NeverNote will read any text in the image and add it to your note. QR codes in the image are added at the bottom of the note."
        #else
        "Take a photo or choose one from your library. NeverNote will read any text in the image and add it to your note. QR codes in the image are added at the bottom of the note."
        #endif
    }
}
