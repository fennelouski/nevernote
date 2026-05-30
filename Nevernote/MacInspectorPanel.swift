#if os(macOS)
import AppKit
import SwiftUI

struct MacConfirmationRequest: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let confirmTitle: String
}

struct MacSharePayload: Identifiable, Equatable {
    let id = UUID()
    let itemCount: Int

    init(items: [Any]) {
        itemCount = items.count
    }
}

enum MacInspectorPanel: Identifiable, Equatable {
    case imageEducation
    case photoImport
    case fontPicker
    case capturedImage(id: UUID, image: PlatformImage)
    case share(MacSharePayload)
    case confirmation(MacConfirmationRequest)

    var id: String {
        switch self {
        case .imageEducation: "imageEducation"
        case .photoImport: "photoImport"
        case .fontPicker: "fontPicker"
        case .capturedImage(let id, _): "capturedImage-\(id.uuidString)"
        case .share(let payload): "share-\(payload.id.uuidString)"
        case .confirmation(let request): "confirmation-\(request.id.uuidString)"
        }
    }

    static func == (lhs: MacInspectorPanel, rhs: MacInspectorPanel) -> Bool {
        lhs.id == rhs.id
    }
}

struct MacInspectorModifier: ViewModifier {
    @Binding var panel: MacInspectorPanel?
    @Binding var shareItems: [Any]
    var permissionManager: NoteImagePermissionManager
    var editorFontName: String
    var editorStoredPointSize: CGFloat
    var onImageSelected: (PlatformImage) -> Void
    var onEducationComplete: () -> Void
    var onFontSelect: (String) -> Void
    var onFontSelectSize: (CGFloat) -> Void
    var onFontReset: () -> Void
    var onConfirmationConfirm: () -> Void

    func body(content: Content) -> some View {
        content
            .inspector(isPresented: inspectorPresented) {
                if let panel {
                    inspectorContent(for: panel)
                }
            }
            .inspectorColumnWidth(min: 280, ideal: 360, max: 480)
    }

    private var inspectorPresented: Binding<Bool> {
        Binding(
            get: { panel != nil },
            set: { if !$0 { panel = nil } }
        )
    }

    @ViewBuilder
    private func inspectorContent(for panel: MacInspectorPanel) -> some View {
        switch panel {
        case .imageEducation:
            NoteImageEducationalModal(
                permissionManager: permissionManager,
                onComplete: onEducationComplete,
                onClose: { self.panel = nil }
            )
        case .photoImport:
            MacPhotoImportInspector(
                onClose: { self.panel = nil },
                permissionManager: permissionManager,
                onImageSelected: onImageSelected
            )
        case .fontPicker:
            FontPickerSheet(
                currentToken: editorFontName,
                currentSize: editorStoredPointSize,
                recentTokens: EditorFont.recentTokens(),
                onSelect: onFontSelect,
                onSelectSize: onFontSelectSize,
                onReset: onFontReset,
                onClose: { self.panel = nil }
            )
        case .capturedImage(_, let image):
            NoteImageFullScreenModal(
                image: image,
                presentationStyle: .inspector,
                onDismiss: { self.panel = nil }
            )
        case .share:
            MacShareInspector(items: shareItems, onClose: { self.panel = nil })
        case .confirmation(let request):
            MacConfirmationInspector(
                request: request,
                onConfirm: {
                    onConfirmationConfirm()
                    self.panel = nil
                },
                onCancel: { self.panel = nil }
            )
        }
    }
}

extension View {
    func neverNoteMacInspector(
        panel: Binding<MacInspectorPanel?>,
        shareItems: Binding<[Any]>,
        permissionManager: NoteImagePermissionManager,
        editorFontName: String,
        editorStoredPointSize: CGFloat,
        onImageSelected: @escaping (PlatformImage) -> Void,
        onEducationComplete: @escaping () -> Void,
        onFontSelect: @escaping (String) -> Void,
        onFontSelectSize: @escaping (CGFloat) -> Void,
        onFontReset: @escaping () -> Void,
        onConfirmationConfirm: @escaping () -> Void
    ) -> some View {
        modifier(
            MacInspectorModifier(
                panel: panel,
                shareItems: shareItems,
                permissionManager: permissionManager,
                editorFontName: editorFontName,
                editorStoredPointSize: editorStoredPointSize,
                onImageSelected: onImageSelected,
                onEducationComplete: onEducationComplete,
                onFontSelect: onFontSelect,
                onFontSelectSize: onFontSelectSize,
                onFontReset: onFontReset,
                onConfirmationConfirm: onConfirmationConfirm
            )
        )
    }
}

struct MacShareInspector: View {
    let items: [Any]
    let onClose: () -> Void

    private var services: [NSSharingService] {
        NSSharingService.sharingServices(forItems: items)
    }

    var body: some View {
        NavigationStack {
            List(services, id: \.title) { service in
                Button {
                    service.perform(withItems: items)
                    onClose()
                } label: {
                    HStack(spacing: 12) {
                        Image(nsImage: service.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text(service.title)
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Share")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onClose)
                }
            }
        }
    }
}

struct MacConfirmationInspector: View {
    let request: MacConfirmationRequest
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(request.title)
                    .font(.title3.bold())
                Text(request.message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                HStack {
                    Button("Cancel", action: onCancel)
                        .keyboardShortcut(.cancelAction)
                    Spacer()
                    Button(request.confirmTitle, action: onConfirm)
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationTitle("Confirm")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
}
#endif
