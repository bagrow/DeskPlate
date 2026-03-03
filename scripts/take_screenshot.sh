#!/bin/bash
#
# Automate taking the main-window screenshot for README/assets.
#
# What it does:
#   1. Backs up current UserDefaults
#   2. Writes demo labels/icons
#   3. Kills and relaunches the app
#   4. Waits for you to open the preferences window
#   5. Takes a screenshot of the window
#   6. Restores original UserDefaults
#   7. Relaunches the app with restored settings
#
# Usage:
#   ./scripts/take_screenshot.sh
#
# Requires: Accessibility permissions for Terminal/shell (System Settings > Privacy > Accessibility)

set -euo pipefail

BUNDLE_ID="com.bagrow.DeskPlate"
PROCESS_NAME="DeskPlate"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_PATH="$PROJECT_DIR/build/Desk Plate.app"
OUTPUT="$PROJECT_DIR/assets/main-window.png"
BACKUP_FILE="/tmp/deskplate-defaults-backup.plist"

cleanup() {
    echo ""
    echo "Restoring original settings..."
    killall "$PROCESS_NAME" 2>/dev/null || true
    sleep 0.5
    if [[ -f "$BACKUP_FILE" ]]; then
        defaults import "$BUNDLE_ID" "$BACKUP_FILE"
        rm -f "$BACKUP_FILE"
    fi
    echo "Relaunching with restored settings..."
    open "$APP_PATH"
    echo "Done!"
}
trap cleanup EXIT

# --- 1. Back up current defaults ---

echo "Backing up current settings..."
defaults export "$BUNDLE_ID" "$BACKUP_FILE" 2>/dev/null || true

# --- 2. Write demo labels and icons ---

echo "Writing demo labels..."
defaults write "$BUNDLE_ID" spaceLabels -dict \
    "0" "Landing zone" \
    "1" "Critical research - Write" \
    "2" "Critical research - Code" \
    "3" "Awesome Report" \
    "4" "Killer Proposal" \
    "5" "Vibe Codin' Apps"

defaults write "$BUNDLE_ID" spaceIcons -dict \
    "0" "person.2.fill" \
    "1" "pencil" \
    "2" "chart.line.uptrend.xyaxis" \
    "3" "clock.badge.checkmark" \
    "4" "dollarsign.circle" \
    "5" "laptopcomputer"

defaults write "$BUNDLE_ID" labelPosition -string "bottomRight"
defaults write "$BUNDLE_ID" labelTint -string "clear"
defaults write "$BUNDLE_ID" labelMargin -float 0
defaults write "$BUNDLE_ID" overlayEnabled -bool true

# --- 3. Kill and relaunch ---

echo "Relaunching app with demo data..."
killall "$PROCESS_NAME" 2>/dev/null || true
sleep 0.5
open "$APP_PATH"
sleep 1

# --- 4. Wait for user to arrange the window ---

DELAY=${DELAY:-5}

echo ""
echo ">>> Click the menu bar icon to open the preferences window."
echo ">>> Arrange it however you'd like for the screenshot."
echo ""

for (( i=DELAY; i>0; i-- )); do
    printf "\r>>> Capturing in %d... " "$i"
    sleep 1
done
printf "\r>>> Capturing now!     \n"

# --- 5. Take screenshot ---

screencapture -o -x -w "$OUTPUT"
echo "Saved: $OUTPUT"
