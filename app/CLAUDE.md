# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Omi is a Flutter-based mobile application that serves as the companion app for MemoPin wearable devices. The app enables users to interact with their MemoPin device (and other supported devices like Frame, Apple Watch, XOR), manage apps, record and process conversations/memories, and customize their experience.

## Development Commands

### Setup
```bash
# Initial setup for iOS
bash setup.sh ios

# Initial setup for Android
bash setup.sh android

# Initial setup for macOS
bash setup.sh macos
```

### Running the App
```bash
# Run in development mode (default flavor)
flutter run --flavor dev

# Run in production mode
flutter run --flavor prod

# Build for iOS release
flutter build ios --flavor dev --release

# Install to connected iPhone
ios-deploy --bundle build/ios/iphoneos/Runner.app --debug
```

### Code Generation
```bash
# Generate code for json_serializable, envied, and other build_runner tasks
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for continuous generation
flutter pub run build_runner watch --delete-conflicting-outputs

# Generate pigeon platform interface code
flutter pub run pigeon --input pigeons/message.dart
```

### Testing and Analysis
```bash
# Run static analysis
flutter analyze

# Run tests
flutter test

# Run integration tests
flutter test integration_test
```

## Architecture

### Flavor System
The app uses Flutter flavors to manage different environments:
- **dev**: Development environment with dev API endpoints and Firebase config
- **prod**: Production environment with production API endpoints and Firebase config

Flavors are managed through:
- `lib/flavors.dart` - Flavor enum and configuration
- `lib/env/` - Environment-specific configurations (dev_env.dart, prod_env.dart)
- Firebase configs: `firebase_options_dev.dart` and `firebase_options_prod.dart`

### State Management
The app uses Provider for state management with a clear pattern:
- **BaseProvider** (`lib/providers/base_provider.dart`) - Base class for all providers with loading state management
- **Providers** (`lib/providers/`) - Feature-specific state management classes that extend BaseProvider
  - Key providers: AppProvider, AuthProvider, DeviceProvider, MemoriesProvider, CaptureProvider, ConversationProvider, MessageProvider

All providers follow the pattern of extending `BaseProvider` which provides `loading` state and `setLoadingState()` method.

### Core Architecture Layers

1. **Backend Layer** (`lib/backend/`)
   - `http/` - API client and HTTP utilities
     - `shared.dart` - Core HTTP client with auth header management and request builders
   - `schema/` - Data models and schemas
   - `preferences.dart` - SharedPreferences wrapper for local storage

2. **Services Layer** (`lib/services/`)
   - `devices/` - Device connection management for Omi, Frame, Apple Watch, etc.
     - Device-specific connections: `omi_connection.dart`, `frame_connection.dart`, `apple_watch_connection.dart`
     - Factory pattern: `device_connection.dart` creates appropriate connection based on device type
     - Transport abstraction: `transports/` contains BLE, Watch, and Frame transport implementations
   - `sockets/` - WebSocket connections for real-time features
     - `transcription_connection.dart`, `wal_connection.dart`, `pure_socket.dart`
   - `notifications/` - Push notification handling
   - `auth_service.dart` - Firebase authentication management

3. **UI Layer**
   - `lib/pages/` - Full page components organized by feature (apps, capture, conversations, memories, settings, etc.)
   - `lib/widgets/` - Reusable widget components
   - `lib/ui/` - Atomic design components (atoms, molecules, organisms)

4. **Platform-Specific**
   - `lib/mobile/` - Mobile-specific app shell
   - `lib/desktop/` - Desktop-specific app shell
   - `lib/core/app_shell.dart` - Routing shell that handles deep links and app navigation

### Device Connection Architecture

The app supports multiple device types through an abstraction layer:
- **DeviceConnectionFactory** (`lib/services/devices/device_connection.dart`) - Creates appropriate device connections based on device type and transport
- **Transport Layer** - Abstracts communication protocols (BLE, Watch Connectivity, Frame)
- **Device-Specific Connections** - Handle device-specific logic:
  - `OmiDeviceConnection` - For MemoPin and OpenGlass devices
  - `FrameDeviceConnection` - For Brilliant Frame smart glasses
  - `AppleWatchConnection` - For Apple Watch integration
  - `XorDeviceConnection` - For XOR devices
  - `BeeConnection`, `FieldyConnection` - Additional device support

