import Foundation

enum Fmt {
    /// 942 -> "942", 12_300 -> "12.3K", 1_240_000 -> "1.24M"
    static func compact(_ n: Int) -> String {
        let v = Double(n)
        switch abs(v) {
        case 1_000_000...:
            return trimmed(v / 1_000_000) + "M"
        case 1_000...:
            return trimmed(v / 1_000) + "K"
        default:
            return "\(n)"
        }
    }

    private static func trimmed(_ v: Double) -> String {
        let s = String(format: "%.2f", v)
        // drop trailing zeros / dot: 1.20 -> 1.2, 3.00 -> 3
        var out = s
        while out.contains(".") && (out.hasSuffix("0") || out.hasSuffix(".")) {
            out.removeLast()
        }
        return out
    }

    static func usd(_ v: Double) -> String {
        if v >= 100 { return String(format: "$%.0f", v) }
        return String(format: "$%.2f", v)
    }

    /// Seconds remaining -> "2d 3h" / "2h 14m" / "43m" / "0m"
    static func duration(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds))
        let d = s / 86400
        let h = (s % 86400) / 3600
        let m = (s % 3600) / 60
        if d > 0 { return "\(d)d \(h)h" }
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    /// "just now" / "12s ago" / "3m ago"
    static func ago(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds))
        if s < 5 { return "just now" }
        if s < 60 { return "\(s)s ago" }
        return "\(s / 60)m ago"
    }

    static func clock(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
}
