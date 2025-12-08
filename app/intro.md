# Omi App - Comprehensive Project Analysis

## 1. 功能概述 (Functionality Overview)

### 1.1 核心功能 (Core Functions)

**设备连接与管理**
- 支持多种智能可穿戴设备的蓝牙连接（Omi、OpenGlass、Frame智能眼镜、Apple Watch、PLAUD、Bee、Fieldy、Friend Pendant、AI Note等）
- 实时设备状态监控（电池电量、固件版本、连接状态）
- 设备固件OTA更新
- 设备发现与配对管理

**音频捕获与处理**
- 多种音频编解码支持（PCM16、PCM8、Opus、AAC、LC3等）
- 实时音频流传输（通过BLE从设备到App）
- 麦克风录音（移动端）
- 系统音频捕获（桌面端 - macOS）
- 后台录音服务支持（Android/iOS）

**对话与记忆管理**
- 实时语音转文字（WebSocket实时转录）
- 对话自动分段与说话人识别
- 对话结构化提取（标题、摘要、关键词、行动项）
- 对话历史存储与检索
- 照片与对话关联（OpenGlass设备支持图像流）

**AI应用市场**
- 第三方应用集成（100+个应用）
- 应用安装、配置、评分与评论
- 应用触发（基于对话内容自动或手动触发）
- 应用结果展示与管理

**智能助手与聊天**
- AI对话（基于对话历史的智能问答）
- 多轮对话支持
- 上下文感知回复

**任务管理集成**
- 与主流任务管理工具集成（Todoist、Asana、Google Tasks、ClickUp、Apple Reminders）
- OAuth认证流程
- 自动创建任务项

**用户体验**
- 多平台支持（iOS、Android、macOS、Windows、Web）
- 黑暗主题UI设计
- 响应式布局（移动端/桌面端自适应）
- 深度链接支持（应用内跳转）
- 推送通知（Firebase Cloud Messaging）

### 1.2 高级功能

**语音配置文件**
- 用户语音样本采集
- 说话人识别训练
- 多人对话区分

**订阅与付费**
- Stripe支付集成
- 订阅状态管理
- 使用量追踪（防止超额使用）

**数据同步**
- Write-Ahead Log (WAL) 机制保证数据可靠性
- 离线缓存支持
- 网络状态自动重连

**开发者模式**
- API密钥管理（OpenAI、Deepgram等）
- MCP (Model Context Protocol) 支持
- 调试日志导出

**分析与监控**
- Mixpanel用户行为分析
- Firebase Crashlytics崩溃报告
- GrowthBook特性开关与A/B测试
- Intercom客户支持集成

---

## 2. 业务流程 (Workflows)

### 2.1 用户注册与登录流程

```
用户启动App
    ↓
检查认证状态 (AuthenticationProvider)
    ↓
未认证 → 设备选择页面 (DeviceSelectionPage)
    ↓
选择设备类型或无设备
    ↓
Firebase认证 (Google登录/Apple登录)
    ↓
创建Persona (个人资料)
    ↓
完成引导 (OnboardingWrapper)
    ↓
进入主页 (HomePageWrapper)
```

### 2.2 设备连接流程

```
扫描蓝牙设备 (DeviceService)
    ↓
识别设备类型 (BtDevice.fromScanResult)
    ↓
创建对应的设备连接 (DeviceConnectionFactory)
    ├─ OmiDeviceConnection (Omi/OpenGlass)
    ├─ FrameDeviceConnection (Frame眼镜)
    ├─ AppleWatchConnection (Apple Watch)
    └─ PlaudDeviceConnection 等
    ↓
建立BLE连接/Watch Connectivity连接
    ↓
订阅设备特征（音频流、电池、设备信息等）
    ↓
更新设备状态 (DeviceProvider)
    ↓
持久化连接信息 (SharedPreferences)
```

### 2.3 对话捕获与处理流程

```
设备开始音频采集
    ↓
音频数据通过BLE传输到App (CaptureProvider)
    ↓
[可选] 音频解码 (Opus → PCM)
    ↓
WebSocket连接到转录服务 (TranscriptSegmentSocketService)
    ↓
实时接收转录片段 (TranscriptSegment)
    ├─ 文本内容
    ├─ 时间戳
    ├─ 说话人ID
    └─ 是否为句子结束
    ↓
聚合转录片段
    ↓
对话结束检测（静音时长 > 阈值）
    ↓
发送到后端处理 (POST /v1/conversations)
    ↓
后端返回结构化数据
    ├─ 对话摘要
    ├─ 标题
    ├─ 行动项
    ├─ 关键词
    └─ 情感分析
    ↓
触发相关应用 (AppProvider)
    ↓
保存到本地数据库 (WAL + SharedPreferences)
    ↓
UI更新显示 (ConversationProvider)
```

