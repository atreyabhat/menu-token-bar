import Foundation

enum UsageError: Error {
    case noToken
    case http(Int)
    case decode
    case network(String)
}

/// Fetches the current rate-limit snapshot from the same endpoint Claude Code's
/// `/usage` view uses. This is an undocumented OAuth endpoint; it authenticates
/// with the access token Claude Code stores in your login keychain. Reading is
/// read-only and scoped to your own account.
enum UsageClient {
    static let endpoint = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    static let keychainService = "Claude Code-credentials"

    static func fetch() async throws -> Usage {
        guard let token = readToken() else { throw UsageError.noToken }

        var req = URLRequest(url: endpoint)
        req.httpMethod = "GET"
        req.timeoutInterval = 15
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("ccbar", forHTTPHeaderField: "User-Agent")

        let data: Data
        let resp: URLResponse
        do {
            (data, resp) = try await URLSession.shared.data(for: req)
        } catch {
            throw UsageError.network(error.localizedDescription)
        }

        guard let http = resp as? HTTPURLResponse else { throw UsageError.network("no response") }
        guard http.statusCode == 200 else { throw UsageError.http(http.statusCode) }
        return try decode(data)
    }

    static func decode(_ data: Data) throws -> Usage {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rawLimits = obj["limits"] as? [[String: Any]] else {
            throw UsageError.decode
        }

        let rows: [LimitRow] = rawLimits.map { l in
            let kind = l["kind"] as? String ?? "other"
            let scope = l["scope"] as? [String: Any]
            return LimitRow(
                id: kind + "/" + (scopeModel(scope) ?? ""),
                kind: kind,
                group: l["group"] as? String ?? "",
                label: label(kind: kind, scope: scope),
                percent: pct(l["percent"]),
                severity: l["severity"] as? String ?? "normal",
                resetsAt: (l["resets_at"] as? String).flatMap(DateParse.iso),
                isActive: l["is_active"] as? Bool ?? false
            )
        }
        return Usage(limits: rows, fetchedAt: Date())
    }

    // MARK: - Helpers

    private static func label(kind: String, scope: [String: Any]?) -> String {
        switch kind {
        case "session":      return "Session (5hr)"
        case "weekly_all":   return "Weekly (7 day)"
        case "weekly_scoped":
            if let model = scopeModel(scope) { return "Weekly \(model)" }
            return "Weekly (scoped)"
        default:
            return kind.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private static func scopeModel(_ scope: [String: Any]?) -> String? {
        (scope?["model"] as? [String: Any])?["display_name"] as? String
    }

    private static func pct(_ v: Any?) -> Int {
        if let n = v as? NSNumber { return Int(n.doubleValue.rounded()) }
        return 0
    }

    /// Reads the OAuth access token from the login keychain by shelling out to
    /// `security`, then extracting `accessToken` from the stored JSON. Runs off
    /// the main thread by callers; the keychain read itself is fast.
    static func readToken() -> String? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        p.arguments = ["find-generic-password", "-s", keychainService, "-w"]
        let out = Pipe()
        p.standardOutput = out
        p.standardError = Pipe()
        do { try p.run() } catch { return nil }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        guard p.terminationStatus == 0,
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        if let wrapped = obj["claudeAiOauth"] as? [String: Any] {
            return wrapped["accessToken"] as? String
        }
        return obj["accessToken"] as? String
    }
}

/// ISO-8601 parsing tolerant of both millisecond (`.282Z`) and microsecond
/// (`.715900+00:00`) fractional seconds.
enum DateParse {
    private static let withFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let plain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func iso(_ s: String) -> Date? {
        if let d = withFraction.date(from: s) { return d }
        if let d = plain.date(from: s) { return d }
        return plain.date(from: stripFractional(s))
    }

    /// "2026-07-10T04:09:59.715900+00:00" -> "2026-07-10T04:09:59+00:00"
    private static func stripFractional(_ s: String) -> String {
        guard let dot = s.firstIndex(of: ".") else { return s }
        let tail = s[s.index(after: dot)...]
        if let tz = tail.firstIndex(where: { $0 == "+" || $0 == "-" || $0 == "Z" }) {
            return String(s[..<dot]) + String(tail[tz...])
        }
        return String(s[..<dot])
    }
}
