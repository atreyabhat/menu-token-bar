APP        := ccbar
VERSION    := 0.1.0
BUNDLE     := Claude Usage Bar.app
BUILD_DIR  := .build/release
CONFIG     := release

.PHONY: all build bundle run install uninstall icon dmg clean

all: bundle

build:
	swift build -c $(CONFIG)

## Assemble the .app bundle from the built executable + Info.plist.
bundle: build
	rm -rf "$(BUNDLE)"
	mkdir -p "$(BUNDLE)/Contents/MacOS"
	mkdir -p "$(BUNDLE)/Contents/Resources"
	cp "$(BUILD_DIR)/$(APP)" "$(BUNDLE)/Contents/MacOS/$(APP)"
	cp Resources/Info.plist "$(BUNDLE)/Contents/Info.plist"
	cp Resources/AppIcon.icns "$(BUNDLE)/Contents/Resources/AppIcon.icns"
	@echo "Built $(BUNDLE)"

## Build and launch it.
run: bundle
	open "$(BUNDLE)"

## Build + install as a login-launched menu bar app (hidden, not /Applications).
install:
	./scripts/install.sh

## Remove the installed app + login agent.
uninstall:
	./scripts/uninstall.sh

## Package a distributable disk image.
dmg: bundle
	./scripts/make-dmg.sh "$(APP)" "$(VERSION)"

## Regenerate the app icon from tools/genicon.swift.
icon:
	swift tools/genicon.swift AppIcon.iconset
	iconutil -c icns AppIcon.iconset -o Resources/AppIcon.icns
	rm -rf AppIcon.iconset

clean:
	rm -rf .build "$(BUNDLE)" "$(APP)-$(VERSION).dmg" AppIcon.iconset
