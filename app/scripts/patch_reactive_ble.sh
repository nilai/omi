#!/bin/bash
# Patch flutter_reactive_ble to work with Gradle 8+
# Run this script after 'flutter pub get' if you encounter Gradle build errors

set -e

echo "🔧 Patching flutter_reactive_ble for Gradle 8+ compatibility..."

# Find the package path (supports both pub.dev and pub.flutter-io.cn mirrors)
PACKAGE_DIR=""
for mirror in "pub.dev" "pub.flutter-io.cn"; do
    POTENTIAL_DIR="$HOME/.pub-cache/hosted/$mirror/flutter_reactive_ble-3.1.1+1"
    if [ -d "$POTENTIAL_DIR" ]; then
        PACKAGE_DIR="$POTENTIAL_DIR"
        break
    fi
done

if [ -z "$PACKAGE_DIR" ]; then
    echo "❌ Error: flutter_reactive_ble package not found in pub cache"
    echo "   Please run 'flutter pub get' first"
    exit 1
fi

PACKAGE_PATH="$PACKAGE_DIR/android/build.gradle"
MANIFEST_PATH="$PACKAGE_DIR/android/src/main/AndroidManifest.xml"

echo "📍 Found package at: $PACKAGE_DIR"

# Create backup
if [ ! -f "$PACKAGE_PATH.original" ]; then
    cp "$PACKAGE_PATH" "$PACKAGE_PATH.original"
    echo "💾 Created backup: $PACKAGE_PATH.original"
fi

# Apply patches
echo "🔨 Applying patches..."

# 1. Update protobuf-gradle-plugin version (0.8.14 -> 0.9.4)
if grep -q "protobuf-gradle-plugin:0.8.14" "$PACKAGE_PATH"; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's/protobuf-gradle-plugin:0.8.14/protobuf-gradle-plugin:0.9.4/g' "$PACKAGE_PATH"
    else
        sed -i 's/protobuf-gradle-plugin:0.8.14/protobuf-gradle-plugin:0.9.4/g' "$PACKAGE_PATH"
    fi
    echo "  ✓ Updated protobuf-gradle-plugin to 0.9.4"
fi

# 2. Fix generateProtoTasks syntax for Gradle 8+
if grep -q "all().each { task ->" "$PACKAGE_PATH"; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's/all()\.each { task ->/all().configureEach { task ->/g' "$PACKAGE_PATH"
    else
        sed -i 's/all()\.each { task ->/all().configureEach { task ->/g' "$PACKAGE_PATH"
    fi
    echo "  ✓ Fixed generateProtoTasks syntax"
fi

# 3. Update protoc version for ARM64 Mac support (3.13.0 -> 3.21.12)
if grep -q "protoc:3.13.0" "$PACKAGE_PATH"; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's/protoc:3.13.0/protoc:3.21.12/g' "$PACKAGE_PATH"
    else
        sed -i 's/protoc:3.13.0/protoc:3.21.12/g' "$PACKAGE_PATH"
    fi
    echo "  ✓ Updated protoc to 3.21.12 for ARM64 Mac support"
fi

# 4. Remove package attribute from AndroidManifest.xml (deprecated in Android Gradle Plugin 8+)
if [ -f "$MANIFEST_PATH" ]; then
    # Create backup for manifest
    if [ ! -f "$MANIFEST_PATH.original" ]; then
        cp "$MANIFEST_PATH" "$MANIFEST_PATH.original"
        echo "💾 Created backup: $MANIFEST_PATH.original"
    fi

    if grep -q 'package="com.signify.hue.flutterreactiveble"' "$MANIFEST_PATH"; then
        # Use perl for multi-line replacement (more reliable than sed for this case)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            perl -i -p0e 's/<manifest xmlns:android="http:\/\/schemas\.android\.com\/apk\/res\/android"\n  package="com\.signify\.hue\.flutterreactiveble">/<manifest xmlns:android="http:\/\/schemas.android.com\/apk\/res\/android">/g' "$MANIFEST_PATH"
        else
            perl -i -p0e 's/<manifest xmlns:android="http:\/\/schemas\.android\.com\/apk\/res\/android"\n  package="com\.signify\.hue\.flutterreactiveble">/<manifest xmlns:android="http:\/\/schemas.android.com\/apk\/res\/android">/g' "$MANIFEST_PATH"
        fi
        echo "  ✓ Removed deprecated package attribute from AndroidManifest.xml"
    fi
fi

echo "✅ Patch applied successfully!"
echo ""
echo "📝 Note: You may need to run this script again after 'flutter pub get'"
