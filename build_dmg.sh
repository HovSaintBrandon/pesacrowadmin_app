#!/bin/bash

# Exit on error
set -e

# Configuration
APP_NAME="pesacrowadmin_app"
DMG_NAME="PesaCrowAdmin"
BUILD_DIR="build/macos/Build/Products/Release"
STAGING_DIR="build/dmg_staging"

echo "----------------------------------------------------"
echo "🚀 PesaCrow Admin: macOS DMG Builder"
echo "----------------------------------------------------"

# 1. Build the Flutter app in release mode
echo "🛠️  Step 1: Building Flutter macOS app in release mode..."
flutter build macos --release

# 2. Check if build succeeded
if [ ! -d "$BUILD_DIR/$APP_NAME.app" ]; then
    echo "❌ Error: Build failed. .app bundle not found at $BUILD_DIR/$APP_NAME.app"
    exit 1
fi

echo "✅ Build completed successfully."

# 3. Create staging directory
echo "📂 Step 2: Preparing staging area..."
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

# 4. Copy the app to staging
echo "📝 Step 3: Copying app bundle..."
cp -R "$BUILD_DIR/$APP_NAME.app" "$STAGING_DIR/"

# 5. Create a link to /Applications for easy installation
echo "🔗 Step 4: Creating Applications shortcut..."
ln -s /Applications "$STAGING_DIR/Applications"

# 6. Create the DMG
echo "💿 Step 5: Creating Disk Image ($DMG_NAME.dmg)..."
rm -f "$DMG_NAME.dmg"
hdiutil create -volname "$DMG_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_NAME.dmg"

# 7. Cleanup
echo "🧹 Step 6: Cleaning up..."
rm -rf "$STAGING_DIR"

echo "----------------------------------------------------"
echo "✅ SUCCESS!"
echo "📍 Your DMG is ready: $(pwd)/$DMG_NAME.dmg"
echo "----------------------------------------------------"
