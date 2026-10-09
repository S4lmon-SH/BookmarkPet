import Foundation
import Testing
@testable import BookmarkPetCore

struct MemoSessionTests {
    private func freshStore() throws -> MemoFileStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        return MemoFileStore(fileURL: directory.appendingPathComponent("memo.txt"))
    }

    @Test func whitespaceControlsBadgeWithoutChangingText() throws {
        let store = try freshStore()
        let session = try MemoSession(store: store)
        let whitespace = " \t\n  \r\n"
        try session.replace(with: whitespace)
        #expect(session.text == whitespace)
        #expect(!session.hasMemo)
        #expect(try store.load() == whitespace)

        let formatted = "  다음 할 일\n\n"
        try session.replace(with: formatted)
        #expect(session.hasMemo)
        #expect(session.text == formatted)
    }

    @Test func persistsKoreanMultilineAndPasteSizedText() throws {
        let store = try freshStore()
        let original = "  한글 입력 확인 🇰🇷\n" + String(repeating: "긴 메모와 붙여넣기\n", count: 150) + "  "
        let firstRun = try MemoSession(store: store)
        try firstRun.replace(with: original)
        let secondRun = try MemoSession(store: store)
        #expect(secondRun.text == original)
        #expect(secondRun.hasMemo)
    }

    @Test func clearUndoAndRestartStayInSync() throws {
        let store = try freshStore()
        let session = try MemoSession(store: store)
        try session.replace(with: "다음에 이어서")
        try session.clear()
        #expect(session.text == "")
        #expect(!session.hasMemo)
        #expect(session.undoText == "다음에 이어서")
        #expect(try MemoSession(store: store).text == "")

        try session.undoClear()
        #expect(session.hasMemo)
        #expect(session.undoText == nil)
        #expect(try MemoSession(store: store).text == "다음에 이어서")
    }

    @Test func editingAfterClearDiscardsUndo() throws {
        let session = try MemoSession(store: freshStore())
        try session.replace(with: "이전")
        try session.clear()
        try session.replace(with: "새 메모")
        try session.undoClear()
        #expect(session.text == "새 메모")
    }

    @Test func detectsWebLinksWithExactUTF16Ranges() throws {
        let text = "  다음 🇰🇷\n(https://example.com/task?q=1#next),\nwww.example.org/start  "
        let links = try MemoLinkDetector().links(in: text)
        #expect(links.count == 2)
        guard links.count == 2 else { return }
        #expect((text as NSString).substring(with: links[0].range) == "https://example.com/task?q=1#next")
        #expect(links[0].url.absoluteString == "https://example.com/task?q=1#next")
        #expect((text as NSString).substring(with: links[1].range) == "www.example.org/start")
        #expect(links[1].url.host == "www.example.org")
    }

    @Test func detectsOnlyCurrentWebLinks() throws {
        let detector = try MemoLinkDetector()
        #expect(detector.links(in: "test@example.com ftp://example.com file:///tmp/memo.txt").isEmpty)
        #expect(detector.links(in: "https://example.com").count == 1)
        #expect(detector.links(in: "주소 삭제 후 일반 메모").isEmpty)
        #expect(!MemoLinkDetector.isWebURL(URL(string: "javascript:alert(1)")!))
        #expect(!MemoLinkDetector.isWebURL(URL(string: "https:relative")!))
    }
}
