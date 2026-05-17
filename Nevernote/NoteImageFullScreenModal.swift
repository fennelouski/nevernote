import SwiftUI

struct FullScreenImagePresentation: Identifiable {
    let id = UUID()
    let image: PlatformImage
}

enum NoteImagePreviewPresentationStyle {
    case fullscreen
    case inspector
}

struct NoteImageFullScreenModal: View {
    let image: PlatformImage
    var presentationStyle: NoteImagePreviewPresentationStyle = .fullscreen
    var onDismiss: () -> Void

    private var isInspectorStyle: Bool { presentationStyle == .inspector }

    @State private var zoomScale: CGFloat = 1
    @State private var panOffset: CGSize = .zero
    @State private var steadyPanOffset: CGSize = .zero
    @State private var dismissDrag: CGFloat = 0

    @State private var pinchBaseScale: CGFloat = 1
    @State private var pinchBaseOffset: CGSize = .zero
    @State private var pinchAnchor: UnitPoint = .center
    @State private var isPinching = false

    private let zoomedInScale: CGFloat = 2.5
    private let minZoomScale: CGFloat = 1
    private let maxZoomScale: CGFloat = 4
    private let dismissThreshold: CGFloat = 120
    /// Pinch releases below this snap back to fit so double-tap does not zoom in further.
    private let pinchSnapToFitThreshold: CGFloat = 0.08

    private var isAtFit: Bool { zoomScale <= minZoomScale + 0.001 }
    private var isZoomedOut: Bool { zoomScale <= minZoomScale + 0.01 }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            (isInspectorStyle ? Color.noteCanvas : Color.black)
                .opacity(isInspectorStyle ? 1 : (1 - min(dismissDrag / 300, 0.5)))
                .ignoresSafeArea()

            GeometryReader { geo in
                platformImageView(image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(zoomScale)
                    .offset(x: panOffset.width, y: panOffset.height + dismissDrag)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        SpatialTapGesture(count: 2)
                            .onEnded { value in
                                toggleZoom(at: value.location, in: geo.size)
                            }
                    )
                    .simultaneousGesture(magnifyGesture(containerSize: geo.size))
                    .gesture(dragGesture)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()

            if !isInspectorStyle {
                Button(action: close) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.white.opacity(0.85))
                        .shadow(radius: 4)
                }
                .padding(.top, 16)
                .padding(.trailing, 20)
                .neverNoteShortcut(.closeImage)
            }
        }
        #if os(iOS)
        .statusBarHidden(true)
        #endif
    }

    @ViewBuilder
    private func platformImageView(_ image: PlatformImage) -> Image {
        #if canImport(UIKit)
        Image(uiImage: image)
        #else
        Image(nsImage: image)
        #endif
    }

    private func magnifyGesture(containerSize: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                if !isPinching {
                    isPinching = true
                    pinchBaseScale = zoomScale
                    pinchBaseOffset = panOffset
                    pinchAnchor = value.startAnchor
                }
                applyScale(
                    pinchBaseScale * value.magnification,
                    anchor: pinchAnchor,
                    baseOffset: pinchBaseOffset,
                    containerSize: containerSize
                )
            }
            .onEnded { value in
                applyScale(
                    pinchBaseScale * value.magnification,
                    anchor: pinchAnchor,
                    baseOffset: pinchBaseOffset,
                    containerSize: containerSize
                )
                steadyPanOffset = panOffset
                isPinching = false

                if zoomScale < minZoomScale + pinchSnapToFitThreshold {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        resetToFit()
                    }
                }
            }
    }

    private func toggleZoom(at location: CGPoint, in containerSize: CGSize) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            if isAtFit {
                applyScale(
                    zoomedInScale,
                    anchor: unitPoint(for: location, in: containerSize),
                    baseOffset: panOffset,
                    baseScale: zoomScale,
                    containerSize: containerSize
                )
                steadyPanOffset = panOffset
            } else {
                resetToFit()
            }
        }
    }

    private func resetToFit() {
        zoomScale = minZoomScale
        panOffset = .zero
        steadyPanOffset = .zero
    }

    private func applyScale(
        _ targetScale: CGFloat,
        anchor: UnitPoint,
        baseOffset: CGSize,
        baseScale: CGFloat? = nil,
        containerSize: CGSize
    ) {
        let fromScale = baseScale ?? pinchBaseScale
        let newScale = min(max(targetScale, minZoomScale), maxZoomScale)
        let scaleRatio = newScale / fromScale
        let anchorFromCenter = CGPoint(
            x: (anchor.x - 0.5) * containerSize.width,
            y: (anchor.y - 0.5) * containerSize.height
        )
        panOffset = CGSize(
            width: anchorFromCenter.x - (anchorFromCenter.x - baseOffset.width) * scaleRatio,
            height: anchorFromCenter.y - (anchorFromCenter.y - baseOffset.height) * scaleRatio
        )
        zoomScale = newScale
    }

    private func unitPoint(for location: CGPoint, in containerSize: CGSize) -> UnitPoint {
        UnitPoint(
            x: location.x / max(containerSize.width, 1),
            y: location.y / max(containerSize.height, 1)
        )
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                if isPinching { return }
                if isZoomedOut {
                    dismissDrag = max(0, value.translation.height)
                } else {
                    panOffset = CGSize(
                        width: steadyPanOffset.width + value.translation.width,
                        height: steadyPanOffset.height + value.translation.height
                    )
                }
            }
            .onEnded { value in
                if isPinching { return }
                if isZoomedOut {
                    if value.translation.height > dismissThreshold {
                        close()
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            dismissDrag = 0
                        }
                    }
                } else {
                    steadyPanOffset = panOffset
                }
            }
    }

    private func close() {
        onDismiss()
    }
}
