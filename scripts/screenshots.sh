#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT="$PROJECT_DIR/Nevernote.xcodeproj"
SCHEME="NeverNote"
BUNDLE_ID_IOS="com.nathanfennel.NeverNote"
BUNDLE_ID_WATCH="com.nathanfennel.NeverNote.watchkitapp"
OUTPUT_DIR="$PROJECT_DIR/screenshots"
BUILD_DIR="$PROJECT_DIR/.screenshot-build"

IOS_RUNTIME="com.apple.CoreSimulator.SimRuntime.iOS-26-5"
WATCH_RUNTIME="com.apple.CoreSimulator.SimRuntime.watchOS-11-0"
IPHONE_DEVICE_TYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max"
IPAD_DEVICE_TYPE="com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M5-12GB"
WATCH_DEVICE_TYPE="com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-9-41mm"
WATCH_COMPANION_TYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max"

# Persistent simulator names — reused across runs so boot only happens once.
IPHONE_SIM_NAME="NeverNote_Screenshots_iPhone"
IPAD_SIM_NAME="NeverNote_Screenshots_iPad"
WATCH_SIM_NAME="NeverNote_Screenshots_Watch"
WATCH_COMPANION_SIM_NAME="NeverNote_Screenshots_WatchCompanion"

# ── Helper: find an existing available simulator by name, or create it ────────
# Prints the UDID. Sets BOOTED_BY_US=1 if we booted it, 0 if already booted.
BOOTED_BY_US_MAP=()  # "udid=1" entries for sims we started

