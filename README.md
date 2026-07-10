# menu-token-bar

A quiet macOS menu-bar readout of your **Claude Code** usage. It shows a single
unobtrusive `</> NN%` next to your clock — the percentage of your 5-hour session
limit you've used — and, on click, the full breakdown: each limit's percentage
and when it resets. No progress bars, no clutter.

```
Claude Code Usage                    ⏻
Session (5hr)      41%   resets in 4h 11m
Weekly (7 day)     28%   resets in 6h 59m
Weekly Fable       42%   resets in 6h 59m
```

## Install

You already use Claude Code — so the installer is just a prompt. **Paste this
into Claude Code:**

> Install the menu bar app from https://github.com/atreyabhat/menu-token-bar —
> clone it and run `scripts/install.sh`, which builds it with Swift, installs it
> to `~/Library/Application Support` (not Applications), registers a login agent,
> and launches it. It reads my existing Claude Code login for usage data. Then
> confirm it's showing in my menu bar.

Or run the one-liner yourself:

```sh
curl -fsSL https://raw.githubusercontent.com/atreyabhat/menu-token-bar/main/scripts/install.sh | bash
```

Either way it builds from source and puts `</> NN%` in your menu bar, set to
start at login. Because it's **built locally**, macOS doesn't quarantine it —
there's no Gatekeeper warning, no code signing, and **no Apple Developer account
needed**.

### Requirements

- macOS 13 or later
- Xcode **Command Line Tools** (`xcode-select --install`) — used to build it
- Signed in to Claude Code (it reads your existing login; nothing to configure)

### Uninstall

```sh
curl -fsSL https://raw.githubusercontent.com/atreyabhat/menu-token-bar/main/scripts/uninstall.sh | bash
```

…or just tell Claude Code to "uninstall menu-token-bar". This stops it, removes
the login agent, and deletes the app.

## How it works

On each refresh (every 60s) it reads your Claude Code OAuth token from the login
keychain (via Apple's `security` tool, so there's no keychain prompt) and calls
the same usage endpoint Claude Code's own `/usage` view uses, then renders the
limits it returns. The menu bar tracks your Session (5-hour) percentage and tints
amber past 80%, red past 95%.

It is entirely local and read-only: your token never leaves your machine except
in the request to Anthropic's API, exactly as Claude Code itself does. No server,
no telemetry, nothing written back.

### Caveat: unofficial endpoint

The usage endpoint is undocumented and not a supported API. It works today but
Anthropic could change or remove it, which would break this until updated. If the
numbers ever look off, trust `/usage` inside Claude Code. If you're signed out (or
the token has expired and Claude Code hasn't refreshed it), the app shows a short
hint until the next successful poll.

## Build / develop

Requires the Swift toolchain (Xcode or Command Line Tools), macOS 13+.

```sh
make run                          # build + launch (does not install)
make install                      # build + install as a login agent
make uninstall                    # remove it
make icon                         # regenerate the app icon
./.build/release/ccbar --dump     # print current limits to the terminal
```

## License

MIT
