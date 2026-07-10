#!/usr/bin/env bash
# Remove menu-token-bar: stop it, drop the login agent, delete the installed app.
set -euo pipefail

APP="ccbar"
LABEL="dev.atreya.ccbar"
INSTALL_DIR="$HOME/Library/Application Support/menu-token-bar"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

GUI="gui/$(id -u)"
launchctl bootout "$GUI/$LABEL" 2>/dev/null || true
launchctl unload "$PLIST" 2>/dev/null || true
rm -f "$PLIST"
rm -rf "$INSTALL_DIR"
pkill -x "$APP" 2>/dev/null || true

echo "✓ menu-token-bar uninstalled."
