import SwiftUI
import Combine

/// Owns the polling loop and the current view state. The network + keychain read
/// run off the main actor; only the decoded snapshot is published back.
@MainActor
final class UsageStore: ObservableObject {
    @Published private(set) var usage: Usage?
    @Published private(set) var lastError: String?
    @Published private(set) var isRefreshing = false

    /// Drives the reset countdown / "updated Xs ago" text without a re-fetch.
    @Published var tick = Date()

    @AppStorage("refreshSeconds") var refreshSeconds: Int = 60

    private var timer: Timer?
    private var tickTimer: Timer?
    private var started = false

    // Exponential backoff so a 429 never turns into a once-a-minute retry storm.
    private var backoff: TimeInterval = 0
    private var nextAllowedFetch = Date.distantPast

    init() { start() }

    func start() {
        guard !started else { return }
        started = true
        Task { await refresh() }
        scheduleTimer()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick = Date() }
        }
    }

    private func scheduleTimer() {
        timer?.invalidate()
        let interval = TimeInterval(max(15, refreshSeconds))
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.refresh() }
        }
    }

    func refresh() async {
        if isRefreshing { return }
        if Date() < nextAllowedFetch { return }   // still in a backoff window
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let snapshot = try await Task.detached(priority: .utility) {
                try await UsageClient.fetch()
            }.value
            usage = snapshot
            lastError = nil
            backoff = 0
            nextAllowedFetch = .distantPast
        } catch UsageError.noToken {
            lastError = "Sign in to Claude Code"
        } catch UsageError.http(401) {
            lastError = "Auth expired, open Claude Code"
        } catch UsageError.http(429) {
            // Back off: 60s, doubling, capped at 5min; resets on first success.
            backoff = backoff == 0 ? 60 : min(backoff * 2, 300)
            nextAllowedFetch = Date().addingTimeInterval(backoff)
            lastError = "Rate limited, retrying soon"
        } catch UsageError.http(let code) {
            lastError = "HTTP \(code)"
        } catch UsageError.decode {
            lastError = "Unexpected response"
        } catch {
            lastError = "Offline"
        }
    }

    /// Fetch on demand (e.g. when the dropdown opens) unless we fetched very
    /// recently, so opening always shows near-live numbers without hammering.
    func refreshIfStale(maxAge: TimeInterval = 15) {
        if let u = usage, Date().timeIntervalSince(u.fetchedAt) < maxAge { return }
        Task { await refresh() }
    }

    // MARK: - Derived display values

    var limits: [LimitRow] { usage?.limits ?? [] }

    /// The limit shown in the menu bar itself: the 5-hour session window across
    /// all models — the everyday "how much of this block have I used" number.
    /// Falls back to the highest limit if the endpoint omits a session bucket.
    var barRow: LimitRow? {
        limits.first { $0.kind == "session" }
    }

    var barPercent: Int? {
        barRow?.percent ?? usage?.maxPercent
    }

    /// The compact string shown in the menu bar itself.
    var barLabel: String {
        guard let p = barPercent else { return "…" }
        return "\(p)%"
    }

    /// Menu-bar tint: nil (blend in) until you approach a limit.
    var barColor: Color? {
        guard let p = barPercent else { return nil }
        if p >= 95 { return .red }
        if p >= 80 { return .orange }
        return nil
    }

    func percentColor(_ row: LimitRow) -> Color? {
        if row.percent >= 95 || row.severity == "critical" { return .red }
        if row.percent >= 80 || row.severity == "warning" { return .orange }
        return nil
    }

    func resetText(_ row: LimitRow) -> String {
        guard let r = row.resetsAt else { return "" }
        return "resets in " + Fmt.duration(r.timeIntervalSince(tick))
    }

}
