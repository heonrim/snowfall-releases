#!/bin/bash
# Installs (or updates) Snowfall into /Applications.
#   curl -fsSL https://raw.githubusercontent.com/heonrim/snowfall-releases/main/install.sh | bash
set -euo pipefail

URL="${SNOWFALL_URL:-https://github.com/heonrim/snowfall-releases/releases/latest/download/Snowfall.zip}"
DEST="/Applications/Snowfall.app"

if [[ "$(uname)" != "Darwin" ]]; then
    echo "Snowfall only runs on macOS." >&2; exit 1
fi
major="$(sw_vers -productVersion | cut -d. -f1)"
if (( major < 13 )); then
    echo "Snowfall needs macOS 13 Ventura or later (this Mac has $(sw_vers -productVersion))." >&2; exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "❄  Downloading Snowfall…"
if [[ -f "$URL" ]]; then cp "$URL" "$tmp/Snowfall.zip"; else curl -fL --progress-bar "$URL" -o "$tmp/Snowfall.zip"; fi
ditto -x -k "$tmp/Snowfall.zip" "$tmp"
[[ -d "$tmp/Snowfall.app" ]] || { echo "The download did not contain Snowfall.app." >&2; exit 1; }

if pgrep -x Snowfall >/dev/null; then
    echo "❄  Quitting the running Snowfall…"
    osascript -e 'tell application id "io.github.heonrim.snowfall" to quit' >/dev/null 2>&1 || pkill -x Snowfall || true
    for _ in {1..20}; do pgrep -x Snowfall >/dev/null || break; sleep 0.25; done
fi

sudo=""
if [[ ! -w /Applications ]] || { [[ -e "$DEST" ]] && [[ ! -w "$DEST" ]]; }; then
    echo "❄  /Applications needs your password to install."
    sudo="sudo"
fi
$sudo rm -rf "$DEST"
$sudo ditto "$tmp/Snowfall.app" "$DEST"
# The app is free and not notarized by Apple; this tells macOS you chose to trust it.
$sudo xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true

echo "❄  Installed to $DEST. Look for the snowflake in your menu bar."
open "$DEST"
