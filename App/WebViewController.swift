import AppKit
import WebKit
import Foundation

final class WebViewController: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    let webView: WKWebView

    private let bridge: FileBridge
    private let boardDirectory: URL
    private var watcher: FileWatcher?
    private var reloadWorkItem: DispatchWorkItem?
    private var ignoreGoalsUntil = Date.distantPast

    init(boardDirectory: URL) {
        self.boardDirectory = boardDirectory
        self.bridge = FileBridge(boardDirectory: boardDirectory)

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        let controller = WKUserContentController()
        configuration.userContentController = controller
        configuration.setURLSchemeHandler(BoardSchemeHandler(root: boardDirectory), forURLScheme: "mood")
        let webView = WKWebView(frame: .zero, configuration: configuration)
        self.webView = webView

        super.init()

        controller.add(self, name: "bridge")
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = false
        webView.allowsMagnification = false
        if #available(macOS 13.3, *) {
            webView.isInspectable = true
        }

        reloadBoard()
        startWatching()
    }

    func reloadBoard() {
        let json = bridge.readGoalsJSON() ?? "null"
        let safeJSON = json.replacingOccurrences(of: "</", with: "<\\/")
        let script = "window.__MOOD_INITIAL_DATA__ = \(safeJSON);"
        let controller = webView.configuration.userContentController
        controller.removeAllUserScripts()
        controller.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        webView.load(URLRequest(url: URL(string: "mood:///index.html")!))
    }

    private func startWatching() {
        watcher = FileWatcher(path: boardDirectory.path) { [weak self] paths in
            self?.handleFileChanges(paths)
        }
    }

    private func handleFileChanges(_ paths: [String]) {
        let presentationChanged = paths.contains { Self.isPresentationFile($0) }
        let goalsChanged = paths.contains { ($0 as NSString).lastPathComponent == "goals.json" }

        guard presentationChanged || goalsChanged else { return }
        if goalsChanged && !presentationChanged && Date() < ignoreGoalsUntil { return }

        reloadWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.requestReloadFromPage()
        }
        reloadWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    private static func isPresentationFile(_ path: String) -> Bool {
        let ext = (path as NSString).pathExtension.lowercased()
        return ["html", "css", "js"].contains(ext)
    }

    private func requestReloadFromPage() {
        webView.evaluateJavaScript("window.__moodRequestReload && window.__moodRequestReload()", completionHandler: nil)
    }

    private func isTrustedLocalURL(_ url: URL?) -> Bool {
        guard let url = url else { return false }
        return url.scheme == "mood"
    }

    // MARK: WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "bridge",
              let body = message.body as? [String: Any],
              let action = body["action"] as? String else { return }

        switch action {
        case "write":
            if let payload = body["payload"] as? String {
                ignoreGoalsUntil = Date().addingTimeInterval(1.5)
                bridge.writeGoalsJSON(payload)
            }
        case "reload":
            DispatchQueue.main.async { [weak self] in
                self?.reloadBoard()
            }
        default:
            break
        }
    }

    // MARK: WKNavigationDelegate

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(isTrustedLocalURL(navigationAction.request.url) ? .allow : .cancel)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(isTrustedLocalURL(navigationResponse.response.url) ? .allow : .cancel)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        NSLog("Mood: navigation failed: \(error)")
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        reloadBoard()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        writeSnapshotIfRequested()
        writeHTMLDumpIfRequested()
        writeEvalIfRequested()
    }

    // MARK: WKUIDelegate

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        return nil
    }

    // MARK: Debug dumps (optional, off by default)

    private func writeHTMLDumpIfRequested() {
        guard let path = ProcessInfo.processInfo.environment["MOOD_DUMP_PATH"], !path.isEmpty else { return }
        let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        webView.evaluateJavaScript("document.documentElement.outerHTML") { result, _ in
            guard let html = result as? String else { return }
            try? html.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func writeEvalIfRequested() {
        guard let expr = ProcessInfo.processInfo.environment["MOOD_EVAL"], !expr.isEmpty,
              let path = ProcessInfo.processInfo.environment["MOOD_EVAL_PATH"], !path.isEmpty else { return }
        let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        webView.evaluateJavaScript(expr) { result, error in
            let text: String
            if let result = result { text = String(describing: result) }
            else { text = "ERROR: \(error?.localizedDescription ?? "unknown")" }
            try? text.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func writeSnapshotIfRequested() {
        guard let dir = ProcessInfo.processInfo.environment["MOOD_SNAPSHOT_DIR"], !dir.isEmpty else { return }
        let directory = URL(fileURLWithPath: (dir as NSString).expandingTildeInPath)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let webView = self?.webView else { return }
            webView.takeSnapshot(with: nil) { image, _ in
                guard let image = image,
                      let tiff = image.tiffRepresentation,
                      let rep = NSBitmapImageRep(data: tiff),
                      let png = rep.representation(using: .png, properties: [:]) else { return }
                try? png.write(to: directory.appendingPathComponent("board.png"))
            }
        }
    }
}
