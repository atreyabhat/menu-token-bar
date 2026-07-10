# Claude Usage Bar

A tiny macOS menu bar app that shows your Claude Code usage as `</> NN%`. Click it
for the full breakdown (session, weekly, per model) with reset times.

## Install

Paste this into Claude Code:

> Install the menu bar app from https://github.com/atreyabhat/menu-token-bar: clone
> it and run `scripts/install.sh`. It builds from source, puts it in my menu bar,
> and starts it at login. Then confirm it is running.

That is it. It reads your existing Claude Code login, so there is nothing to set up.
Needs macOS 13+ and the Xcode Command Line Tools (`xcode-select --install`).

To remove it, tell Claude Code to run `scripts/uninstall.sh`.

It runs locally and read only, calling the same usage endpoint Claude Code's
`/usage` view uses (undocumented, so it could change).
