//
//  NoteImageURLPrefetcher.swift
//  Nevernote
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum NoteImageURLPrefetcherError: LocalizedError {
    case invalidResponse
    case tooLarge
    case notImageData
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return String(localized: "Could not load that link.")
        case .tooLarge:
            return String(localized: "Image is too large.")
        case .notImageData:
            return String(localized: "That link is not an image.")
        case .network(let e):
            return e.localizedDescription
        }
    }
}

enum NoteImageURLPrefetcher {
    private static let maxBytes = 4 * 1024 * 1024
    private static let cache = NSCache<NSURL, PlatformImage>()

    static func cachedImage(for url: URL) -> PlatformImage? {
        cache.object(forKey: url as NSURL)
    }

    static func storeInCache(_ image: PlatformImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }

    static func prefetchImage(from url: URL, completion: @escaping (Result<PlatformImage, NoteImageURLPrefetcherError>) -> Void) {
        if let img = cachedImage(for: url) {
            DispatchQueue.main.async { completion(.success(img)) }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                DispatchQueue.main.async { completion(.failure(.network(error))) }
                return
            }
            guard let http = response as? HTTPURLResponse else {
                DispatchQueue.main.async { completion(.failure(.invalidResponse)) }
                return
            }
            guard (200 ... 299).contains(http.statusCode) else {
                DispatchQueue.main.async { completion(.failure(.invalidResponse)) }
                return
            }
            let expectedLen = http.expectedContentLength
            if expectedLen > 0, expectedLen > Int64(maxBytes) {
                DispatchQueue.main.async { completion(.failure(.tooLarge)) }
                return
            }
            guard let data, !data.isEmpty else {
                DispatchQueue.main.async { completion(.failure(.notImageData)) }
                return
            }
            guard data.count <= maxBytes else {
                DispatchQueue.main.async { completion(.failure(.tooLarge)) }
                return
            }
            guard let image = NeverNotePlatform.platformImage(from: data) else {
                DispatchQueue.main.async { completion(.failure(.notImageData)) }
                return
            }
            cache.setObject(image, forKey: url as NSURL)
            DispatchQueue.main.async { completion(.success(image)) }
        }
        task.resume()
    }
}

enum NoteHTTPSLinkEnumeration {
    /// First-appearance document order of unique http(s) link keys passing `include`.
    static func orderedLinkKeys(in attributed: NSAttributedString, include: (String) -> Bool) -> [String] {
        var firstLocation: [String: Int] = [:]
        let full = NSRange(location: 0, length: attributed.length)
        guard full.length > 0 else { return [] }

        attributed.enumerateAttribute(.link, in: full) { value, range, _ in
            let urlString: String?
            if let url = value as? URL {
                urlString = url.absoluteString
            } else if let str = value as? String {
                urlString = str
            } else {
                urlString = nil
            }
            guard let urlString,
                  let url = URL(string: urlString) else { return }
            let key = NoteDocument.normalizedURLKey(url)
            guard include(key) else { return }
            if firstLocation[key] == nil {
                firstLocation[key] = range.location
            }
        }

        return firstLocation.sorted { $0.value < $1.value }.map(\.key)
    }
}