### 2.4 AI应用触发流程

```
对话完成处理
    ↓
检查已安装应用的触发条件
    ↓
匹配应用触发器（关键词、主题等）
    ↓
调用应用外部集成API
    ├─ Webhook通知
    └─ 参数传递（对话内容、转录文本等）
    ↓
接收应用响应
    ↓
创建ServerMessage展示结果
    ↓
推送通知（如果需要）
```

### 2.5 任务集成工作流（以Todoist为例）

```
用户点击"连接Todoist"
    ↓
打开OAuth授权URL (浏览器/WebView)
    ↓
用户授权
    ↓
重定向回App (Deep Link: omi://todoist/callback)
    ↓
AppShell处理Deep Link
    ↓
TodoistService.handleCallback()
    ↓
从Firebase获取访问令牌
    ↓
更新本地状态
    ↓
TaskIntegrationProvider.refresh()
    ↓
显示成功通知
```

---

## 3. 模块架构 (Module Architecture)

### 3.1 分层架构

```
┌─────────────────────────────────────────┐
│         UI Layer (Presentation)          │
│   - pages/                               │
│   - widgets/                             │
│   - ui/atoms, molecules, organisms       │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│      State Management (Provider)         │
│   - providers/*_provider.dart            │
│   - BaseProvider扩展                      │
│   - ChangeNotifier通知UI更新              │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│        Services Layer (Business)         │
│   - services/devices/                    │
│   - services/sockets/                    │
│   - services/auth_service.dart           │
│   - services/notifications.dart          │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│         Backend Layer (Data)             │
│   - backend/http/ (API客户端)            │
│   - backend/schema/ (数据模型)            │
│   - backend/preferences.dart (本地存储)   │
└─────────────────────────────────────────┘
```

### 3.2 核心模块详解

#### **Providers模块** (`lib/providers/`)

| Provider | 职责 |
|----------|------|
| `AuthenticationProvider` | 用户认证状态管理、Firebase登录/登出 |
| `DeviceProvider` | 设备连接状态、蓝牙管理、固件更新 |
| `CaptureProvider` | 音频捕获、实时转录、对话录制 |
| `ConversationProvider` | 对话历史管理、CRUD操作 |
| `AppProvider` | 应用市场、应用安装/配置 |
| `MessageProvider` | AI聊天消息、对话历史 |
| `MemoriesProvider` | 记忆管理（旧版对话系统） |
| `HomeProvider` | 主页状态、用户偏好 |
| `OnboardingProvider` | 引导流程状态 |
| `SpeechProfileProvider` | 语音配置文件管理 |
| `UsageProvider` | 订阅状态、使用量追踪 |
| `TaskIntegrationProvider` | 任务管理工具集成状态 |
| `NoteDeviceProvider` | AI Note设备专用 |
| `NoteOtaProvider` | AI Note OTA更新 |

#### **Services模块** (`lib/services/`)

**设备服务** (`services/devices/`)
- `DeviceService`: 设备管理核心服务（单例）
- `DeviceConnectionFactory`: 根据设备类型创建连接
- 设备特定连接：
  - `OmiDeviceConnection`
  - `FrameDeviceConnection`
  - `AppleWatchDeviceConnection`
  - `PlaudDeviceConnection`
  - `NoteConnection`
  - 等等
- Transport抽象层：
  - `BleTransport` (蓝牙低功耗)
  - `WatchTransport` (Apple Watch连接)
  - `FrameTransport` (Frame SDK)

**Socket服务** (`services/sockets/`)
- `TranscriptSegmentSocketService`: 实时转录WebSocket
- `WalSocketService`: Write-Ahead Log同步
- `PureSocketService`: 通用WebSocket封装

**其他服务**
- `AuthService`: Firebase认证、令牌管理
- `NotificationService`: 推送通知管理
- `ConnectivityService`: 网络状态监听
- `ServiceManager`: 服务生命周期管理（单例）

#### **Backend模块** (`lib/backend/`)

**HTTP API** (`backend/http/`)
- `shared.dart`: HTTP客户端封装、请求头构建、认证管理
- `api/conversations.dart`: 对话相关API
- `api/device.dart`: 设备相关API
- `api/apps.dart`: 应用市场API

