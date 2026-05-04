import Foundation

enum NoteRichTextCodec {
    static func decode(_ data: Data) -> NSAttributedString? {
        guard !data.isEmpty else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: data)
    }

    static func encode(_ value: NSAttributedString) -> Data? {
        try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: false)
    }
}
