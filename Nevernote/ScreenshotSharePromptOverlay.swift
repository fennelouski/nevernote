//
//  ScreenshotSharePromptOverlay.swift
//  Nevernote
//

import SwiftUI

struct ScreenshotSharePromptOverlay: View {
    let step: ScreenshotPromptStep
    var onShareText: () -> Void
    var onChooseImage: () -> Void
    var onPickAspect: (NoteExportAspectRatio) -> Void
    var onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.screenshotOverlayDim
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            VStack(spacing: 0) {
                switch step {
                case .chooseShareKind:
                    Text("Share your note?")
                        .font(.title2.weight(.bold))
                        .neverNoteWrappingLabel()
                        .padding(.top, 22)
                        .padding(.horizontal, 20)

                    Text("You just took a screenshot. Share the note text, or create a clean image of your text only.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .neverNoteWrappingLabel()
                        .padding(.top, 10)
                        .padding(.horizontal, 18)

                    VStack(spacing: 12) {
                        Button(action: onShareText) {
                            Text("Share note text")
                                .font(.headline)
                                .neverNoteWrappingLabel()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.brandBlue)
                        .neverNoteShortcut(.shareScreenshotText)

                        Button(action: onChooseImage) {
                            Text("Share as image of text")
                                .font(.headline)
                                .neverNoteWrappingLabel()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.bordered)
                        .tint(Color.brandBlue)
                        .neverNoteShortcut(.shareScreenshotImage)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 22)

                case .chooseAspect:
                    Text("Aspect ratio")
                        .font(.title2.weight(.bold))
                        .neverNoteWrappingLabel()
                        .padding(.top, 22)

                    Text("The image will contain only your text and background — no buttons or frames.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .neverNoteWrappingLabel()
                        .padding(.horizontal, 18)
                        .padding(.top, 8)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(Array(NoteExportAspectRatio.allCases.enumerated()), id: \.element.id) { index, ratio in
                            Button {
                                onPickAspect(ratio)
                            } label: {
                                Text(ratio.displayLabel)
                                    .font(.subheadline.weight(.semibold))
                                    .neverNoteWrappingLabel()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.bordered)
                            .tint(Color.brandBlue)
                            .neverNoteShortcut(aspectShortcut(for: index))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                }

                Button("Cancel", role: .cancel, action: onCancel)
                    .font(.body.weight(.medium))
                    .neverNoteShortcut(.cancel)
                    .padding(.top, 20)
                    .padding(.bottom, 18)
            }
            .frame(maxWidth: 400)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 24)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    private func aspectShortcut(for index: Int) -> NeverNoteShortcut {
        switch index {
        case 0: return .screenshotAspect1
        case 1: return .screenshotAspect2
        case 2: return .screenshotAspect3
        case 3: return .screenshotAspect4
        default: return .screenshotAspect5
        }
    }
}
