import BookmarkPetCore
import Foundation

@main
struct ManualRunner {
    static func main() throws {
        var passed = 0
        try check("whitespace badge and exact text") {
            let store = makeStore()
            let session = try MemoSession(store: store)
            let spaces = " \t\n\r\n  "
            try session.replace(with: spaces)
            try expect(!session.hasMemo && session.text == spaces && store.load() == spaces)
            try session.replace(with: "  다음 할 일\n\n")
            try expect(session.hasMemo && session.text == "  다음 할 일\n\n")
        }
        passed += 1

        try check("Korean multiline paste and restart") {
            let store = makeStore()
            let text = "한글 입력 🇰🇷\n" + String(repeating: "긴 메모 붙여넣기\n", count: 150)
            try MemoSession(store: store).replace(with: text)
            let restarted = try MemoSession(store: store)
            try expect(restarted.text == text && restarted.hasMemo)
        }
        passed += 1

        try check("clear undo persisted state") {
            let store = makeStore()
            let session = try MemoSession(store: store)
            try session.replace(with: "  다시 시작\n")
            try session.clear()
            try expect(session.text.isEmpty && !session.hasMemo && (try store.load()).isEmpty)
            try session.undoClear()
            try expect(session.text == "  다시 시작\n" && session.hasMemo)
            try expect(try MemoSession(store: store).text == session.text)
        }
        passed += 1

        try check("new edit invalidates undo") {
            let session = try MemoSession(store: makeStore())
            try session.replace(with: "이전")
            try session.clear()
            try session.replace(with: "새 메모")
            try session.undoClear()
            try expect(session.text == "새 메모" && session.undoText == nil)
        }
        passed += 1

        try check("web links preserve Korean UTF-16 ranges and punctuation") {
            let text = "  다음 🇰🇷\n(https://example.com/task?q=1#next),\nwww.example.org/start  "
            let links = try MemoLinkDetector().links(in: text)
            try expect(links.count == 2)
            try expect((text as NSString).substring(with: links[0].range) == "https://example.com/task?q=1#next")
            try expect(links[0].url.absoluteString == "https://example.com/task?q=1#next")
            try expect((text as NSString).substring(with: links[1].range) == "www.example.org/start")
            try expect(links[1].url.host == "www.example.org")
        }
        passed += 1

        try check("web links exclude other schemes and update after editing") {
            let detector = try MemoLinkDetector()
            try expect(detector.links(in: "test@example.com ftp://example.com file:///tmp/memo.txt").isEmpty)
            try expect(detector.links(in: "https://example.com").count == 1)
            try expect(detector.links(in: "주소 삭제 후 일반 메모").isEmpty)
            try expect(!MemoLinkDetector.isWebURL(URL(string: "javascript:alert(1)")!))
            try expect(!MemoLinkDetector.isWebURL(URL(string: "https:relative")!))
        }
        passed += 1

        print("\(passed) core tests passed")
    }

    static func makeStore() -> MemoFileStore {
        MemoFileStore(fileURL: FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("memo.txt"))
    }

    static func expect(_ condition: @autoclosure () throws -> Bool) throws {
        if try !condition() { throw TestFailure.failed }
    }

    static func check(_ name: String, _ body: () throws -> Void) throws {
        try body()
        print("PASS: \(name)")
    }

    enum TestFailure: Error { case failed }
}
