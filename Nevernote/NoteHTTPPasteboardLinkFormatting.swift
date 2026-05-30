import Foundation

enum NoteHTTPPasteboardLinkFormatting {
    static func applyHTTPDetectedLinks(in mutable: NSMutableAttributedString, range: NSRange) {
        guard range.length > 0, NSMaxRange(range) <= mutable.length else { return }
        let substring = mutable.attributedSubstring(from: range).string
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return }
        let localRange = NSRange(location: 0, length: (substring as NSString).length)
        detector.enumerateMatches(in: substring, options: [], range: localRange) { match, _, _ in
            guard let match, let url = match.url else { return }
            let absoluteRange = NSRange(location: range.location + match.range.location, length: match.range.length)
            mutable.addAttribute(.link, value: url, range: absoluteRange)
        }
    }
}
