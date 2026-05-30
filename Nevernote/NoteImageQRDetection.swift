import Vision
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum NoteImageQRDetection {
    static func detectQRPayloads(in image: PlatformImage) async -> [String] {
        #if canImport(UIKit)
        guard let cgImage = image.cgImage else { return [] }
        #else
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return [] }
        #endif

        return await withCheckedContinuation { continuation in
            let request = VNDetectBarcodesRequest { request, error in
                if error != nil {
                    continuation.resume(returning: [])
                    return
                }
                let observations = request.results as? [VNBarcodeObservation] ?? []
                var seen = Set<String>()
                var ordered: [String] = []
                for observation in observations {
                    guard let payload = observation.payloadStringValue?
                        .trimmingCharacters(in: .whitespacesAndNewlines),
                        !payload.isEmpty,
                        !seen.contains(payload)
                    else { continue }
                    seen.insert(payload)
                    ordered.append(payload)
                }
                continuation.resume(returning: ordered)
            }
            request.symbologies = [.qr]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }
}

enum NoteImportedImageText {
    static func compose(ocr: String, qrPayloads: [String]) -> String {
        let ocrText = ocr.trimmingCharacters(in: .whitespacesAndNewlines)
        let qrBlock = qrPayloads.joined(separator: "\n")
        switch (ocrText.isEmpty, qrBlock.isEmpty) {
        case (false, false):
            return ocrText + "\n\n" + qrBlock
        case (false, true):
            return ocrText
        case (true, false):
            return qrBlock
        case (true, true):
            return ""
        }
    }
}
