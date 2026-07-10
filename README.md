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

Requires macOS 13+ and the Xcode Command Line Tools (`xcode-select --install`) and ofcourse Claude Code (duh!).
To remove it later, run `scripts/uninstall.sh`.


## Features

- **Exact reset times.** Claude Code's `/usage` shows the reset only in whole hours (2h 45m reads as "2 hours"); this counts down to the exact minute.
- Polls every **60.** seconds
- Calls the same endpoint Claude Code's`/usage` view uses (undocumented, so it could change).
- **Reads the same endpoint `/usage` uses.**  so the percentages are authoritative, not estimated from local logs.

