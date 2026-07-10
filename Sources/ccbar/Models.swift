import Foundation

/// One rate-limit bucket as reported by Claude Code's usage endpoint — e.g.
/// "Session (5hr)", "Weekly (7 day)", or a model-scoped weekly limit.
struct LimitRow: Identifiable, Sendable {
    let id: String          // stable across refreshes for SwiftUI ForEach
    let kind: String        // session | weekly_all | weekly_scoped | ...
    let group: String       // session | weekly
    let label: String       // display label, e.g. "Weekly Fable"
    let percent: Int
    let severity: String    // normal | warning | ...
    let resetsAt: Date?
    let isActive: Bool      // the currently binding constraint
}

/// A full snapshot from the usage endpoint.
struct Usage: Sendable {
    let limits: [LimitRow]
    let fetchedAt: Date

    var maxPercent: Int { limits.map(\.percent).max() ?? 0 }
}
