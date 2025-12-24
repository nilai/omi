# Scripts

This directory contains utility scripts for the MemoPin app project.

## patch_reactive_ble.sh

**Purpose**: Fixes Gradle 8+ and Android Gradle Plugin 8+ compatibility issues with the `flutter_reactive_ble` package.

**When to use**: Run this script if you encounter any of the following errors during Android builds:
```
Could not get unknown property 'source' for generate-proto-generateDebugProto
```
or
```
Incorrect package="com.signify.hue.flutterreactiveble" found in source AndroidManifest.xml
Setting the namespace via the package attribute in the source AndroidManifest.xml is no longer supported.
```

**Usage**:
```bash
./scripts/patch_reactive_ble.sh
```

**What it does**:
1. Locates the `flutter_reactive_ble` package in your pub cache
2. Updates the protobuf-gradle-plugin version from 0.8.14 to 0.9.4
3. Fixes the `generateProtoTasks` syntax for Gradle 8+ compatibility
4. Updates protoc compiler version from 3.13.0 to 3.21.12 for ARM64 Mac support
5. Removes the deprecated `package` attribute from AndroidManifest.xml (Android Gradle Plugin 8+ requirement)
6. Creates backups of the original files (`.original` suffix)

**Note**: You may need to re-run this script after running `flutter pub get`, as it may restore the original package files.

## Automated Workflow

To ensure the patch is always applied, you can add this to your build process:

```bash
flutter pub get && ./scripts/patch_reactive_ble.sh && flutter run
```
