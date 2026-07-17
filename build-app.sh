#!/bin/bash
# Builds IPMonit.app into build/
# Usage: ./build-app.sh [-dev]
#   -dev  include dev-only About info (project folder path, build notes)
set -euo pipefail
cd "$(dirname "$0")"

SWIFT_FLAGS=()
if [ "${1:-}" = "-dev" ]; then
    echo "Dev build (DEV_BUILD enabled)"
    SWIFT_FLAGS=(-Xswiftc -DDEV_BUILD)
fi

swift build -c release ${SWIFT_FLAGS[@]+"${SWIFT_FLAGS[@]}"}

APP="build/IPMonit.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/IPMonit "$APP/Contents/MacOS/IPMonit"

[ -f assets/AppIcon.icns ] || ./scripts/make-icon.sh
cp assets/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>IPMonit</string>
    <key>CFBundleDisplayName</key><string>IPMonit</string>
    <key>CFBundleIdentifier</key><string>local.ipmonit</string>
    <key>CFBundleExecutable</key><string>IPMonit</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
EOF

codesign --force --deep --sign - "$APP"
echo "Done: $PWD/$APP"
