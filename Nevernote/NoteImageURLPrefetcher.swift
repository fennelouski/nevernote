//
//  NoteImageURLPrefetcher.swift
//  Nevernote
//

import UIKit

enum NoteImageURLPrefetcherError: LocalizedError {
    case invalidResponse
    case tooLarge
    case notImageData
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Could not load that link."
        case .tooLarge:
            return "Image is too large."
        case .notImageData:
            return "That link is not an image."
        case .network(let e):
            return e.localizedDescription
        }
    }
}

enum NoteImageURLPrefetcher {
    private static let maxBytes = 4 * 1024 * 1024
    private static let cache = NSCache<NSURL, UIImage>()

    static func cachedImage(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    static func storeInCache(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }

    static func prefetchImage(from url: URL, completion: @escaping (Result<UIImage, NoteImageURLPrefetcherError>) -> Void) {
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
            guard let image = UIImage(data: data) else {
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

        attributed.enumerateAttribute(.link, in: full, options: []) { value, range, _ in
            guard let url = value as? URL ?? (value as? String).flatMap({ URL(string: $0) }) else { return }
            guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return }
            let key = NoteDocument.normalizedURLKey(url)
            guard include(key) else { return }
            let loc = range.location
            if let existing = firstLocation[key] {
                if loc < existing { firstLocation[key] = loc }
            } else {
                firstLocation[key] = loc
            }
        }

        return firstLocation.keys.sorted { (firstLocation[$0] ?? 0) < (firstLocation[$1] ?? 0) }
    }
}

enum NoteHTTPPasteboardLinkFormatting {
    static func applyHTTPDetectedLinks(in mutable: NSMutableAttributedString, range: NSRange) {
        guard range.length > 0, NSMaxRange(range) <= mutable.length else { return }
        let substring = (mutable.string as NSString).substring(with: range)
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return }
        let len = (substring as NSString).length
        guard len > 0 else { return }

        var rangesToApply: [(NSRange, URL)] = []
        detector.enumerateMatches(in: substring, options: [], range: NSRange(location: 0, length: len)) { match, _, _ in
            guard let match, let url = match.url else { return }
            guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return }
            rangesToApply.append((match.range, url))
        }
        for (localRange, url) in rangesToApply.reversed() {
            let global = NSRange(location: range.location + localRange.location, length: localRange.length)
            guard NSMaxRange(global) <= mutable.length else { continue }
            mutable.addAttribute(.link, value: url, range: global)
        }
    }
}
