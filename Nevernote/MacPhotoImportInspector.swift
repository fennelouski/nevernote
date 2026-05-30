#if os(macOS)
import AppKit
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct MacPhotoImportInspector: View {
    let onClose: () -> Void
    let permissionManager: NoteImagePermissionManager
    let onImageSelected: (PlatformImage) -> Void

    @State private var selectedItem: PhotosPickerItem?
    @State private var showFileImporter = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Photo Library", systemImage: "photo.on.rectangle")
                    }
                    Button {
                        showFileImporter = true
                    } label: {
                        Label("Browse Files…", systemImage: "folder")
                    }
                } footer: {
                    Text("NeverNote will read any text in the image and add it to your note.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Choose Photo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onClose)
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.image],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    let didAccess = url.startAccessingSecurityScopedResource()
                    defer {
                        if didAccess {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    guard let image = NSImage(contentsOf: url) else { return }
                    onImageSelected(image)
                    onClose()
                case .failure:
                    break
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    guard let data = try? await newItem.loadTransferable(type: Data.self),
                          let image = NSImage(data: data) else { return }
                    await MainActor.run {
                        onImageSelected(image)
                        selectedItem = nil
                        onClose()
                    }
                }
            }
            .task {
                await permissionManager.requestPhotoLibrary()
            }
        }
    }
}
#endif