find_or_create() {
    local name="$1" device_type="$2" runtime="$3"
    # Query JSON list for an available sim with this name
    local udid
    udid=$(xcrun simctl list devices --json | python3 -c "
import json, sys
data = json.load(sys.stdin)
for rt, devs in data['devices'].items():
    for d in devs:
        if d.get('isAvailable') and d['name'] == '$name':
            print(d['udid'])
            sys.exit(0)
" 2>/dev/null || true)

    if [ -z "$udid" ]; then
        udid=$(xcrun simctl create "$name" "$device_type" "$runtime")
        echo "  Created $name ($udid)" >&2
    else
        echo "  Reusing $name ($udid)" >&2
    fi
    echo "$udid"
}

boot_if_needed() {
    local udid="$1"
    local state
    state=$(xcrun simctl list devices --json | python3 -c "
import json, sys
data = json.load(sys.stdin)
for rt, devs in data['devices'].items():
    for d in devs:
        if d['udid'] == '$udid':
            print(d['state'])
            sys.exit(0)
" 2>/dev/null || true)

    if [ "$state" != "Booted" ]; then
        xcrun simctl boot "$udid"
        xcrun simctl bootstatus "$udid" -b > /dev/null
        BOOTED_BY_US_MAP+=("$udid")
        echo "  Booted $udid" >&2
    else
        echo "  Already booted $udid" >&2
    fi
}

# ── Step 1: Resolve simulators ────────────────────────────────────────────────
echo "==> Resolving simulators..."
IPHONE_UDID=$(find_or_create "$IPHONE_SIM_NAME" "$IPHONE_DEVICE_TYPE" "$IOS_RUNTIME")
IPAD_UDID=$(find_or_create "$IPAD_SIM_NAME" "$IPAD_DEVICE_TYPE" "$IOS_RUNTIME")
WATCH_COMPANION_UDID=$(find_or_create "$WATCH_COMPANION_SIM_NAME" "$WATCH_COMPANION_TYPE" "$IOS_RUNTIME")
WATCH_UDID=$(find_or_create "$WATCH_SIM_NAME" "$WATCH_DEVICE_TYPE" "$WATCH_RUNTIME")

# Pair watch with companion if not already paired (pair requires both shutdown)
WATCH_PAIR=$(xcrun simctl list pairs --json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for pair_id, pair in data.get('pairs', {}).items():
    phone = pair.get('phone', {}).get('udid','')
    watch = pair.get('watch', {}).get('udid','')
    if phone == '$WATCH_COMPANION_UDID' and watch == '$WATCH_UDID':
        print('paired')
        sys.exit(0)
" 2>/dev/null || true)

if [ "$WATCH_PAIR" != "paired" ]; then
    # Must be shutdown to pair
    xcrun simctl shutdown "$WATCH_UDID" 2>/dev/null || true
    xcrun simctl shutdown "$WATCH_COMPANION_UDID" 2>/dev/null || true
    xcrun simctl pair "$WATCH_UDID" "$WATCH_COMPANION_UDID" 2>/dev/null || true
    echo "  Paired watch with companion"
fi

# ── Step 2: Boot simulators ───────────────────────────────────────────────────
echo "==> Booting simulators (skipped if already running)..."
boot_if_needed "$IPHONE_UDID"
boot_if_needed "$IPAD_UDID"
boot_if_needed "$WATCH_COMPANION_UDID"
boot_if_needed "$WATCH_UDID"

# ── Step 3: Build iOS app ─────────────────────────────────────────────────────
echo "==> Building iOS app..."
xcodebuild build \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=$IPHONE_UDID" \
    -configuration Debug \
    -derivedDataPath "$BUILD_DIR" \
    CODE_SIGNING_ALLOWED=NO \
    2>&1 | grep -E "^(error:|Build succeeded|FAILED)" | tail -10 || true

IOS_APP="$BUILD_DIR/Build/Products/Debug-iphonesimulator/NeverNote.app"
if [ ! -d "$IOS_APP" ]; then
    echo "ERROR: iOS app not found at $IOS_APP"
    exit 1
fi
echo "    Built: $IOS_APP"

WATCH_APP="$IOS_APP/Watch/NeverNote Watch App.app"
SKIP_WATCH=0
if [ ! -d "$WATCH_APP" ]; then
    echo "WARNING: Watch app not found at $WATCH_APP — skipping Watch screenshots."
    SKIP_WATCH=1
fi

# ── Step 4: Install apps ──────────────────────────────────────────────────────
echo "==> Installing apps..."
xcrun simctl install "$IPHONE_UDID" "$IOS_APP"
xcrun simctl install "$IPAD_UDID" "$IOS_APP"
if [ "$SKIP_WATCH" -eq 0 ]; then
    xcrun simctl install "$WATCH_UDID" "$WATCH_APP"
fi

# ── Helpers ───────────────────────────────────────────────────────────────────

capture() {
    local udid="$1" outpath="$2"
    mkdir -p "$(dirname "$outpath")"
    # Headless sims occasionally stall rendering ("Timeout waiting for screen
    # surfaces"), especially right after an appearance switch — retry.
    local attempt
    for attempt in 1 2 3 4; do
        if xcrun simctl io "$udid" screenshot "$outpath" 2>/dev/null; then
            echo "    $outpath"
            return 0
        fi
        echo "    capture failed (attempt $attempt), retrying..." >&2
        sleep 3
    done
    xcrun simctl io "$udid" screenshot "$outpath"
    echo "    $outpath"
}

ios_shot() {
    local udid="$1" label="$2" appearance="$3" idx="$4" kb="$5"
    local outpath="$OUTPUT_DIR/$label/$appearance/text_${idx}_${kb}.png"

    xcrun simctl ui "$udid" appearance "$appearance"
    xcrun simctl terminate "$udid" "$BUNDLE_ID_IOS" 2>/dev/null || true

    local args=(--screenshot-mode --screenshot-text "$idx")
    [ "$kb" = "keyboard" ] && args+=(--screenshot-keyboard)

    xcrun simctl launch "$udid" "$BUNDLE_ID_IOS" "${args[@]}" > /dev/null
    [ "$kb" = "keyboard" ] && sleep 2.5 || sleep 1.5

    capture "$udid" "$outpath"
    xcrun simctl terminate "$udid" "$BUNDLE_ID_IOS" 2>/dev/null || true
}

watch_shot() {
    local udid="$1" idx="$2"
    local outpath="$OUTPUT_DIR/Apple_Watch_41mm/text_${idx}.png"

    # watchOS has no light/dark appearance setting — always dark
    xcrun simctl terminate "$udid" "$BUNDLE_ID_WATCH" 2>/dev/null || true
    xcrun simctl launch "$udid" "$BUNDLE_ID_WATCH" \
        --screenshot-mode --screenshot-text "$idx" > /dev/null
    sleep 1.5

    capture "$udid" "$outpath"
    xcrun simctl terminate "$udid" "$BUNDLE_ID_WATCH" 2>/dev/null || true
}

# ── Step 5: Capture all screenshots ──────────────────────────────────────────
echo "==> Capturing screenshots..."
mkdir -p "$OUTPUT_DIR"

# Optionally capture a subset, e.g. SCREENSHOT_TEXTS="0 1" ./scripts/screenshots.sh
for idx in ${SCREENSHOT_TEXTS:-0 1 2 3 4}; do
    for appearance in light dark; do
        echo "  [text $idx / $appearance]"

        ios_shot "$IPHONE_UDID" "iPhone_17_Pro_Max" "$appearance" "$idx" "no_keyboard"
        ios_shot "$IPHONE_UDID" "iPhone_17_Pro_Max" "$appearance" "$idx" "keyboard"
        ios_shot "$IPAD_UDID"   "iPad_Pro_13"       "$appearance" "$idx" "no_keyboard"
        ios_shot "$IPAD_UDID"   "iPad_Pro_13"       "$appearance" "$idx" "keyboard"

    done

    if [ "$SKIP_WATCH" -eq 0 ]; then
        watch_shot "$WATCH_UDID" "$idx"
    fi
done

COUNT=$(find "$OUTPUT_DIR" -name '*.png' | wc -l | tr -d ' ')
echo ""
echo "==> Done! $COUNT screenshots saved to: $OUTPUT_DIR"
open "$OUTPUT_DIR"
