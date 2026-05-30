//
//  NoteBottomURLImagePreviews.swift
//  NeverNote
//
//  Created by Nathan Fennel on 5/17/26.
//  Copyright © 2026 Nathan Fennel. All rights reserved.
//

import SwiftUI

struct NoteBottomURLImagePreviews: View {
    let urlKeys: [String]

    var body: some View {
        VStack(spacing: 14) {
            ForEach(urlKeys, id: \.self) { key in
                if let url = URL(string: key) {
                    NoteBottomURLImageRow(url: url)
                }
            }
        }
    }
}
