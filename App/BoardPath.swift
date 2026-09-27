import Foundation

// The app loads the board from this directory by default. Override at runtime
// by launching with the MOOD_BOARD_DIR environment variable set to an absolute
// path (or a path beginning with ~).
let defaultBoardDirectory = "~/personal/mood/Board"

func resolveBoardDirectory() -> URL {
    if let env = ProcessInfo.processInfo.environment["MOOD_BOARD_DIR"], !env.isEmpty {
        return URL(fileURLWithPath: (env as NSString).expandingTildeInPath)
    }
    return URL(fileURLWithPath: (defaultBoardDirectory as NSString).expandingTildeInPath)
}
