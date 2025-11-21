# Omi App 编译和部署指南

本文档详细说明 Omi 应用的编译、运行、打包和配置更新流程。

## 目录

- [环境要求](#环境要求)
- [初始设置](#初始设置)
- [开发运行](#开发运行)
- [代码生成](#代码生成)
- [更新配置](#更新配置)
- [打包发布](#打包发布)
- [常见问题](#常见问题)

---

## 环境要求

### iOS
- Xcode 16.4+
- CocoaPods 1.16.2+
- iOS Developer Mode 已启用
- SSH 访问（证书仓库需要）

### Android
- Android Studio Iguana | 2024.3+
- Android SDK Platform API 35
- JDK 21
- Gradle 8.10
- NDK 28.2.13676358
- USB 调试已启用

### macOS Desktop
- macOS 开发环境
- 使用 `window_manager` 包

---

## 初始设置

### 首次设置

```bash
# iOS 初始设置
bash setup.sh ios

# Android 初始设置
bash setup.sh android

# macOS 初始设置
bash setup.sh macos
```

### 安装依赖

```bash
# 获取 Flutter 依赖
flutter pub get

# 生成必要的代码文件
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 开发运行

### Dev 环境运行

```bash
# 默认 dev flavor
flutter run --flavor dev

# 指定设备运行
flutter run --flavor dev -d <device_id>

# 查看可用设备
flutter devices
```

### 启动 DevTools 查看日志

```bash
# 运行应用时会显示 DevTools URL
flutter run --flavor dev

# 在浏览器中打开显示的 DevTools 链接
# 点击 "Logging" 标签页查看实时日志
```

### 热重载和重启

- **热重载**: 在运行中的终端按 `r`
- **完全重启**: 在运行中的终端按 `R`
- **退出**: 在运行中的终端按 `q`

---

## 代码生成

项目使用多个代码生成工具，修改相关文件后需要重新生成代码。

### 生成所有代码

```bash
# 生成 json_serializable, envied 等
flutter pub run build_runner build --delete-conflicting-outputs

# 监听模式（自动生成）
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 生成 Pigeon 平台接口

```bash
# 生成平台通信代码
flutter pub run pigeon --input pigeons/message.dart
```

### 何时需要重新生成

需要运行 `build_runner` 的情况：
- 修改了 `.dev.env` 或 `.prod.env` 文件
- 添加或修改了使用 `@JsonSerializable()` 的模型类
- 修改了任何带有 `part 'xxx.g.dart'` 的文件
- 添加或修改了环境变量配置

---

## 更新配置

### 更新环境变量（重要）

#### 1. 修改 Dev 环境配置

```bash
# 编辑 dev 环境变量
vim .dev.env

# 或使用其他编辑器
code .dev.env
```

#### 2. 重新生成环境代码

```bash
# 重新生成 envied 代码
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 3. 清理并重新运行

```bash
# 清理构建缓存
flutter clean

# 重新获取依赖
flutter pub get

# 重新运行应用
flutter run --flavor dev
```

#### 一键更新配置命令

```bash
# 修改 .dev.env 后执行
flutter pub run build_runner build --delete-conflicting-outputs && \
flutter clean && \
flutter pub get && \
flutter run --flavor dev
```

### 更新 Production 环境配置

```bash
# 1. 编辑 prod 环境变量
vim .prod.env

# 2. 重新生成代码
flutter pub run build_runner build --delete-conflicting-outputs

# 3. 清理并构建
flutter clean && flutter pub get

# 4. 使用 prod flavor 运行或打包
flutter run --flavor prod
```

### 更新 Firebase 配置

修改 Firebase 配置后：

```bash
# Dev 环境
# 更新 lib/firebase_options_dev.dart

# Prod 环境
# 更新 lib/firebase_options_prod.dart

# 重新运行应用
flutter run --flavor dev  # 或 --flavor prod
```

---

## 打包发布

### Android 打包

#### Dev 版本（测试用）

```bash
# 构建 APK
flutter build apk --flavor dev --release

# 构建 App Bundle (推荐用于 Google Play)
flutter build appbundle --flavor dev --release

# 输出位置
# APK: build/app/outputs/flutter-apk/app-dev-release.apk
# AAB: build/app/outputs/bundle/devRelease/app-dev-release.aab
```

#### Production 版本

```bash
# 构建生产 APK
flutter build apk --flavor prod --release

# 构建生产 App Bundle
flutter build appbundle --flavor prod --release

# 输出位置
# APK: build/app/outputs/flutter-apk/app-prod-release.apk
# AAB: build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

#### 直接安装到设备

```bash
# 构建并安装 dev 版本
flutter build apk --flavor dev --release
adb install build/app/outputs/flutter-apk/app-dev-release.apk

# 或使用
flutter install --flavor dev
```

### iOS 打包

#### Dev 版本（测试用）

```bash
# 构建 iOS app
flutter build ios --flavor dev --release

# 使用 ios-deploy 安装到连接的 iPhone
ios-deploy --bundle build/ios/iphoneos/Runner.app --debug

# 或通过 Xcode
# 1. 打开 ios/Runner.xcworkspace
# 2. 选择 dev scheme
# 3. Product > Archive
```

#### Production 版本

```bash
# 构建生产版本
flutter build ios --flavor prod --release

# 通过 Xcode 发布
# 1. 打开 ios/Runner.xcworkspace
# 2. 选择 prod scheme
# 3. Product > Archive
# 4. Distribute App
```

#### 构建 IPA 文件

```bash
# 使用 Xcode 命令行
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme prod \
  -configuration Release \
  -archivePath build/ios/archive/Runner.xcarchive \
  archive

# 导出 IPA
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath build/ios/ipa \
  -exportOptionsPlist ios/ExportOptions.plist
```

### macOS Desktop 打包

```bash
# 构建 macOS 应用
flutter build macos --flavor dev --release

# 输出位置
# build/macos/Build/Products/Release/omi.app
```

---

## 常见问题

### 1. 环境变量没有生效

**问题**: 修改了 `.dev.env` 但应用中还是旧值

**解决方案**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter clean
flutter pub get
flutter run --flavor dev
```

### 2. 代码生成错误

**问题**: `build_runner` 执行失败

**解决方案**:
```bash
# 清理生成的文件
flutter clean
rm -rf .dart_tool/

# 重新获取依赖
flutter pub get

# 强制重新生成
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Flavor 构建失败

**问题**: `flutter build` 时 flavor 相关错误

**解决方案**:
- 确认 `lib/flavors.dart` 中的 flavor 配置正确
- 检查 `lib/env/` 目录下的环境文件
- 确认 Firebase 配置文件存在且正确
  - `lib/firebase_options_dev.dart`
  - `lib/firebase_options_prod.dart`

### 4. iOS 证书问题

**问题**: 构建时提示签名错误

**解决方案**:
1. 打开 Xcode
2. 选择 Runner target
3. Signing & Capabilities
4. 选择正确的 Team 和 Provisioning Profile
5. 确认 Bundle Identifier 正确

### 5. Android 依赖冲突

**问题**: Android 构建时依赖冲突

**解决方案**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --flavor dev --release
```

### 6. 查看详细构建日志

```bash
# 运行时显示详细日志
flutter run --flavor dev -v

# 构建时显示详细日志
flutter build apk --flavor dev --release -v

# 分析代码问题
flutter analyze

# 运行测试
flutter test
```

---

## 版本发布检查清单

### 发布前准备

- [ ] 更新版本号 (`pubspec.yaml` 中的 `version`)
- [ ] 更新 CHANGELOG
- [ ] 运行静态分析: `flutter analyze`
- [ ] 运行测试: `flutter test`
- [ ] 检查 `.prod.env` 配置正确
- [ ] 确认 Firebase 生产配置正确
- [ ] 生成最新代码: `flutter pub run build_runner build --delete-conflicting-outputs`

### Android 发布

- [ ] 构建 App Bundle: `flutter build appbundle --flavor prod --release`
- [ ] 测试安装包
- [ ] 准备 Google Play Store 截图和描述
- [ ] 上传到 Google Play Console

### iOS 发布

- [ ] 构建 Archive: `flutter build ios --flavor prod --release`
- [ ] 通过 Xcode Archive 导出
- [ ] TestFlight 内部测试
- [ ] 准备 App Store 截图和描述
- [ ] 提交到 App Store Connect

---

## 参考资源

- [Flutter 官方文档](https://flutter.dev/docs)
- [Flutter Flavors 配置](https://flutter.dev/docs/deployment/flavors)
- [构建和发布 iOS 应用](https://flutter.dev/docs/deployment/ios)
- [构建和发布 Android 应用](https://flutter.dev/docs/deployment/android)
- [DevTools 使用指南](https://docs.flutter.dev/tools/devtools)

---

## 快速命令参考

```bash
# 开发运行
flutter run --flavor dev

# 重新生成代码
flutter pub run build_runner build --delete-conflicting-outputs

# 更新配置后完整流程
flutter pub run build_runner build --delete-conflicting-outputs && flutter clean && flutter pub get && flutter run --flavor dev

# Android 打包
flutter build apk --flavor prod --release
flutter build appbundle --flavor prod --release

# iOS 打包
flutter build ios --flavor prod --release

# 代码分析
flutter analyze

# 运行测试
flutter test

# 清理构建
flutter clean
```
