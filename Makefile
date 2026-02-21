APP_NAME    := Desk Plate
MODULE_NAME := DeskPlate
BUILD_DIR   := $(CURDIR)/build
INSTALL_DIR := $(HOME)/Applications

SDK         := $(shell xcrun --show-sdk-path)
TARGET      := arm64-apple-macos26.0
FRAMEWORKS  := -framework Cocoa -framework ServiceManagement

SOURCES     := $(wildcard DeskPlate/*.swift)

# Use a stamp file to track build state, since the app bundle path has a space
STAMP       := $(BUILD_DIR)/.build-stamp

.PHONY: all clean install uninstall

all: $(STAMP)

$(STAMP): $(SOURCES) DeskPlate/Info.plist scripts/generate_icon.swift
	@mkdir -p "$(BUILD_DIR)/$(APP_NAME).app/Contents/MacOS"
	@mkdir -p "$(BUILD_DIR)/$(APP_NAME).app/Contents/Resources"
	swiftc -O \
		-sdk "$(SDK)" \
		-target $(TARGET) \
		$(FRAMEWORKS) \
		-module-name $(MODULE_NAME) \
		$(SOURCES) \
		-o "$(BUILD_DIR)/$(APP_NAME).app/Contents/MacOS/$(MODULE_NAME)"
	@if [ ! -f "$(BUILD_DIR)/$(MODULE_NAME).icns" ]; then \
		echo "Generating app icon..."; \
		xcrun swift -sdk "$(SDK)" scripts/generate_icon.swift "$(BUILD_DIR)"; \
	fi
	@cp "$(BUILD_DIR)/$(MODULE_NAME).icns" "$(BUILD_DIR)/$(APP_NAME).app/Contents/Resources/$(MODULE_NAME).icns"
	@cp DeskPlate/Info.plist "$(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist"
	@codesign --force --sign - "$(BUILD_DIR)/$(APP_NAME).app"
	@touch "$@"
	@echo "Built: $(BUILD_DIR)/$(APP_NAME).app"

install: all
	@mkdir -p "$(INSTALL_DIR)"
	@rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	@cp -R "$(BUILD_DIR)/$(APP_NAME).app" "$(INSTALL_DIR)/$(APP_NAME).app"
	@echo "Installed to $(INSTALL_DIR)/$(APP_NAME).app"

uninstall:
	@rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	@echo "Removed $(INSTALL_DIR)/$(APP_NAME).app"

clean:
	@rm -rf "$(BUILD_DIR)"
	@echo "Cleaned build directory"
