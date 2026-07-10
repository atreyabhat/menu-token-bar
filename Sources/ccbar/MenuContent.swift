import SwiftUI

/// The dropdown: each rate limit as a plain text row — label, percentage, and
/// reset countdown. Deliberately no progress bars.
struct MenuContent: View {
    @ObservedObject var store: UsageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("Claude Code Usage")
                    .font(.caption).bold()
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "power")
                }
                .buttonStyle(.borderless)
                .help("Quit ccbar")
            }

            if store.limits.isEmpty {
                Text(store.lastError ?? "Loading…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(store.limits) { row in
                        limitRow(row)
                    }
                }
            }

            if !store.updatedAgo.isEmpty {
                Text(store.updatedAgo)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .frame(width: 260)
        .onAppear { store.refreshIfStale() }
    }

    private func limitRow(_ row: LimitRow) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.label)
                    .font(.body)
                    .fontWeight(row.isActive ? .semibold : .regular)
                Spacer()
                Text("\(row.percent)%")
                    .font(.body)
                    .monospacedDigit()
                    .foregroundStyle(store.percentColor(row) ?? .primary)
            }
            Text(store.resetText(row))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

}
