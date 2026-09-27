import Foundation

@main
struct BridgeTests {
    static func main() {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("mood-bridge-test-\(UUID().uuidString)", isDirectory: true)
        try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let bridge = FileBridge(boardDirectory: dir)
        let json = "{\"version\":1,\"months\":{},\"weeks\":{}}"

        assert(bridge.writeGoalsJSON(json), "write of valid JSON should succeed")
        let written = bridge.readGoalsJSON()
        assert(written != nil, "read after write should succeed")
        assert(written!.contains("\"version\":1"), "read should return the written content")

        assert(!bridge.writeGoalsJSON("{not json"), "malformed JSON must be rejected")
        assert(!bridge.writeGoalsJSON("just some text"), "plain text must be rejected")
        assert(bridge.readGoalsJSON()!.contains("\"version\":1"), "file must be unchanged after a rejected write")

        print("FileBridge tests passed")
    }
}
