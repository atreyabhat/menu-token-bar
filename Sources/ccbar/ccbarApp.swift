import SwiftUI

struct CcbarApp: App {
    @StateObject private var store = UsageStore()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(store: store)
        } label: {
            // Quiet by default: "</> NN%" as a single label (a multi-view menu
            // bar label renders unreliably), tinting only as you near the limit.
            Text("</> \(store.barLabel)")
                .monospacedDigit()
                .foregroundStyle(store.barColor ?? .primary)
        }
        .menuBarExtraStyle(.window)
    }
}
