import Foundation
import WebKit

// Serves the board's files over a private `mood://` scheme so WKWebView never
// caches them. Every request reads straight from disk, which makes live reload
// show changes immediately instead of serving a stale cached copy.
final class BoardSchemeHandler: NSObject, WKURLSchemeHandler {
    private let root: URL

    init(root: URL) {
        self.root = root.standardizedFileURL
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url,
              let path = filePath(for: url),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            let error = NSError(domain: "Mood", code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Board resource not found: \(urlSchemeTask.request.url?.absoluteString ?? "")"])
            urlSchemeTask.didFailWithError(error)
            return
        }

        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: [
                "Content-Type": mimeType(for: url),
                "Content-Length": String(data.count),
                "Cache-Control": "no-store, no-cache, must-revalidate"
            ]) ?? URLResponse(url: url, mimeType: mimeType(for: url),
                              expectedContentLength: data.count, textEncodingName: "utf-8")

        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}

    private func filePath(for url: URL) -> String? {
        var relative = url.path
        if relative.hasPrefix("/") { relative = String(relative.dropFirst()) }
        if relative.isEmpty { relative = "index.html" }

        let candidate = root.appendingPathComponent(relative).standardizedFileURL
        let rootPath = root.path
        guard candidate.path == rootPath || candidate.path.hasPrefix(rootPath + "/") else {
            return nil
        }
        return candidate.path
    }

    private func mimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "html": return "text/html"
        case "css": return "text/css"
        case "js": return "text/javascript"
        case "svg": return "image/svg+xml"
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "json": return "application/json"
        default: return "application/octet-stream"
        }
    }
}
