#!/bin/bash
# Renders README screenshots (docs/) offscreen with fake data.
set -euo pipefail
cd "$(dirname "$0")/.."

swiftc \
    Sources/IPMonit/IPMonitor.swift \
    Sources/IPMonit/ContentView.swift \
    Sources/IPMonit/AppDelegate.swift \
    Sources/IPMonit/Localization.swift \
    scripts/screenshots/main.swift \
    -o /tmp/ipmonit-render-screens

/tmp/ipmonit-render-screens docs

# Иконка для README
sips -z 256 256 -s format png assets/AppIcon.icns --out docs/icon.png >/dev/null
echo "written: docs/icon.png"
