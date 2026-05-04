//
//  ActivityShareSheet.swift
//  Nevernote
//

import SwiftUI
import UIKit

/// Presents `UIActivityViewController` from SwiftUI (popover-safe on iPad when `sourceRect` is set).
struct ActivityShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    @Binding var isPresented: Bool
    var sourceRect: CGRect?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        vc.completionWithItemsHandler = { _, _, _, _ in
            DispatchQueue.main.async {
                isPresented = false
            }
        }
        if let pop = vc.popoverPresentationController {
            let anchorView: UIView? = {
                guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
                return scene.windows.first(where: { $0.isKeyWindow })?.rootViewController?.view
                    ?? scene.windows.first?.rootViewController?.view
            }()
            if let v = anchorView {
                pop.sourceView = v
                pop.sourceRect = sourceRect ?? CGRect(x: v.bounds.midX, y: v.bounds.midY, width: 1, height: 1)
            } else {
                let b = UIScreen.main.bounds
                pop.sourceView = UIView(frame: b)
                pop.sourceRect = sourceRect ?? CGRect(x: b.midX, y: b.midY, width: 1, height: 1)
            }
            pop.permittedArrowDirections = []
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
