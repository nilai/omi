# iOS 本地开发环境修改记录

> **注意**: 这些修改仅用于本地开发测试，不应提交到代码仓库。

## 修改日期
2024-12-13

## 修改原因
使用个人 Apple Developer 账号（Personal Team）在 iPad 上进行本地开发测试。

---

## 1. 开发团队设置 (DEVELOPMENT_TEAM)

**文件**: `ios/Runner.xcodeproj/project.pbxproj`

**修改内容**: 将 dev flavor 的 DEVELOPMENT_TEAM 从空值改为个人团队 ID

```
# 修改前
DEVELOPMENT_TEAM = "";

# 修改后
DEVELOPMENT_TEAM = 95R88GA6GP;
```

**影响的配置**:
- Debug-dev
- Profile-dev
- Release-dev
- 以及其他相关 targets

**恢复方法**:
```
将 DEVELOPMENT_TEAM = 95R88GA6GP; 改回 DEVELOPMENT_TEAM = "";
```

---

## 2. 禁用 Watch App

**文件**: `ios/Runner.xcodeproj/project.pbxproj`

**修改内容**: 移除了 omiWatchApp 的构建依赖

### 2.1 清空 Embed Watch Content 构建阶段
```
# 修改前
files = (
    42A7BA3E2E788BD400138969 /* omiWatchApp.app in Embed Watch Content */,
);

# 修改后
files = (
);
```

### 2.2 移除 Target 依赖
```
# 修改前
dependencies = (
    42A7BA3D2E788BD400138969 /* PBXTargetDependency */,
);

# 修改后
dependencies = (
);
```

**原因**: 本地未安装 watchOS SDK (需要 watchOS 26.1)

**恢复方法**:
1. 安装 watchOS SDK: Xcode > Settings > Platforms > 下载 watchOS
2. 或者恢复 project.pbxproj 中的 Watch app 依赖

---

## 3. 移除付费功能 Entitlements

**文件**:
- `ios/Runner/RunnerDebug-dev.entitlements`
- `ios/Runner/RunnerProfile-dev.entitlements`
- `ios/Runner/RunnerRelease-dev.entitlements`

**修改内容**: 移除了需要付费开发者账号的功能

### 原始内容:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>development</string>
    <key>com.apple.developer.applesignin</key>
    <array>
        <string>Default</string>
    </array>
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>applinks:h.omi.me</string>
        <string>applinks:try.omi.me</string>
    </array>
</dict>
</plist>
```

### 修改后:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
</dict>
</plist>
```

**被禁用的功能**:
| 功能 | Key | 影响 |
|-----|-----|-----|
| 推送通知 | `aps-environment` | 无法接收推送消息 |
| Apple 登录 | `com.apple.developer.applesignin` | 无法使用 Sign in with Apple |
| 深链接 | `com.apple.developer.associated-domains` | 无法通过 h.omi.me / try.omi.me 打开 App |

**恢复方法**: 将上述 XML 内容恢复到对应的 entitlements 文件中

---

## 4. 修改 Bundle Identifier

**文件**: `ios/Runner.xcodeproj/project.pbxproj`

**修改内容**: 修改 dev flavor 的 Bundle ID 以避免与公司团队注册的 ID 冲突

```
# 修改前
PRODUCT_BUNDLE_IDENTIFIER = "$(APP_BUNDLE_IDENTIFIER).development";

# 修改后
PRODUCT_BUNDLE_IDENTIFIER = "$(APP_BUNDLE_IDENTIFIER).nilai.dev";
```

**原因**: `com.friend-app-with-wearable.ios12.development` 已被公司团队注册，个人团队无法使用

**新的 Bundle ID**: `com.friend-app-with-wearable.ios12.nilai.dev`

**恢复方法**:
```
将 .nilai.dev 改回 .development
```

---

## 快速恢复所有修改

如果需要恢复到原始状态（例如提交代码前），执行以下操作：

```bash
# 方法 1: 使用 git 恢复
git checkout -- ios/Runner.xcodeproj/project.pbxproj
git checkout -- ios/Runner/RunnerDebug-dev.entitlements
git checkout -- ios/Runner/RunnerProfile-dev.entitlements
git checkout -- ios/Runner/RunnerRelease-dev.entitlements

# 方法 2: 恢复整个 ios 目录
git checkout -- ios/
```

---

## 账号信息

| 类型 | Team ID | 用途 |
|-----|---------|-----|
| 个人账号 (Personal Team) | 95R88GA6GP | 本地开发测试 |
| 公司账号 | 9536L8KLMP | 生产环境 / App Store |

---

## 注意事项

1. **不要提交这些修改到 Git**
2. 测试完成后记得恢复原始配置
3. 如需使用完整功能（推送、Apple 登录、深链接），需要使用公司开发者账号
4. 如需 Watch App 功能，需要安装 watchOS SDK
