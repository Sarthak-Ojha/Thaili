#!/bin/bash
# =======================================================
#   Thaili - macOS Release Packaging Script
#   Run this on your Mac at the very end when ready!
# =======================================================

set -e

APP_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_APP="$SCRIPT_DIR/build/macos/Build/Products/Release/thaili.app"
DIST_DIR="$SCRIPT_DIR/dist"

echo ""
echo "======================================================="
echo "   Thaili - macOS Release Packaging Script            "
echo "======================================================="
echo ""

# 1. Fetch dependencies
echo "[1/3] Getting Flutter dependencies..."
flutter pub get

# 2. Build Release macOS App
echo "[2/3] Compiling Flutter macOS release app..."
flutter build macos --release

if [ ! -d "$BUILD_APP" ]; then
  echo "Error: Release build failed. $BUILD_APP not found."
  exit 1
fi
echo "macOS release build succeeded!"

# 3. Create dist folder and DMG/ZIP installer
echo "[3/3] Packaging distribution in dist/..."
mkdir -p "$DIST_DIR"

# Create a zip of the .app
ZIP_NAME="Thaili-v$APP_VERSION-macOS.zip"
cd "$SCRIPT_DIR/build/macos/Build/Products/Release"
zip -r -q "$DIST_DIR/$ZIP_NAME" "thaili.app"
echo "Portable ZIP created: dist/$ZIP_NAME"

# Create a native macOS .dmg disk image using built-in hdiutil
DMG_NAME="Thaili-v$APP_VERSION-macOS.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"
rm -f "$DMG_PATH"

hdiutil create -volname "Thaili" -srcfolder "thaili.app" -ov -format UDZO "$DMG_PATH" > /dev/null 2>&1
if [ -f "$DMG_PATH" ]; then
  echo "macOS Disk Image (DMG) created: dist/$DMG_NAME"
fi

echo ""
echo "======================================================="
echo "   Done! Release files are ready in dist/ folder:     "
echo "   - dist/$ZIP_NAME"
if [ -f "$DMG_PATH" ]; then
  echo "   - dist/$DMG_NAME"
fi
echo "======================================================="
echo ""
