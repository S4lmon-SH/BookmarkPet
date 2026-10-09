import Foundation

public protocol MemoStore {
    func load() throws -> String
    func save(_ text: String) throws
}

/// A web link's range uses UTF-16 offsets, as required by AppKit text storage.
public struct MemoLink: Equatable, Sendable {
    public let range: NSRange
    public let url: URL
}

public struct MemoLinkDetector {
    private let detector: NSDataDetector

    public init() throws {
        detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    }

    public func links(in text: String) -> [MemoLink] {
        detector.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap { match in
            guard let url = match.url, Self.isWebURL(url) else { return nil }
            return MemoLink(range: match.range, url: url)
        }
    }

    public static func isWebURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
              let host = url.host, !host.isEmpty else { return false }
        return true
    }
}

/// One UTF-8 file, atomically replaced on every edit. No text normalization occurs.
public struct MemoFileStore: MemoStore {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public static func defaultStore() throws -> MemoFileStore {
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return MemoFileStore(fileURL: support
            .appendingPathComponent("BookmarkPet", isDirectory: true)
            .appendingPathComponent("memo.txt"))
    }

    public func load() throws -> String {
        do {
            return try String(contentsOf: fileURL, encoding: .utf8)
        } catch let error as NSError where error.domain == NSCocoaErrorDomain
            && error.code == NSFileReadNoSuchFileError {
            return ""
        }
    }

    public func save(_ text: String) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(text.utf8).write(to: fileURL, options: .atomic)
    }
}

public final class MemoSession {
    private let store: any MemoStore
    public private(set) var text: String
    public private(set) var undoText: String?

    public var hasMemo: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public init(store: any MemoStore) throws {
        self.store = store
        self.text = try store.load()
    }

    public func replace(with newText: String) throws {
        guard newText != text else { return }
        try store.save(newText)
        text = newText
        undoText = nil
    }

    public func clear() throws {
        guard !text.isEmpty else { return }
        let previous = text
        try store.save("")
        text = ""
        undoText = previous
    }

    public func undoClear() throws {
        guard let previous = undoText else { return }
        try store.save(previous)
        text = previous
        undoText = nil
    }
}
