#!/usr/bin/env bash
# Build menu-token-bar from source and install it as a login-launched menu bar
# app. Safe to run from a clone (uses it) or standalone via curl (clones first).
# Because the app is built locally, macOS does not quarantine it — no Gatekeeper
# prompt, no signing, no Apple Developer account needed.
set -euo pipefail

REPO_URL="https://github.com/atreyabhat/menu-token-bar.git"
APP="ccbar"
BUNDLE="ccbar.app"
LABEL="dev.atreya.ccbar"
INSTALL_DIR="$HOME/Library/Application Support/menu-token-bar"
AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST="$AGENTS_DIR/$LABEL.plist"

echo "==> Checking toolchain"
if ! /usr/bin/xcrun --find swift >/dev/null 2>&1 && ! command -v swift >/dev/null 2>&1; then
  echo "Swift toolchain not found. Install the Command Line Tools first:" >&2
  echo "    xcode-select --install" >&2
  exit 1
fi

# Use the current checkout if we're inside it; otherwise clone to a cache dir.
if [ -f "Package.swift" ] && grep -q 'name: "ccbar"' Package.swift 2>/dev/null; then
  SRC="$(pwd)"
  echo "==> Building from current checkout: $SRC"
else
  SRC="$HOME/.cache/menu-token-bar"
  echo "==> Cloning $REPO_URL"
  rm -rf "$SRC"
  git clone --depth 1 "$REPO_URL" "$SRC"
fi
cd "$SRC"

echo "==> Building"
make bundle

echo "==> Installing to $INSTALL_DIR (not /Applications)"
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/$BUNDLE"
cp -R "$BUNDLE" "$INSTALL_DIR/$BUNDLE"

echo "==> Registering login agent"
mkdir -p "$AGENTS_DIR"
cat > "$PLIST" <<PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>$LABEL</string>
    <key>ProgramArguments</key>
    <array><string>$INSTALL_DIR/$BUNDLE/Contents/MacOS/$APP</string></array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><false/>
    <key>ProcessType</key><string>Interactive</string>
</dict>
</plist>
PLISTEOF

# Stop any running/previous instance, then (re)load the agent. RunAtLoad starts
# it immediately; the agent starts it again on every login.
pkill -x "$APP" 2>/dev/null || true
GUI="gui/$(id -u)"
launchctl bootout "$GUI/$LABEL" 2>/dev/null || true
launchctl bootstrap "$GUI" "$PLIST" 2>/dev/null || launchctl load -w "$PLIST"
launchctl kickstart -k "$GUI/$LABEL" 2>/dev/null || true

echo ""
echo "✓ menu-token-bar is installed and now in your menu bar (look for \"</> NN%\")."
echo "  It starts automatically at login and reads your existing Claude Code login."
echo "  Uninstall: curl -fsSL https://raw.githubusercontent.com/atreyabhat/menu-token-bar/main/scripts/uninstall.sh | bash"
