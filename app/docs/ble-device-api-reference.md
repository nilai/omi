# BLE 设备与 API 快速参考文档

> 本文档提供 Omi 应用中 BLE 设备相关页面、网络接口和数据模型的文件位置快速索引，便于开发者快速定位和修改。

---

## 📋 目录

1. [BLE 设备页面清单](#ble-设备页面清单)
2. [网络接口文件清单](#网络接口文件清单)
3. [数据模型文件清单](#数据模型文件清单)
4. [快速修改指南](#快速修改指南)
5. [文件速查表](#文件速查表)

---

## 📱 BLE 设备页面清单

### 1. 主页（设备连接中心）

主页是设备连接和管理的核心界面。

| 文件路径 | 功能说明 |
|---------|---------|
| `lib/pages/home/page.dart` | 主页入口，集成设备连接、对话、聊天、记忆等功能 |
| `lib/pages/home/device.dart` | **已连接设备显示组件** (ConnectedDevice) |
| `lib/pages/home/firmware_update.dart` | 固件更新页面 |
| `lib/pages/home/firmware_update_dialog.dart` | 固件更新对话框 |
| `lib/pages/home/firmware_mixin.dart` | 固件相关的 mixin 逻辑 |

**辅助组件**：
- `lib/pages/home/widgets/battery_info_widget.dart` - 设备电池信息显示
- `lib/pages/home/widgets/chat_apps_dropdown_widget.dart` - 聊天应用下拉选择
- `lib/pages/home/widgets/out_of_credits_widget.dart` - 积分不足提示

### 2. 设备发现与配对页面

负责扫描和连接 BLE 设备的页面。

| 文件路径 | 功能说明 |
|---------|---------|
| `lib/pages/onboarding/find_device/page.dart` | **查找设备页面** (FindDevicesPage) - 扫描附近的 BLE 设备 |
| `lib/pages/onboarding/find_device/found_devices.dart` | **已发现设备列表组件** (FoundDevices) - 显示扫描结果并处理连接 |
| `lib/pages/onboarding/device_selection.dart` | 设备选择页面 |
| `lib/pages/onboarding/device_onboarding/device_onboarding_page.dart` | 设备引导页面 |
| `lib/pages/onboarding/device_onboarding/device_onboarding_wrapper.dart` | 设备引导包装器 |

### 3. 设备设置与管理

设备参数配置和连接管理页面。

| 文件路径 | 功能说明 |
|---------|---------|
| `lib/pages/settings/device_settings.dart` | **设备设置页面** (DeviceSettings) - 设备亮度、麦克风增益等配置 |
| `lib/pages/capture/connect.dart` | **连接设备页面** (ConnectDevicePage) - 手动连接设备 |

---

## 🌐 网络接口文件清单

### 核心 HTTP 客户端

| 文件路径 | 功能说明 |
|---------|---------|
| `lib/backend/http/shared.dart` | **HTTP 客户端核心** - 所有 API 调用的基础 |

**核心方法**：
- `makeApiCall()` - 统一的 API 调用方法
- `buildHeaders()` - 自动添加认证 Token
- 支持自动 Token 刷新（5分钟缓冲期）

### API 端点文件列表

所有 API 接口定义位于 `lib/backend/http/api/` 目录下：

| 文件名 | 主要功能 | 关键接口 |
|--------|---------|---------|
| `device.dart` | 设备相关 API | 获取最新固件版本 |
| `conversations.dart` | 对话管理 API | `processInProgressConversation()`, `getConversations()`, `deleteConversationServer()`, `updateConversationTitle()` |
| `memories.dart` | 记忆管理 API | `createMemoryServer()`, `updateMemoryVisibilityServer()` |
| `messages.dart` | 消息管理 API | `getMessagesServer()` - 获取消息列表 |
| `apps.dart` | 应用市场 API | `retrieveAppsGrouped()` - 获取分组应用列表 |
| `users.dart` | 用户信息 API | 用户资料管理 |
| `action_items.dart` | 行动项 API | 行动项管理 |
| `notifications.dart` | 通知 API | 推送通知管理 |
| `payment.dart` / `payments.dart` | 支付 API | 订阅和支付管理 |
| `privacy.dart` | 隐私设置 API | 隐私选项配置 |
| `speech_profile.dart` | 语音配置 API | 语音识别配置 |
| `dev_api.dart` | 开发者 API | API 密钥管理 |
| `mcp_api.dart` | MCP API | MCP 密钥管理 |

### API 调用示例

```dart
// 标准 API 调用模式
Future<List<Memory>> getMemories({int limit = 100, int offset = 0}) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}v3/memories?limit=$limit&offset=$offset',
    method: 'GET',
    headers: {},
    body: '',
  );

  if (response == null) return [];
  List<dynamic> data = json.decode(response.body);
  return data.map((item) => Memory.fromJson(item)).toList();
}
```

---

## 📊 数据模型文件清单

### 核心数据模型

所有数据模型定义位于 `lib/backend/schema/` 目录下：

| 文件路径 | 模型类名 | 功能说明 |
|---------|---------|---------|
| `bt_device/bt_device.dart` | **BtDevice** | BLE 设备核心数据模型 |
| `bt_device/note_device.dart` | **NoteDevice** | Note 设备数据模型 |
| `conversation.dart` | **ServerConversation** | 对话数据模型 |
| `memory.dart` | **Memory** | 记忆数据模型 |
| `app.dart` | **App** | 应用数据模型 |
| `message.dart` | **ServerMessage** | 消息数据模型 |
| `message_event.dart` | MessageEvent 相关 | 消息事件模型 |
| `transcript_segment.dart` | **TranscriptSegment** | 转录片段模型 |
| `geolocation.dart` | Geolocation | 地理位置模型 |
| `person.dart` | **Person** | 人物数据模型 |
| `action_item.dart` | **ActionItem** | 行动项模型 |
| `structured.dart` | Structured | 结构化数据模型 |
| `dev_api_key.dart` | **DevApiKey** | 开发者 API 密钥模型 |
| `mcp_api_key.dart` | **McpApiKey** | MCP API 密钥模型 |
| `schema.dart` | - | **统一导出文件** |

### 重要枚举类型

#### BtDevice 相关枚举 (`bt_device/bt_device.dart`)

```dart
// 音频编解码器类型
enum BleAudioCodec {
  pcm8,    // 8-bit PCM，低质量，低带宽
  pcm16,   // 16-bit PCM，高质量，高带宽
  mulaw8,  // μ-law 压缩，电话质量
  opus,    // Opus 编码，高质量，可变比特率
  aac,     // AAC 编码，移动设备友好
}

// 设备类型
enum DeviceType {
  omi,         // Omi 设备
  frame,       // Frame 智能眼镜
  appleWatch,  // Apple Watch
  xor,         // XOR 设备
  bee,         // Bee 设备
  fieldy,      // Fieldy 设备
  openglass,   // OpenGlass 设备
}

// 图像方向
enum ImageOrientation {
  landscape,
  portrait,
}
```

#### Conversation 相关枚举 (`conversation.dart`)

```dart
// 对话来源
enum ConversationSource {
  friend,      // 朋友对话
  omi,         // Omi 设备
  workflow,    // 工作流
  openglass,   // OpenGlass
  screenpipe,  // Screenpipe
  sdcard,      // SD 卡
}

// 对话状态
enum ConversationStatus {
  in_progress,  // 进行中
  processing,   // 处理中
  completed,    // 已完成
  failed,       // 失败
}
```

#### Memory 相关枚举 (`memory.dart`)

```dart
// 记忆分类
enum MemoryCategory {
  interesting,  // 有趣的
  system,       // 系统
}

// 记忆可见性
enum MemoryVisibility {
  private,  // 私有
  public,   // 公开
}
```

### 数据模型特点

1. **JSON 序列化**
   - 使用 `json_serializable` 自动生成序列化代码
   - 每个模型都有对应的 `.g.dart` 生成文件
   - 需要运行 `build_runner` 重新生成

2. **模型关系**
   - `BtDevice` → 设备连接的核心模型
   - `ServerConversation` → 包含 `ConversationPhoto` 列表
   - `App` → 包含 `AppReview` 和 `AuthStep`

---

## 🔧 快速修改指南

### 修改网络接口

#### 1. 添加新的 API 端点

**步骤**：
1. 在 `lib/backend/http/api/` 下创建或编辑对应的 API 文件
2. 使用 `makeApiCall()` 构建请求
3. 处理响应并转换为数据模型

**示例**：
```dart
// lib/backend/http/api/new_feature.dart
import '../shared.dart';
import '../../schema/new_feature.dart';

Future<List<NewFeature>> getNewFeatures() async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}v3/new-features',
    method: 'GET',
    headers: {},
    body: '',
  );

  if (response == null) return [];
  List<dynamic> data = json.decode(response.body);
  return data.map((item) => NewFeature.fromJson(item)).toList();
}
```

#### 2. 修改 HTTP 客户端配置

**文件位置**: `lib/backend/http/shared.dart`

可修改内容：
- 请求超时时间
- 错误处理逻辑
- 认证头构建方式
- API 版本号

### 修改数据模型

#### 1. 修改现有模型

**步骤**：
1. 编辑 `lib/backend/schema/` 下的模型文件
2. 更新类属性
3. 更新 `fromJson()` 和 `toJson()` 方法（如果手动编写）
4. 运行代码生成命令

**代码生成命令**：
```bash
# 生成 JSON 序列化代码
flutter pub run build_runner build --delete-conflicting-outputs

# 监听模式（自动重新生成）
flutter pub run build_runner watch --delete-conflicting-outputs
```

#### 2. 添加新数据模型

**步骤**：
1. 在 `lib/backend/schema/` 创建新的模型文件
2. 定义类并添加 `@JsonSerializable()` 注解
3. 实现 `fromJson()` 和 `toJson()` 方法
4. 在 `schema.dart` 中导出新模型
5. 运行 `build_runner` 生成代码

**模板**：
```dart
import 'package:json_annotation/json_annotation.dart';

part 'new_model.g.dart';

@JsonSerializable()
class NewModel {
  final String id;
  final String name;

  NewModel({
    required this.id,
    required this.name,
  });

  factory NewModel.fromJson(Map<String, dynamic> json) =>
      _$NewModelFromJson(json);

  Map<String, dynamic> toJson() => _$NewModelToJson(this);
}
```

#### 3. 更新使用该模型的代码

需要同步更新的位置：
- **Provider** (`lib/providers/`) - 状态管理类
- **API 调用** (`lib/backend/http/api/`) - 接口调用
- **UI 组件** (`lib/pages/`, `lib/widgets/`) - 界面显示

---

## 📑 文件速查表

### 核心文件快速索引

| 功能类别 | 文件路径 | 关键说明 |
|---------|---------|---------|
| **BLE 扫描页面** | `lib/pages/onboarding/find_device/page.dart` | 查找并连接 BLE 设备 |
| **已连接设备** | `lib/pages/home/device.dart` | 显示当前连接的设备状态 |
| **设备设置** | `lib/pages/settings/device_settings.dart` | 设备参数配置界面 |
| **HTTP 客户端** | `lib/backend/http/shared.dart` | 网络请求核心，认证管理 |
| **BLE 设备模型** | `lib/backend/schema/bt_device/bt_device.dart` | 设备数据结构，编解码器定义 |
| **设备 API** | `lib/backend/http/api/device.dart` | 设备相关接口（固件等） |
| **对话 API** | `lib/backend/http/api/conversations.dart` | 对话管理接口 |
| **记忆 API** | `lib/backend/http/api/memories.dart` | 记忆管理接口 |
| **应用 API** | `lib/backend/http/api/apps.dart` | 应用市场接口 |

### 设备连接相关文件

| 层级 | 文件路径 | 说明 |
|------|---------|------|
| **UI 层** | `lib/pages/home/device.dart` | 已连接设备 UI |
| **Provider 层** | `lib/providers/device_provider.dart` | 设备连接状态管理 |
| **Service 层** | `lib/services/devices/device_connection.dart` | 设备连接工厂 |
| **Transport 层** | `lib/services/devices/transports/ble_transport.dart` | BLE 传输实现 |
| **数据模型层** | `lib/backend/schema/bt_device/bt_device.dart` | BLE 设备数据模型 |

### 常用开发命令

```bash
# 开发环境运行
flutter run --flavor dev

# 生产环境运行
flutter run --flavor prod

# 生成代码（JSON 序列化等）
flutter pub run build_runner build --delete-conflicting-outputs

# 静态分析
flutter analyze

# 运行测试
flutter test
```

---

## 📝 附录

### A. 架构参考

详细的架构分析请参考：[`omi-architecture-analysis-cn.md`](./omi-architecture-analysis-cn.md)

### B. 相关文档

- 项目说明：`README.md`
- Claude Code 指南：`CLAUDE.md`
- 环境配置：`lib/env/dev_env.dart`, `lib/env/prod_env.dart`

### C. 目录结构速览

```
lib/
├── backend/
│   ├── http/
│   │   ├── shared.dart         # HTTP 客户端核心
│   │   └── api/                # API 端点定义
│   │       ├── device.dart
│   │       ├── conversations.dart
│   │       ├── memories.dart
│   │       └── ...
│   └── schema/                 # 数据模型
│       ├── bt_device/
│       │   └── bt_device.dart
│       ├── conversation.dart
│       ├── memory.dart
│       └── ...
├── pages/
│   ├── home/                   # 主页（设备连接中心）
│   │   ├── page.dart
│   │   └── device.dart
│   ├── onboarding/
│   │   └── find_device/        # BLE 设备扫描
│   │       └── page.dart
│   └── settings/
│       └── device_settings.dart # 设备设置
├── providers/                  # 状态管理
│   └── device_provider.dart
└── services/                   # 服务层
    └── devices/
        ├── device_connection.dart
        └── transports/
            └── ble_transport.dart
```

---

**文档版本**: v1.0
**创建日期**: 2025-01-09
**基于代码库**: Omi App (commit: 42d3bb502)
**维护说明**: 本文档应随代码库更新同步维护

---

**© 2025 Omi Project. 本文档用于开发团队快速参考。**
