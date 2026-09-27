SHELL := /bin/bash

APP_NAME := Mood
BUILD_DIR := build
BUNDLE := $(BUILD_DIR)/Mood.app
SWIFT_SOURCES := $(wildcard App/*.swift)

.PHONY: all build install run memory clean icon test

all: build

test:
	node tests/test_calendar_store.js
	swiftc -swift-version 5 -o /tmp/mood_bridge_test App/FileBridge.swift tests/test_bridge.swift
	/tmp/mood_bridge_test
	rm -f /tmp/mood_bridge_test

build: $(BUNDLE)

$(BUILD_DIR)/Mood: $(SWIFT_SOURCES)
	@mkdir -p $(BUILD_DIR)
	swiftc -O -swift-version 5 \
		-framework AppKit -framework WebKit -framework CoreServices \
		-o $@ $(SWIFT_SOURCES)

$(BUILD_DIR)/AppIcon.icns: tools/make_icon.swift
	@mkdir -p $(BUILD_DIR)
	swift tools/make_icon.swift $(BUILD_DIR)/AppIcon.icns

$(BUNDLE): $(BUILD_DIR)/Mood $(BUILD_DIR)/AppIcon.icns App/Info.plist
	rm -rf $(BUNDLE)
	mkdir -p $(BUNDLE)/Contents/MacOS $(BUNDLE)/Contents/Resources
	cp $(BUILD_DIR)/Mood $(BUNDLE)/Contents/MacOS/Mood
	cp App/Info.plist $(BUNDLE)/Contents/Info.plist
	cp $(BUILD_DIR)/AppIcon.icns $(BUNDLE)/Contents/Resources/AppIcon.icns
	printf 'APPL????' > $(BUNDLE)/Contents/PkgInfo
	codesign --force --sign - $(BUNDLE)

install: build
	mkdir -p $(HOME)/Applications
	rm -rf $(HOME)/Applications/Mood.app
	cp -R $(BUNDLE) $(HOME)/Applications/Mood.app
	@echo "Installed to $(HOME)/Applications/Mood.app"

run: build
	open $(BUNDLE)

memory:
	python3 tools/measure_memory.py

clean:
	rm -rf $(BUILD_DIR)
