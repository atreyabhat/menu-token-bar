import Foundation

@main
enum Entry {
    static func main() {
        if CommandLine.arguments.contains("--dump") {
            Dump.run()
            return
        }
        CcbarApp.main()
    }
}

/// Headless readout of the current limits — the same numbers the menu bar uses.
/// Handy for verifying the endpoint and comparing against Claude Code's `/usage`.
enum Dump {
    static func run() {
        let sem = DispatchSemaphore(value: 0)
        Task {
            defer { sem.signal() }
            do {
                let u = try await UsageClient.fetch()
                print("ccbar usage @ \(u.fetchedAt)")
                for l in u.limits {
                    let label = l.label.padding(toLength: 16, withPad: " ", startingAt: 0)
                    let pct = String(format: "%3d%%", l.percent)
                    let reset = l.resetsAt.map { "resets in " + Fmt.duration($0.timeIntervalSinceNow) } ?? "—"
                    let active = l.isActive ? "   ← active" : ""
                    print("  \(label) \(pct)   \(reset)\(active)")
                }
            } catch {
                print("error: \(error)")
            }
        }
        sem.wait()
    }
}
