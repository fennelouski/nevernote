//
//  NoteBottomURLImageRow.swift
//  NeverNote
//
//  Created by Nathan Fennel on 5/17/26.
//  Copyright © 2026 Nathan Fennel. All rights reserved.
//

import SwiftUI

struct NoteBottomURLImageRow: View {
    let url: URL
    @State private var image: PlatformImage?

    var body: some View {
        Group {
            if let image {
                platformImageView(image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity)
        .task(id: url) {
            if let cached = NoteImageURLPrefetcher.cachedImage(for: url) {
                image = cached
                return
            }
            NoteImageURLPrefetcher.prefetchImage(from: url) { result in
                if case .success(let img) = result {
                    image = img
                }
            }
        }
    }

    @ViewBuilder
    private func platformImageView(_ image: PlatformImage) -> Image {
        #if canImport(UIKit)
        Image(uiImage: image)
        #else
        Image(nsImage: image)
        #endif
    }
}