**数据模型** (`backend/schema/`)
- `BtDevice`: 蓝牙设备模型
- `ServerConversation`: 对话数据模型
- `ServerMessage`: 消息模型
- `App`: 应用模型
- `TranscriptSegment`: 转录片段
- `ActionItem`: 行动项
- `Person`: 人物模型

**本地存储** (`backend/preferences.dart`)
- `SharedPreferencesUtil`: SharedPreferences封装
- 存储用户设置、设备信息、缓存数据

#### **UI模块** (`lib/pages/`)

| 功能区 | 页面 |
|--------|------|
| **主页** | `home/page.dart` - 主页面、对话列表 |
| **对话** | `conversations/` - 对话列表、详情、播放 |
| **捕获** | `capture/` - 实时捕获页面 |
| **应用** | `apps/` - 应用市场、应用详情、评论 |
| **聊天** | `chat/` - AI聊天界面 |
| **设置** | `settings/` - 各种设置页面（20+个） |
| **引导** | `onboarding/` - 用户引导流程 |
| **支付** | `payments/` - 订阅管理 |
| **语音** | `speech_profile/` - 语音配置 |

### 3.3 跨平台架构

```
AppShell (lib/core/app_shell.dart)
    ↓
LayoutBuilder (响应式判断)
    ├─ width >= 1100 → DesktopApp
    │       ↓
    │   DesktopHomePageWrapper
    │
    └─ width < 1100 → MobileApp
            ↓
        HomePageWrapper / OnboardingWrapper
```

### 3.4 数据流架构

**单向数据流**
```
User Action → Provider (notifyListeners) → Widget Rebuild
     ↑                                           ↓
     └──────────── UI Event ←────────────────────┘
```

**网络数据流**
```
API Call → HTTP Response → Model Parse → Provider Update → UI
                                ↓
                         Cache (SharedPreferences)
```

**实时数据流**
```
Device → BLE/WebSocket → Service → Provider → UI
                              ↓
                        WAL Service (持久化)
```

### 3.5 依赖注入模式

```dart
// main.dart中的MultiProvider
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
    ChangeNotifierProvider(create: (_) => DeviceProvider()),
    ChangeNotifierProvider(create: (_) => CaptureProvider()),
    // ... 20+ providers
  ],
  child: MaterialApp(...)
)

// Provider依赖关系
ChangeNotifierProxyProvider<DeviceProvider, OnboardingProvider>(
  create: (_) => OnboardingProvider(),
  update: (_, device, previous) => 
    (previous?..setDeviceProvider(device)) ?? OnboardingProvider(),
)
```

---

## 4. 技术栈总结

**前端框架**: Flutter 3.0+  
**状态管理**: Provider模式  
**网络通信**: HTTP (http package) + WebSocket (web_socket_channel)  
**蓝牙**: flutter_blue_plus + flutter_reactive_ble  
**音频**: flutter_sound + opus_flutter + just_audio  
**认证**: Firebase Auth (Google/Apple登录)  
**推送**: Firebase Messaging  
**分析**: Mixpanel + Firebase Crashlytics + GrowthBook  
**支付**: Stripe  
**持久化**: SharedPreferences + WAL机制  
**深度链接**: app_links  
**平台通道**: MethodChannel (用于原生集成)

---

## 5. 项目总结

这个项目是一个功能全面的智能可穿戴设备伴侣应用，采用了清晰的分层架构和模块化设计，支持多平台、多设备，具有实时音频处理、AI应用生态和完整的用户体验流程。

### 关键特点

1. **多设备支持**: 通过抽象的设备连接层支持10+种不同的智能可穿戴设备
2. **实时音频处理**: 完整的音频采集→传输→转录→处理流程
3. **可扩展的应用生态**: 100+第三方应用集成
4. **跨平台架构**: 单一代码库支持iOS、Android、macOS、Windows、Web
5. **完善的状态管理**: 基于Provider的清晰状态管理模式
6. **可靠的数据同步**: WAL机制保证数据一致性
7. **完整的分析体系**: Mixpanel + Crashlytics + GrowthBook

### 技术亮点

- **设备抽象层**: DeviceConnection接口 + Transport层实现了设备通信的完全解耦
- **实时通信**: WebSocket实现低延迟的语音转文字
- **后台服务**: Android/iOS后台录音服务保证持续捕获
- **深度链接**: 完善的Deep Link处理支持OAuth回调和应用内导航
- **响应式设计**: 基于LayoutBuilder的移动端/桌面端自适应
