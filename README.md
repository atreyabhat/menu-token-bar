# Claude Usage Bar

A tiny macOS menu bar app that shows your Claude Code usage as `</> NN%`.

<img width="280" height="230" alt="image" src="https://github.com/user-attachments/assets/29ed09b0-7d4f-41b4-8807-7a14ad91022f" />


## Install

> [!TIP]
> **Paste the prompt below into Claude Code.** It builds the app, drops it in your
> menu bar, and starts it at login. Nothing else to set up.

```text
Install the menu bar app from https://github.com/atreyabhat/claude-usage-bar: clone it and run scripts/install.sh, which builds it from source, puts it in my menu bar, and starts it at login. It reads my existing Claude Code login. Then confirm it is running.
```

Requires macOS 13+ and the Xcode Command Line Tools (`xcode-select --install`).
To remove it later, run `scripts/uninstall.sh`.

It runs locally and read only, calling the same usage endpoint Claude Code's
`/usage` view uses (undocumented, so it could change).













## Features For Nerds

- **Exact reset times.** Claude Code's `/usage` shows the reset only in whole hours (2h 45m reads as "2 hours"); this counts down to the exact minute.
- **Fresh on demand.** Polls every 60 seconds, and refetches the moment you open the dropdown, so a manual check is always current.
- **Real numbers.** Reads the same endpoint `/usage` uses, so the percentages are authoritative, not estimated from local logs.
- **Featherweight.** About 0% CPU when idle, ~15 MB memory, one small request a minute.