Device discovery is handled through `lib/services/devices/discovery/device_locator.dart`.

### Models and Data
- `lib/models/` - Core data models (user_usage.dart, subscription.dart, sync_state.dart, playback_state.dart)
- `lib/backend/schema/` - API schema models (app.dart, bt_device/, etc.)
- Many models use `json_serializable` with `.g.dart` generated files

### Audio Processing
- Audio codec support: PCM16, PCM8, MuLaw, Opus, AAC (defined in `bt_device.dart`)
- Opus integration via `opus_flutter` and `opus_dart` packages
- Custom opus implementations with dependency overrides for iOS and Android

### Firebase Integration
- Firebase Auth for authentication
- Firebase Messaging for push notifications
- Firebase Crashlytics for crash reporting
- Background message handler in `main.dart` for FCM data messages

### Analytics and Monitoring
- Mixpanel for user analytics
- GrowthBook for feature flags and A/B testing
- Intercom for user support
- Talker for logging

## Code Organization Patterns

### Provider Pattern
All providers should:
1. Extend `BaseProvider` for consistent loading state management
2. Call `notifyListeners()` after state changes
3. Handle async operations with proper error handling

### API Calls
- Use `buildHeaders()` from `lib/backend/http/shared.dart` to construct headers with auth
- Auth tokens are automatically refreshed when expired (5-minute buffer)
- Use `ApiClient` for HTTP client management

### Navigation
- Deep linking handled through `AppShell` using `app_links` package
- Routes support: `/apps/{appId}`, `/personas/{personaId}`, `/chat/{chatId}`, and more

## Common Development Patterns

### Adding a New Feature Page
1. Create page directory in `lib/pages/{feature}/`
2. Create provider in `lib/providers/{feature}_provider.dart` extending `BaseProvider`
3. Add provider to the MultiProvider in main app shell
4. Add routes/navigation in `app_shell.dart` if needed

### Adding Device Support
1. Create device connection class implementing `DeviceConnection` in `lib/services/devices/`
2. Add device type to enum in `bt_device.dart`
3. Update `DeviceConnectionFactory` to handle new device type
4. Create or reuse appropriate transport from `lib/services/devices/transports/`

### Working with Audio
- Use BleAudioCodec enum for codec type checking
- Audio streaming happens through device connections
- Transcription via WebSocket connections in `lib/services/sockets/`

## Important Files

- `lib/main.dart` - App entry point, Firebase initialization, provider setup
- `lib/core/app_shell.dart` - Main routing and deep link handling
- `lib/backend/http/shared.dart` - Core HTTP utilities and auth
- `lib/services/devices/device_connection.dart` - Device connection factory
- `lib/providers/app_provider.dart` - App marketplace state management
- `lib/providers/device_provider.dart` - Device connection state management
- `pubspec.yaml` - Dependencies and build configuration

## Platform-Specific Notes

### iOS
- Requires Xcode 16.4+, CocoaPods 1.16.2+
- Developer Mode must be enabled on device
- SSH access needed for certificate repositories during setup

### Android
- Requires Android Studio Iguana | 2024.3
- Android SDK Platform API 35
- JDK 21, Gradle 8.10, NDK 28.2.13676358
- USB debugging must be enabled

### Desktop (macOS)
- Limited desktop support via `lib/desktop/`
- Uses `window_manager` package for window management

## Dependencies to Note

- **flutter_blue_plus** - Bluetooth Low Energy communication
- **provider** - State management
- **firebase_core**, **firebase_auth**, **firebase_messaging** - Firebase services
- **opus_flutter**, **opus_dart** - Audio codec support (custom forks via dependency_overrides)
- **frame_sdk** - Brilliant Frame smart glasses integration
- **web_socket_channel** - WebSocket connections for real-time features
- **envied** - Environment variable management (requires code generation)
- **json_serializable** - JSON serialization (requires code generation)
