import Foundation

// The single, narrowly scoped bridge between the web page and the filesystem.
// It can only read and write `goals.json` inside the board directory. Nothing
// else is ever touched, so the web content cannot reach arbitrary local files.
final class FileBridge {
    let boardDirectory: URL
    let goalsURL: URL

    init(boardDirectory: URL) {
        self.boardDirectory = boardDirectory
        let dataDirectory = boardDirectory.appendingPathComponent("data", isDirectory: true)
        self.goalsURL = dataDirectory.appendingPathComponent("goals.json")
    }

    func readGoalsJSON() -> String? {
        try? String(contentsOf: goalsURL, encoding: .utf8)
    }

    @discardableResult
    func writeGoalsJSON(_ json: String) -> Bool {
        // Refuse to write anything that is not a single valid JSON document so
        // the file on disk can never end up corrupt.
        guard let data = json.data(using: .utf8),
              (try? JSONSerialization.jsonObject(with: data, options: [])) != nil else {
            NSLog("Mood: refusing to write invalid goals JSON")
            return false
        }
        do {
            try FileManager.default.createDirectory(
                at: goalsURL.deletingLastPathComponent(),
                withIntermediateDirectories: true)
            try data.write(to: goalsURL, options: .atomic)
            return true
        } catch {
            NSLog("Mood: failed to write goals.json: \(error)")
            return false
        }
    }
}
