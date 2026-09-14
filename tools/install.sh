#!/usr/bin/env bash
#
# Build GarminGolfTrainer and sideload it onto a USB-connected watch.
#
#   tools/install.sh              build + install
#   tools/install.sh --build-only just compile the .prg
#
# Override via environment: DEVICE, DEVELOPER_KEY, SDK_ROOT, APPS_DIR
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"

DEVICE="${DEVICE:-fenix8solar47mm}"
DEVELOPER_KEY="${DEVELOPER_KEY:-$REPO/../developer_key}"
APPS_DIR="${APPS_DIR:-GARMIN/Apps}"
PRG="bin/GarminGolfTrainer-release.prg"
REMOTE_NAME="GarminGolfTrainer.prg"

# Pick the newest installed SDK unless one is pinned.
if [[ -z "${SDK_ROOT:-}" ]]; then
    SDK_ROOT="$(find "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks" \
        -maxdepth 1 -name 'connectiq-sdk-mac-*' -type d 2>/dev/null | sort | tail -1)"
fi
[[ -n "$SDK_ROOT" && -x "$SDK_ROOT/bin/monkeyc" ]] || {
    echo "No Connect IQ SDK found. Install it, or set SDK_ROOT." >&2; exit 1; }
[[ -f "$DEVELOPER_KEY" ]] || {
    echo "Developer key not found at $DEVELOPER_KEY (set DEVELOPER_KEY)." >&2; exit 1; }

echo "==> Building $DEVICE with $(basename "$SDK_ROOT")"
mkdir -p bin
"$SDK_ROOT/bin/monkeyc" -f monkey.jungle -o "$PRG" -d "$DEVICE" -y "$DEVELOPER_KEY" -r

[[ "${1:-}" == "--build-only" ]] && { echo "Built $PRG"; exit 0; }

echo "==> Preparing MTP transfer"
make -s -C tools mtpsend

# macOS has no native MTP support and Android File Transfer's agent grabs any
# MTP device the moment it is plugged in, holding the USB interface
# exclusively. Garmin Express does the same. Both must be closed.
for app in "Android File Transfer" "Garmin Express"; do
    if pgrep -qf "$app"; then
        echo "    closing $app (it holds the USB interface)"
        osascript -e "quit app \"$app\"" 2>/dev/null || true
        pkill -f "$app Agent" 2>/dev/null || true
    fi
done

echo "==> Sending to $APPS_DIR"
tools/mtpsend send "$PRG" "$APPS_DIR" "$REMOTE_NAME"

echo "==> Verifying"
tools/mtpsend list "$APPS_DIR" | grep -i "$REMOTE_NAME" \
    || { echo "Upload not visible in $APPS_DIR" >&2; exit 1; }

cat <<'DONE'

Done. Unplug the watch, press START, and pick "Golf Trainer" from the list.
The .prg disappears from GARMIN/Apps on the next connect -- the watch moves it
into internal storage. That is normal, not a failed install.
DONE
