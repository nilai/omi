# Omi App 架构分析文档

> 本文档基于对 Omi 应用代码库的深度分析，系统性地梳理了项目的目录结构、数据流和核心架构设计。

---

## 📋 目录

1. [项目概述](#项目概述)
2. [目录结构详解](#目录结构详解)
3. [核心架构层次](#核心架构层次)
4. [数据流分析](#数据流分析)
5. [设计模式与最佳实践](#设计模式与最佳实践)
6. [关键技术组件](#关键技术组件)
7. [应用初始化流程](#应用初始化流程)
8. [第三方集成](#第三方集成)
9. [开发建议](#开发建议)

---

## 1. 项目概述

### 1.1 应用简介

Omi 是一个基于 Flutter 开发的跨平台移动应用，作为 Omi 可穿戴设备的配套应用。应用的核心功能包括：

- **设备管理**：连接和管理多种可穿戴设备（Omi、Frame 智能眼镜、Apple Watch、XOR 等）
- **实时转录**：通过蓝牙或其他传输协议实时接收音频数据并进行转录
- **对话记录**：捕获、存储和管理用户的对话记忆
- **AI 应用市场**：浏览、安装和管理各类 AI 应用插件
- **多平台支持**：iOS、Android、macOS、Windows、Linux 和 Web

### 1.2 技术栈概览

**核心框架与语言**
- Flutter 3.x（Dart）
- 支持多平台部署（移动端、桌面端、Web）

**状态管理**
- Provider 模式
- ChangeNotifier 观察者模式

**网络通信**
- HTTP REST API（用于后端数据交互）
- WebSocket（用于实时转录和消息推送）
- BLE（蓝牙低功耗，用于设备连接）

**音频处理**
- flutter_sound（麦克风录音）
- Opus 编解码器（音频压缩）
- 支持多种音频格式：PCM16、PCM8、MuLaw、Opus、AAC

**第三方服务集成**
- Firebase（Auth、Messaging、Crashlytics）
- Mixpanel（用户行为分析）
- GrowthBook（特征标志和 A/B 测试）
- Intercom（用户支持和客服）

**设备通信**
- flutter_blue_plus（BLE 通信）
- frame_sdk（Frame 智能眼镜集成）
- Apple Watch Connectivity（watchOS 集成）

---

## 2. 目录结构详解

### 2.1 项目顶层结构

```
omi/app/
├── android/          # Android 原生代码和配置
├── ios/              # iOS 原生代码和配置
├── macos/            # macOS 桌面应用配置
├── linux/            # Linux 桌面应用配置
├── windows/          # Windows 桌面应用配置
├── web/              # Web 应用资源
├── lib/              # 核心 Flutter 代码（主要开发目录）
├── assets/           # 静态资源（图片、字体等）
├── docs/             # 项目文档
├── scripts/          # 构建和部署脚本
├── setup/            # 环境配置脚本
├── pubspec.yaml      # Flutter 依赖配置
├── CLAUDE.md         # Claude Code 项目指南
└── README.md         # 项目说明文档
```

### 2.2 lib/ 核心代码结构

`lib/` 目录是应用的核心代码库，采用清晰的分层架构：

```
lib/
├── main.dart                 # 应用入口，初始化流程
├── flavors.dart             # 环境配置（dev/prod）
├── watch_interface.dart     # Watch 通信接口
│
├── backend/                 # 后端交互层
│   ├── http/               # HTTP 客户端和 API
│   │   ├── api/           # RESTful API 端点
│   │   │   ├── apps.dart
│   │   │   ├── memories.dart
│   │   │   ├── conversations.dart
│   │   │   ├── messages.dart
│   │   │   └── ...
│   │   ├── shared.dart    # HTTP 客户端核心（认证、请求构建）
│   │   └── openai.dart    # OpenAI API 集成
│   ├── schema/            # 数据模型定义
│   │   ├── memory.dart
│   │   ├── conversation.dart
│   │   ├── app.dart
│   │   ├── message.dart
│   │   ├── bt_device/      # 蓝牙设备相关模型
│   │   └── ...
│   └── preferences.dart    # 本地存储（SharedPreferences 封装）
│
├── services/               # 服务层（业务逻辑）
│   ├── devices/           # 设备连接服务
│   │   ├── device_connection.dart      # 设备连接工厂和抽象
│   │   ├── omi_connection.dart        # Omi 设备连接实现
│   │   ├── frame_connection.dart      # Frame 眼镜连接实现
│   │   ├── apple_watch_connection.dart # Apple Watch 连接实现
│   │   ├── xor_connection.dart        # XOR 设备连接实现
│   │   ├── bee_connection.dart        # Bee 设备连接实现
│   │   ├── fieldy_connection.dart     # Fieldy 设备连接实现
│   │   ├── transports/               # 传输层抽象
│   │   │   ├── device_transport.dart  # 传输接口定义
│   │   │   ├── ble_transport.dart     # 蓝牙传输实现
│   │   │   ├── watch_transport.dart   # Watch 传输实现
│   │   │   └── frame_transport.dart   # Frame 传输实现
│   │   └── discovery/                # 设备发现
│   │       ├── device_locator.dart
│   │       ├── bluetooth_discoverer.dart
│   │       └── apple_watch_discoverer.dart
│   ├── sockets/           # WebSocket 服务
│   │   ├── transcription_connection.dart  # 实时转录 WebSocket
│   │   ├── wal_connection.dart           # WAL 同步 WebSocket
│   │   └── pure_socket.dart              # WebSocket 基础封装
│   ├── notifications/      # 通知服务
│   ├── auth_service.dart   # Firebase 认证服务
│   ├── wals.dart          # Write-Ahead Log 服务
│   └── services.dart      # 服务管理器（ServiceManager）
│
├── providers/              # 状态管理层（Provider 模式）
│   ├── base_provider.dart          # 所有 Provider 的基类
│   ├── app_provider.dart           # 应用市场状态管理
│   ├── auth_provider.dart          # 认证状态管理
│   ├── device_provider.dart        # 设备连接状态管理
│   ├── memories_provider.dart      # 记忆/对话状态管理
│   ├── capture_provider.dart       # 录音捕获状态管理
│   ├── conversation_provider.dart  # 对话处理状态管理
│   ├── message_provider.dart       # 消息状态管理
│   ├── home_provider.dart          # 主页状态管理
│   └── ...
│
├── pages/                  # UI 页面层（按功能模块组织）
│   ├── apps/              # 应用市场相关页面
│   ├── capture/           # 音频捕获页面
│   ├── chat/              # 聊天对话页面
│   ├── conversations/     # 对话列表页面
│   ├── memories/          # 记忆管理页面
│   ├── home/              # 主页（设备连接）
│   ├── onboarding/        # 用户引导流程
│   ├── settings/          # 设置页面
│   ├── persona/           # 角色管理页面
│   ├── payments/          # 支付相关页面
│   └── ...
│
├── widgets/               # 可复用 UI 组件
│   ├── device_widget.dart
│   ├── transcript.dart
│   ├── conversation_bottom_bar/
│   └── ...
│
├── ui/                    # 原子设计系统组件
│   ├── atoms/            # 原子组件（最小单位）
│   │   ├── omi_button.dart
│   │   ├── omi_text_input.dart
│   │   ├── omi_avatar.dart
│   │   └── ...
│   ├── molecules/        # 分子组件（组合原子）
│   │   ├── omi_chat_bubble.dart
│   │   ├── omi_confirm_dialog.dart
│   │   └── ...
│   └── organisms/        # 有机体组件（复杂功能模块）
│       ├── memory_review_sheet.dart
│       ├── action_item.dart
│       └── ...
│
├── models/                # 业务数据模型
│   ├── subscription.dart
│   ├── user_usage.dart
│   ├── sync_state.dart
│   └── playback_state.dart
│
├── utils/                 # 工具类和辅助函数
│   ├── analytics/        # 分析工具（Mixpanel、GrowthBook、Intercom）
│   ├── audio/            # 音频处理工具
│   ├── bluetooth/        # 蓝牙相关工具
│   ├── debugging/        # 调试和崩溃报告
│   ├── platform/         # 平台适配工具
│   └── ...
│
├── core/                  # 核心应用组件
│   └── app_shell.dart    # 应用外壳（路由、深度链接）
│
├── mobile/               # 移动端特定代码
│   └── mobile_app.dart
│
├── desktop/              # 桌面端特定代码
│   └── desktop_app.dart
│
├── env/                  # 环境配置
│   ├── env.dart
│   ├── dev_env.dart      # 开发环境配置
│   └── prod_env.dart     # 生产环境配置
│
└── gen/                  # 代码生成文件
    ├── assets.gen.dart
    └── fonts.gen.dart
```

### 2.3 目录组织原则

1. **按功能分层**：backend、services、providers、pages 清晰分离职责
2. **按领域模块化**：pages/ 下按功能模块（apps、capture、chat 等）组织
3. **原子设计系统**：ui/ 采用 atoms → molecules → organisms 的组件层次
4. **平台隔离**：mobile/、desktop/ 分别处理平台特定逻辑
5. **代码生成分离**：生成的代码统一放在 gen/ 目录

---

## 3. 核心架构层次

Omi 应用采用经典的**四层架构**设计，从上到下依次为：

### 3.1 架构层次图

```
┌─────────────────────────────────────────────────────────┐
│                    UI 层 (Presentation)                  │
│         pages/ + widgets/ + ui/                         │
│                                                           │
└───────────────────────┬───────────────────────────────────┘
                        │ Consumer<Provider>
                        ↓
┌─────────────────────────────────────────────────────────┐
│               状态管理层 (State Management)                │
│                   providers/                             │
│         BaseProvider → ChangeNotifier → UI              │
└───────────────────────┬───────────────────────────────────┘
                        │ 调用服务接口
                        ↓
┌─────────────────────────────────────────────────────────┐
│                  服务层 (Business Logic)                  │
│                     services/                            │
│    DeviceService | SocketService | WalService           │
└───────────────────────┬───────────────────────────────────┘
                        │ HTTP/WebSocket/BLE
                        ↓
┌─────────────────────────────────────────────────────────┐
│                  数据层 (Data Layer)                      │
│                     backend/                             │
│        HTTP Client | Schema Models | Preferences        │
└───────────────────────┬───────────────────────────────────┘
                        │
                        ↓
              外部系统（后端 API、设备、存储）
```

### 3.2 各层职责详解

#### 3.2.1 UI 层（lib/pages、lib/widgets、lib/ui）

**职责**：
- 展示数据和接收用户输入
- 响应用户交互（按钮点击、表单提交等）
- 通过 Provider 消费状态数据
- 不包含业务逻辑，只负责视图渲染

**关键设计**：
- 采用**原子设计系统**（Atomic Design）组织 UI 组件
- 使用 `Consumer<ProviderType>` 或 `context.watch<ProviderType>()` 监听状态变化
- 页面组件放在 `pages/`，可复用组件放在 `widgets/` 和 `ui/`

**示例代码**：
```dart
// pages/memories/page.dart
class MemoriesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MemoriesProvider>(
      builder: (context, provider, child) {
        if (provider.loading) {
          return CircularProgressIndicator();
        }
        return ListView.builder(
          itemCount: provider.filteredMemories.length,
          itemBuilder: (context, index) {
            return MemoryCard(memory: provider.filteredMemories[index]);
          },
        );
      },
    );
  }
}
```

#### 3.2.2 状态管理层（lib/providers）

**职责**：
- 管理应用状态（加载状态、数据缓存、用户输入）
- 调用服务层接口获取/修改数据
- 通知 UI 层状态变化（通过 `notifyListeners()`）
- 协调多个服务的调用

**关键设计**：
- 所有 Provider 继承自 `BaseProvider`，统一管理 `loading` 状态
- 使用 Flutter 的 `ChangeNotifier` 实现观察者模式
- Provider 之间可以相互依赖（通过构造函数注入）

**BaseProvider 设计**：
```dart
// providers/base_provider.dart
class BaseProvider extends ChangeNotifier {
  bool loading = false;

  void setLoadingState(bool value) {
    loading = value;
    notifyListeners();
  }
}
```

**典型 Provider 实现**：
```dart
// providers/memories_provider.dart
class MemoriesProvider extends ChangeNotifier {
  List<Memory> _memories = [];
  bool _loading = true;
  
  List<Memory> get memories => _memories;
  bool get loading => _loading;

  Future<void> loadMemories() async {
    _loading = true;
    notifyListeners();

    // 调用服务层获取数据
    _memories = await getMemories(); // backend/http/api/memories.dart
    
    _loading = false;
    notifyListeners();
  }

  Future<void> deleteMemory(String memoryId) async {
    bool success = await deleteMemoryServer(memoryId);
    if (success) {
      _memories.removeWhere((m) => m.id == memoryId);
      notifyListeners();
    }
  }
}
```

#### 3.2.3 服务层（lib/services）

**职责**：
- 封装业务逻辑和外部交互
- 管理设备连接、WebSocket 连接、录音服务等
- 提供统一的接口给 Provider 层调用
- 处理复杂的异步操作和状态机

**核心服务**：

1. **DeviceService**：设备连接管理
2. **SocketService**：WebSocket 连接池管理
3. **MicRecorderService**：麦克风录音服务
4. **WalService**：Write-Ahead Log 服务
5. **NotificationService**：推送通知服务
6. **AuthService**：Firebase 认证服务

**ServiceManager（服务定位器模式）**：
```dart
// services/services.dart
class ServiceManager {
  late IDeviceService _device;
  late ISocketService _socket;
  late IMicRecorderService _mic;
  late IWalService _wal;
  late ISystemAudioRecorderService _systemAudio;
  
  static ServiceManager? _instance;
  
  static ServiceManager instance() {
    if (_instance == null) {
      throw Exception("Service manager is not initiated");
    }
    return _instance!;
  }
  
  IDeviceService get device => _device;
  ISocketService get socket => _socket;
  // ... 其他服务的 getter
  
  static Future<void> init() async {
    if (_instance != null) {
      throw Exception("Service manager is initiated");
    }
    _instance = ServiceManager._create();
    await ConnectivityService().init();
  }
}
```

#### 3.2.4 数据层（lib/backend）

**职责**：
- 封装 HTTP API 调用
- 定义数据模型（Schema）
- 管理本地持久化存储（SharedPreferences）
- 处理网络请求的认证和错误

**HTTP 客户端核心**：
```dart
// backend/http/shared.dart
Future<http.Response?> makeApiCall({
  required String url,
  required String method,
  required Map<String, String> headers,
  required String body,
}) async {
  // 自动添加认证 Token
  headers.addAll(await buildHeaders());
  
  // 发起 HTTP 请求
  var response = await http.Request(method, Uri.parse(url))
    ..headers.addAll(headers)
    ..body = body
    .send();
  
  return http.Response.fromStream(await response);
}

// 自动处理 Token 刷新
Future<Map<String, String>> buildHeaders() async {
  String? token = await getIdToken();
  return {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
}
```

**API 端点示例**：
```dart
// backend/http/api/memories.dart
Future<List<Memory>> getMemories({int limit = 100, int offset = 0}) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}v3/memories?limit=$limit&offset=$offset',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return [];
  
  List<dynamic> memories = json.decode(response.body);
  return memories.map((m) => Memory.fromJson(m)).toList();
}
```


---

## 4. 数据流分析

Omi 应用中存在三种主要的数据流模式，每种模式服务于不同的业务场景。

### 4.1 REST API 数据流（持久化数据）

**用途**：获取和修改服务器上的持久化数据（记忆、应用、用户信息等）

**数据流向**：
```
用户操作（UI 层）
    ↓
Provider 调用 API 方法
    ↓
Backend API 层构建 HTTP 请求
    ↓
HTTP Client 添加认证头
    ↓
发送到后端服务器
    ↓
解析响应并转换为模型对象
    ↓
Provider 更新状态
    ↓
UI 响应式更新（通过 notifyListeners）
```

**完整示例**：获取记忆列表

```dart
// 1. UI 层触发
// pages/memories/page.dart
class MemoriesPage extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    context.read<MemoriesProvider>().loadMemories(); // 触发数据加载
  }
}

// 2. Provider 层处理
// providers/memories_provider.dart
class MemoriesProvider extends ChangeNotifier {
  Future<void> loadMemories() async {
    _loading = true;
    notifyListeners();  // 通知 UI 进入加载状态
    
    _memories = await getMemories();  // 调用 API
    
    _loading = false;
    notifyListeners();  // 通知 UI 数据已更新
  }
}

// 3. Backend API 层
// backend/http/api/memories.dart
Future<List<Memory>> getMemories({int limit = 100, int offset = 0}) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}v3/memories?limit=$limit&offset=$offset',
    method: 'GET',
    headers: {},
    body: '',
  );
  
  List<dynamic> memories = json.decode(response.body);
  return memories.map((m) => Memory.fromJson(m)).toList();
}

// 4. HTTP Client 层（自动处理认证）
// backend/http/shared.dart
Future<Map<String, String>> buildHeaders() async {
  String? token = await getIdToken();  // 自动获取 Firebase Token
  return {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
}
```

### 4.2 设备连接数据流（BLE/Watch 通信）

**用途**：连接和管理可穿戴设备，实时接收音频流

**数据流向**：
```
物理设备（Omi/Frame/Apple Watch）
    ↓
传输层（BLE/Watch/Frame Transport）
    ↓
设备连接层（DeviceConnection）
    ↓
设备服务（DeviceService）
    ↓
DeviceProvider 状态管理
    ↓
UI 显示连接状态和设备信息
```

**关键架构**：采用工厂模式 + 策略模式

```dart
// 1. 设备连接工厂
// services/devices/device_connection.dart
class DeviceConnectionFactory {
  static DeviceConnection? create(BtDevice device) {
    // 根据 locator 创建传输层
    DeviceTransport transport;
    final locator = device.locator;
    
    switch (locator.kind) {
      case TransportKind.bluetooth:
        transport = BleTransport(BluetoothDevice.fromId(locator.bluetoothId));
        break;
      case TransportKind.watchConnectivity:
        transport = WatchTransport();
        break;
      default:
        return null;
    }
    
    // 根据设备类型创建连接
    switch (device.type) {
      case DeviceType.omi:
        return OmiDeviceConnection(device, transport);
      case DeviceType.frame:
        return FrameDeviceConnection(device, transport);
      case DeviceType.appleWatch:
        return AppleWatchDeviceConnection(device, transport);
      // ... 其他设备类型
    }
  }
}

// 2. 传输层抽象
// services/devices/transports/device_transport.dart
abstract class DeviceTransport {
  Stream<DeviceTransportState> get connectionStateStream;
  
  Future<void> connect();
  Future<void> disconnect();
  Stream<List<int>> get dataStream;
}

// 3. BLE 传输实现
// services/devices/transports/ble_transport.dart
class BleTransport implements DeviceTransport {
  final BluetoothDevice device;
  
  @override
  Future<void> connect() async {
    await device.connect();
  }
  
  @override
  Stream<List<int>> get dataStream {
    return characteristic.value; // 监听 BLE 特征值变化
  }
}

// 4. Provider 层管理连接状态
// providers/device_provider.dart
class DeviceProvider extends ChangeNotifier {
  bool isConnected = false;
  BtDevice? connectedDevice;
  
  Future<void> connectToDevice(BtDevice device) async {
    isConnecting = true;
    notifyListeners();
    
    var connection = await ServiceManager.instance().device.ensureConnection(device.id);
    await connection?.connect();
    
    isConnected = true;
    isConnecting = false;
    connectedDevice = device;
    notifyListeners();
  }
}
```

### 4.3 WebSocket 实时数据流（实时转录）

**用途**：实时音频转录，将设备采集的音频流式传输到服务器并接收转录结果

**数据流向**：
```
麦克风/设备音频
    ↓
MicRecorderService（录音服务）
    ↓
WebSocket 连接（TranscriptionService）
    ↓
服务器实时转录
    ↓
WebSocket 接收转录片段（TranscriptSegment）
    ↓
CaptureProvider 更新转录文本
    ↓
UI 实时显示转录内容
```

**完整流程**：

```dart
// 1. 建立 WebSocket 连接
// services/sockets/transcription_connection.dart
class TranscriptSegmentSocketService {
  late PureSocket _socket;
  int sampleRate;
  BleAudioCodec codec;
  String language;
  
  TranscriptSegmentSocketService.create(
    this.sampleRate,
    this.codec,
    this.language,
  ) {
    // 构建 WebSocket URL，包含音频参数
    var params = '?language=$language&sample_rate=$sampleRate&codec=$codec'
                 '&uid=${SharedPreferencesUtil().uid}';
    String url = '${Env.apiBaseUrl}'
        .replaceFirst('https://', 'wss://')
        + 'v4/listen$params';
    
    _socket = PureSocket(url);
  }
  
  Future start() async {
    await _socket.connect();
  }
  
  Future send(dynamic message) async {
    _socket.send(message);  // 发送音频字节流
  }
  
  // 监听服务器返回的转录结果
  @override
  void onMessage(String message) {
    final data = json.decode(message);
    if (data['segments'] != null) {
      List<TranscriptSegment> segments = (data['segments'] as List)
          .map((s) => TranscriptSegment.fromJson(s))
          .toList();
      
      // 通知所有监听者
      _listeners.forEach((k, v) {
        v.onSegmentReceived(segments);
      });
    }
  }
}

// 2. Provider 订阅 WebSocket 事件
// providers/capture_provider.dart
class CaptureProvider extends ChangeNotifier 
    implements ITransctipSegmentSocketServiceListener {
  
  List<TranscriptSegment> segments = [];
  
  void startTranscription() async {
    // 创建 WebSocket 服务
    _socket = ConversationTranscriptSegmentSocketService.create(
      16000, // sampleRate
      BleAudioCodec.pcm16,
      'en'
    );
    
    // 订阅事件
    _socket.subscribe(this, this);
    await _socket.start();
  }
  
  @override
  void onSegmentReceived(List<TranscriptSegment> newSegments) {
    segments.addAll(newSegments);
    notifyListeners();  // 通知 UI 更新
  }
  
  // 发送音频数据
  void sendAudioData(Uint8List audioBytes) {
    _socket.send(audioBytes);
  }
}

// 3. UI 层显示实时转录
// pages/capture/page.dart
class CapturePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CaptureProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // 显示实时转录文本
            Text(provider.segments.map((s) => s.text).join(' ')),
            // 录音控制按钮
            ElevatedButton(
              onPressed: () => provider.startTranscription(),
              child: Text('开始转录'),
            ),
          ],
        );
      },
    );
  }
}
```

### 4.4 数据流对比总结

| 数据流类型 | 通信协议 | 数据方向 | 典型延迟 | 使用场景 |
|----------|---------|---------|---------|---------|
| REST API | HTTP/HTTPS | 请求-响应 | 100-500ms | 获取记忆、应用、用户数据 |
| 设备连接 | BLE/Watch Connectivity | 双向流式 | 10-50ms | 设备连接、音频流传输 |
| WebSocket | WebSocket | 双向流式 | 50-200ms | 实时转录、实时消息推送 |

---

## 5. 设计模式与最佳实践

### 5.1 采用的设计模式

#### 5.1.1 单例模式（Singleton Pattern）

**ServiceManager** 采用单例模式，确保全局只有一个服务管理器实例。

```dart
class ServiceManager {
  static ServiceManager? _instance;
  
  static ServiceManager instance() {
    if (_instance == null) {
      throw Exception("Service manager is not initiated");
    }
    return _instance!;
  }
  
  static Future<void> init() async {
    if (_instance != null) {
      throw Exception("Service manager is initiated");
    }
    _instance = ServiceManager._create();
  }
}
```

**优点**：
- 避免重复创建服务实例
- 全局访问点，便于服务定位
- 服务的生命周期统一管理

#### 5.1.2 工厂模式（Factory Pattern）

**DeviceConnectionFactory** 根据设备类型创建对应的设备连接对象。

```dart
class DeviceConnectionFactory {
  static DeviceConnection? create(BtDevice device) {
    // 根据设备类型返回不同的连接实现
    switch (device.type) {
      case DeviceType.omi:
        return OmiDeviceConnection(device, transport);
      case DeviceType.frame:
        return FrameDeviceConnection(device, transport);
      case DeviceType.appleWatch:
        return AppleWatchDeviceConnection(device, transport);
      // ...
    }
  }
}
```

**优点**：
- 解耦设备连接的创建和使用
- 易于扩展新的设备类型
- 隐藏具体实现细节

#### 5.1.3 观察者模式（Observer Pattern）

**Provider + ChangeNotifier** 实现观察者模式，UI 自动响应状态变化。

```dart
// Provider 是被观察者
class MemoriesProvider extends ChangeNotifier {
  void updateMemories(List<Memory> newMemories) {
    _memories = newMemories;
    notifyListeners();  // 通知所有观察者
  }
}

// UI 是观察者
Consumer<MemoriesProvider>(
  builder: (context, provider, child) {
    // provider 变化时自动重建
    return ListView(children: provider.memories.map(...));
  },
)
```

**优点**：
- UI 与业务逻辑解耦
- 自动化的状态同步
- 减少手动管理状态的代码

#### 5.1.4 策略模式（Strategy Pattern）

**DeviceTransport** 抽象层允许不同的传输策略（BLE、Watch Connectivity、Frame）。

```dart
// 传输策略接口
abstract class DeviceTransport {
  Future<void> connect();
  Future<void> disconnect();
  Stream<List<int>> get dataStream;
}

// 具体策略 1：BLE 传输
class BleTransport implements DeviceTransport {
  @override
  Future<void> connect() async {
    await device.connect();
  }
}

// 具体策略 2：Watch 传输
class WatchTransport implements DeviceTransport {
  @override
  Future<void> connect() async {
    await watchConnectivity.activateSession();
  }
}

// 使用时动态选择策略
DeviceConnection connection = OmiDeviceConnection(device, BleTransport(device));
```

**优点**：
- 同一设备连接接口支持多种传输协议
- 易于添加新的传输方式
- 运行时可切换策略

#### 5.1.5 适配器模式（Adapter Pattern）

不同设备通过 **DeviceConnection** 抽象接口适配到统一的设备管理系统。

```dart
abstract class DeviceConnection {
  Future<void> connect();
  Future<void> disconnect();
  Future<void> ping();
  Stream<List<int>> getAudioStream();
}

// Omi 设备适配器
class OmiDeviceConnection extends DeviceConnection {
  // 实现 Omi 特定的连接逻辑
}

// Frame 设备适配器
class FrameDeviceConnection extends DeviceConnection {
  // 实现 Frame 特定的连接逻辑
}
```

**优点**：
- 统一的设备管理接口
- 隐藏设备差异，简化上层调用
- 支持多种异构设备

### 5.2 架构设计原则

#### 5.2.1 分层架构原则

- **单向依赖**：UI → Provider → Service → Backend，上层依赖下层，下层不依赖上层
- **职责分离**：每一层只关注自己的职责，不跨层调用
- **松耦合**：通过接口和抽象类降低层间耦合

#### 5.2.2 依赖倒置原则（DIP）

```dart
// 依赖抽象而非具体实现
abstract class IDeviceService {
  Future<DeviceConnection?> ensureConnection(String deviceId);
}

class DeviceProvider {
  final IDeviceService _deviceService;  // 依赖接口
  
  DeviceProvider(this._deviceService);
}
```

#### 5.2.3 开闭原则（OCP）

- 通过工厂模式和策略模式，系统对扩展开放（添加新设备类型），对修改关闭
- 添加新设备只需实现 `DeviceConnection` 接口，无需修改现有代码

#### 5.2.4 单一职责原则（SRP）

- Provider 只管理状态，不处理业务逻辑
- Service 只处理业务逻辑，不管理 UI 状态
- Backend 只处理网络请求，不包含业务逻辑

---

## 6. 关键技术组件

### 6.1 设备连接架构

设备连接是 Omi 应用的核心功能，支持多种可穿戴设备的连接和通信。

#### 6.1.1 三层架构

```
┌─────────────────────────────────────────────┐
│     DeviceConnection（设备连接抽象）           │
│  OmiConnection | FrameConnection | ...      │
└──────────────────┬──────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────┐
│      DeviceTransport（传输层抽象）            │
│  BleTransport | WatchTransport | ...        │
└──────────────────┬──────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────┐
│          物理层（协议栈）                      │
│  Flutter Blue Plus | Watch Connectivity     │
└─────────────────────────────────────────────┘
```

#### 6.1.2 支持的设备类型

| 设备类型 | 连接类 | 传输方式 | 特性 |
|---------|--------|---------|------|
| Omi | OmiDeviceConnection | BLE | 主力设备，完整功能支持 |
| Frame | FrameDeviceConnection | BLE/Frame SDK | 智能眼镜，视觉交互 |
| Apple Watch | AppleWatchDeviceConnection | Watch Connectivity | watchOS 集成 |
| XOR | XorDeviceConnection | BLE | XOR 设备 |
| Bee | BeeDeviceConnection | BLE | Bee 设备 |
| Fieldy | FieldyDeviceConnection | BLE | Fieldy 设备 |
| OpenGlass | OmiDeviceConnection | BLE | 开源眼镜项目 |

#### 6.1.3 设备发现机制

```dart
// services/devices/discovery/device_locator.dart
class DeviceLocator {
  // 扫描蓝牙设备
  static Stream<BtDevice> scanBluetoothDevices() async* {
    await for (var scanResult in FlutterBluePlus.scanResults) {
      if (isOmiDevice(scanResult.device)) {
        yield BtDevice.fromBluetooth(scanResult.device);
      }
    }
  }
  
  // 扫描 Apple Watch
  static Future<BtDevice?> findAppleWatch() async {
    if (await WatchConnectivity.isSupported()) {
      return BtDevice.appleWatch();
    }
    return null;
  }
}
```

### 6.2 音频处理系统

#### 6.2.1 音频编解码支持

应用支持多种音频编解码格式，以适应不同的设备和网络条件：


```dart
enum BleAudioCodec {
  pcm8,    // 8-bit PCM，低质量，低带宽
  pcm16,   // 16-bit PCM，高质量，高带宽
  mulaw8,  // μ-law 压缩，电话质量
  opus,    // Opus 编码，高质量，可变比特率
  aac,     // AAC 编码，移动设备友好
}
```

**编解码选择策略**：
- **设备到应用**：优先使用 Opus（压缩率高，质量好）
- **应用内录音**：PCM16（无损，便于处理）
- **网络传输**：Opus 或 μ-law（节省带宽）

#### 6.2.2 录音服务架构

```
┌────────────────────────────────────────┐
│      MicRecorderService 接口            │
└──────────────┬─────────────────────────┘
               │
       ┌───────┴────────┐
       │                │
┌──────▼──────┐  ┌──────▼──────────────┐
│  前台录音服务  │  │  后台录音服务        │
│  (直接录音)   │  │  (BackgroundService)│
└──────────────┘  └─────────────────────┘
```

**前台录音**（MicRecorderService）：
- 使用 `flutter_sound` 直接录音
- 适用于应用在前台时
- 低延迟，实时处理

**后台录音**（MicRecorderBackgroundService）：
- 使用 Flutter Background Service
- Android 使用 Foreground Service
- iOS 使用后台音频模式
- 确保录音不被系统杀死

**桌面端系统音频录制**（仅 macOS）：
- 捕获系统音频输出
- 通过 Platform Channel 调用原生代码
- 支持麦克风和系统音频混合

#### 6.2.3 音频流处理流程

```dart
// 录音 → 编码 → WebSocket → 服务器转录

// 1. 开始录音
MicRecorderService.start(
  onByteReceived: (audioBytes) {
    // 2. 发送到 WebSocket
    transcriptionService.send(audioBytes);
  },
);

// 3. 接收转录结果
transcriptionService.onSegmentReceived = (segments) {
  // 4. 更新 UI
  provider.addSegments(segments);
};
```

### 6.3 环境配置与 Flavor 系统

#### 6.3.1 Flavor 定义

```dart
// lib/flavors.dart
enum Environment { dev, prod }

class F {
  static Environment? env;
  
  static String get title {
    return env == Environment.prod ? 'Omi' : 'Omi Dev';
  }
}
```

#### 6.3.2 环境变量管理

使用 `envied` 包管理敏感配置：

```dart
// lib/env/dev_env.dart
@Envied(path: '.dev.env')
abstract class DevEnv {
  @EnviedField(varName: 'API_BASE_URL')
  static const String apiBaseUrl = _DevEnv.apiBaseUrl;
  
  @EnviedField(varName: 'MIXPANEL_PROJECT_TOKEN', obfuscate: true)
  static final String mixpanelProjectToken = _DevEnv.mixpanelProjectToken;
}

// lib/env/prod_env.dart
@Envied(path: '.env')
abstract class ProdEnv {
  @EnviedField(varName: 'API_BASE_URL')
  static const String apiBaseUrl = _ProdEnv.apiBaseUrl;
  
  @EnviedField(varName: 'MIXPANEL_PROJECT_TOKEN', obfuscate: true)
  static final String mixpanelProjectToken = _ProdEnv.mixpanelProjectToken;
}
```

**运行不同环境**：
```bash
# 开发环境
flutter run --flavor dev

# 生产环境
flutter run --flavor prod
```

---

## 7. 应用初始化流程


### 7.1 启动顺序

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. 初始化环境配置
  await _init();
  
  // 2. 启动应用
  runApp(MyApp());
}

Future _init() async {
  // 步骤 1: 配置环境变量（dev/prod）
  if (F.env == Environment.prod) {
    Env.init(ProdEnv());
  } else {
    Env.init(DevEnv());
  }
  
  // 步骤 2: 初始化后台任务
  FlutterForegroundTask.initCommunicationPort();
  
  // 步骤 3: 初始化服务管理器
  await ServiceManager.init();
  
  // 步骤 4: 初始化 Firebase
  await Firebase.initializeApp(
    options: F.env == Environment.prod 
        ? prod.DefaultFirebaseOptions.currentPlatform
        : dev.DefaultFirebaseOptions.currentPlatform
  );
  
  // 步骤 5: 初始化平台服务（分析、崩溃报告）
  await PlatformManager.initializeServices();
  
  // 步骤 6: 初始化通知服务
  await NotificationService.instance.initialize();
  
  // 步骤 7: 注册 FCM 后台消息处理器
  if (!PlatformService.isDesktop) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  
  // 步骤 8: 初始化本地存储
  await SharedPreferencesUtil.init();
  
  // 步骤 9: 初始化 Opus 编解码器（仅移动端）
  if (PlatformService.isMobile) {
    initOpus(await opus_flutter.load());
  }
  
  // 步骤 10: 初始化 GrowthBook（特征标志）
  await GrowthbookUtil.init();
  
  // 步骤 11: 配置蓝牙（非 Windows）
  if (!PlatformService.isWindows) {
    ble.FlutterBluePlus.setOptions(restoreState: true);
    ble.FlutterBluePlus.setLogLevel(ble.LogLevel.info, color: true);
  }
  
  // 步骤 12: 初始化崩溃报告
  await CrashlyticsManager.init();
  
  // 步骤 13: 识别已登录用户（用于分析）
  bool isAuth = (await AuthService.instance.getIdToken()) != null;
  if (isAuth) {
    PlatformManager.instance.mixpanel.identify();
    PlatformManager.instance.crashReporter.identifyUser(
      FirebaseAuth.instance.currentUser?.email ?? '',
      SharedPreferencesUtil().fullName,
      SharedPreferencesUtil().uid,
    );
  }
}
```

### 7.2 Provider 初始化


在 AppShell 中使用 MultiProvider 注入所有状态管理器：

```dart
// lib/main.dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => CaptureProvider()),
        ChangeNotifierProvider(create: (_) => MemoriesProvider()),
        ChangeNotifierProvider(create: (_) => ConversationProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PeopleProvider()),
        ChangeNotifierProvider(create: (_) => UsageProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => DeveloperModeProvider()),
        ChangeNotifierProvider(create: (_) => SpeechProfileProvider()),
        ChangeNotifierProvider(create: (_) => ActionItemsProvider()),
        ChangeNotifierProvider(create: (_) => MCPProvider()),
        // ... 其他 Providers
      ],
      child: AppShell(),
    );
  }
}
```

---

## 8. 第三方集成

### 8.1 Firebase 服务


**Firebase Authentication**
- 用户认证和授权
- 支持 Google Sign-In、Apple Sign-In、邮箱密码等多种方式
- Token 自动刷新机制

**Firebase Cloud Messaging (FCM)**
- 推送通知服务
- 后台消息处理（Action Item 提醒）
- Token 管理和设备注册

**Firebase Crashlytics**
- 崩溃报告和错误跟踪
- 自动捕获未处理的异常
- 用户标识和自定义日志

```dart
// 崩溃报告初始化
FlutterError.onError = (errorDetails) {
  FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
};

PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

### 8.2 用户分析与特征标志

**Mixpanel**
- 用户行为分析
- 事件追踪
- 用户属性管理

```dart
// 追踪事件
PlatformManager.instance.mixpanel.track('Memory Created', properties: {
  'memory_id': memory.id,
  'category': memory.category,
});
```

**GrowthBook**
- 特征标志管理
- A/B 测试
- 动态配置

```dart
// 检查特征是否启用
bool isFeatureEnabled = GrowthbookUtil.isFeatureOn('new_chat_ui');
```

**Intercom**
- 用户支持和客服
- 应用内消息
- 用户帮助中心

### 8.3 设备通信

**Flutter Blue Plus**
- BLE (蓝牙低功耗) 通信
- 设备扫描和连接
- 特征值读写和通知

**Frame SDK**
- Brilliant Frame 智能眼镜集成
- 视觉交互和显示
- 传感器数据读取

**Apple Watch Connectivity**
- watchOS 与 iOS 应用通信
- 数据同步
- 消息传递

### 8.4 音频处理

**flutter_sound**
- 麦克风录音
- 音频播放
- 支持多种音频格式

**opus_flutter / opus_dart**
- Opus 编解码器
- 高质量音频压缩
- 适用于网络传输

---

## 9. 开发建议

### 9.1 添加新功能的最佳实践


#### 步骤 1：创建数据模型
```dart
// lib/backend/schema/new_feature.dart
class NewFeature {
  final String id;
  final String name;
  
  NewFeature({required this.id, required this.name});
  
  factory NewFeature.fromJson(Map<String, dynamic> json) {
    return NewFeature(
      id: json['id'],
      name: json['name'],
    );
  }
}
```

#### 步骤 2：创建 API 端点
```dart
// lib/backend/http/api/new_feature.dart
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

#### 步骤 3：创建 Provider
```dart
// lib/providers/new_feature_provider.dart
class NewFeatureProvider extends ChangeNotifier {
  List<NewFeature> _features = [];
  bool _loading = false;
  
  List<NewFeature> get features => _features;
  bool get loading => _loading;
  
  Future<void> loadFeatures() async {
    _loading = true;
    notifyListeners();
    
    _features = await getNewFeatures();
    
    _loading = false;
    notifyListeners();
  }
}
```

#### 步骤 4：注册 Provider
```dart
// lib/main.dart
MultiProvider(
  providers: [
    // ... 其他 Providers
    ChangeNotifierProvider(create: (_) => NewFeatureProvider()),
  ],
)
```

#### 步骤 5：创建 UI 页面
```dart
// lib/pages/new_feature/page.dart
class NewFeaturePage extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    context.read<NewFeatureProvider>().loadFeatures();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<NewFeatureProvider>(
      builder: (context, provider, child) {
        if (provider.loading) {
          return CircularProgressIndicator();
        }
        
        return ListView.builder(
          itemCount: provider.features.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(provider.features[index].name),
            );
          },
        );
      },
    );
  }
}
```

### 9.2 添加新设备类型

#### 步骤 1：定义设备类型
```dart
// lib/backend/schema/bt_device/bt_device.dart
enum DeviceType {
  omi,
  frame,
  appleWatch,
  xor,
  bee,
  fieldy,
  newDevice,  // 添加新设备类型
}
```

#### 步骤 2：实现 DeviceConnection
```dart
// lib/services/devices/new_device_connection.dart
class NewDeviceConnection extends DeviceConnection {
  NewDeviceConnection(BtDevice device, DeviceTransport transport)
      : super(device, transport);
  
  @override
  Future<void> connect() async {
    await super.connect();
    // 新设备特定的连接逻辑
  }
  
  @override
  Stream<List<int>> getAudioStream() {
    // 返回音频数据流
  }
}
```

#### 步骤 3：更新工厂方法
```dart
// lib/services/devices/device_connection.dart
class DeviceConnectionFactory {
  static DeviceConnection? create(BtDevice device) {
    // ... 创建 transport
    
    switch (device.type) {
      case DeviceType.omi:
        return OmiDeviceConnection(device, transport);
      case DeviceType.newDevice:  // 添加新设备
        return NewDeviceConnection(device, transport);
      // ... 其他设备
    }
  }
}
```

### 9.3 代码规范建议

1. **命名规范**
   - Provider 类名以 `Provider` 结尾
   - Service 类名以 `Service` 结尾
   - 私有变量使用下划线前缀 `_variable`

2. **文件组织**
   - 一个文件一个类（除非是紧密相关的小类）
   - 页面文件命名为 `page.dart`
   - Widget 文件命名为描述性名称，如 `memory_card.dart`

3. **状态管理**
   - 所有 Provider 应继承 `BaseProvider` 或 `ChangeNotifier`
   - 状态更新后必须调用 `notifyListeners()`
   - 避免在 Provider 中直接操作 UI

4. **异步处理**
   - 使用 `async/await` 而非 `.then()`
   - 始终处理错误情况（try-catch）
   - 长时间操作使用 loading 状态提示用户

5. **依赖注入**
   - 通过 Provider 注入依赖，而非直接实例化
   - Service 通过 ServiceManager 获取，而非直接创建
   - 避免循环依赖

### 9.4 性能优化建议

1. **减少不必要的重建**
   ```dart
   // 好的做法：只监听需要的 Provider
   Consumer<MemoriesProvider>(
     builder: (context, provider, child) {
       return Text(provider.memories.length.toString());
     },
   )
   
   // 避免：监听整个 widget
   return Consumer<MemoriesProvider>(
     builder: (context, provider, child) {
       return ComplexWidget();  // 整个 widget 都会重建
     },
   )
   ```

2. **使用 Selector 优化**
   ```dart
   // 只在特定属性变化时重建
   Selector<MemoriesProvider, int>(
     selector: (_, provider) => provider.memories.length,
     builder: (_, count, __) => Text('$count memories'),
   )
   ```

3. **图片加载优化**
   - 使用 `CachedNetworkImage` 缓存网络图片
   - 提供占位符和错误处理
   - 控制图片尺寸，避免加载超大图片

4. **列表优化**
   - 使用 `ListView.builder` 而非 `ListView`
   - 长列表使用虚拟滚动
   - 避免在 `itemBuilder` 中进行复杂计算

### 9.5 调试技巧

1. **日志记录**
   ```dart
   // 使用统一的 Logger
   Logger.debug('Debug message');
   Logger.info('Info message');
   Logger.error('Error message');
   
   // 调试日志管理器
   await DebugLogManager.logEvent('feature_used', {
     'feature_name': 'transcription',
     'duration': 120,
   });
   ```

2. **网络请求调试**
   - 使用 Charles 或 Proxyman 抓包
   - 检查 Authorization header 是否正确
   - 查看 `makeApiCall` 的请求和响应日志

3. **蓝牙调试**
   ```dart
   // 启用 BLE 详细日志
   FlutterBluePlus.setLogLevel(LogLevel.debug, color: true);
   ```

4. **Provider 状态调试**
   ```dart
   // 使用 Provider DevTools
   // 或者在 Provider 中添加调试日志
   @override
   void notifyListeners() {
     debugPrint('[MemoriesProvider] State changed: ${_memories.length} memories');
     super.notifyListeners();
   }
   ```

### 9.6 测试建议

1. **单元测试**
   - 测试 Provider 的状态管理逻辑
   - 测试数据模型的序列化/反序列化
   - Mock API 响应进行测试

2. **Widget 测试**
   - 测试 UI 组件的渲染
   - 测试用户交互（按钮点击、表单输入）
   - 使用 `pumpWidget` 和 `find` API

3. **集成测试**
   - 测试完整的用户流程
   - 测试多页面导航
   - 测试设备连接流程

---

## 10. 总结

### 10.1 架构优势

1. **清晰的分层架构**
   - UI、状态管理、服务、数据四层分离
   - 职责明确，易于维护和扩展

2. **高度可扩展性**
   - 工厂模式和策略模式支持快速添加新设备
   - Provider 模式便于添加新功能
   - 模块化设计降低耦合度

3. **跨平台支持**
   - 单一代码库支持多平台
   - 平台特定代码隔离在 mobile/ 和 desktop/
   - Flavor 系统支持多环境部署

4. **完善的第三方集成**
   - Firebase 提供认证、推送、崩溃报告
   - Mixpanel 和 GrowthBook 提供数据分析和特征管理
   - 丰富的设备通信支持（BLE、Watch、Frame SDK）

5. **实时通信能力**
   - WebSocket 支持实时转录
   - BLE 低延迟音频流传输
   - 后台服务确保持续录音

### 10.2 潜在改进方向

1. **依赖注入优化**
   - 考虑使用 GetIt 或 Injectable 替代 ServiceManager
   - 减少对单例的依赖，提高可测试性

2. **状态管理升级**
   - 对于复杂状态，可考虑 Riverpod 或 Bloc
   - 更好的状态不可变性保证
   - 更清晰的依赖关系管理

3. **代码生成增强**
   - 使用 Freezed 生成不可变数据类
   - 自动生成路由配置
   - 减少样板代码

4. **测试覆盖**
   - 增加单元测试覆盖率
   - 建立 CI/CD 自动化测试
   - 端到端测试自动化

5. **文档完善**
   - API 文档自动生成
   - 组件库文档（Storybook 风格）
   - 架构决策记录（ADR）

### 10.3 核心设计理念

Omi 应用的架构设计体现了以下核心理念：

1. **分离关注点**：每一层只关注自己的职责
2. **面向接口编程**：依赖抽象而非具体实现
3. **开闭原则**：对扩展开放，对修改关闭
4. **组合优于继承**：通过组合不同的服务和传输层实现灵活性
5. **响应式编程**：使用 Stream 和观察者模式实现数据驱动的 UI

---

## 附录

### A. 常用命令速查

```bash
# 开发环境运行
flutter run --flavor dev

# 生产环境运行
flutter run --flavor prod

# 代码生成
flutter pub run build_runner build --delete-conflicting-outputs

# 生成 Pigeon 平台接口
flutter pub run pigeon --input pigeons/message.dart

# 静态分析
flutter analyze

# 运行测试
flutter test

# iOS 构建
flutter build ios --flavor dev --release

# 安装到 iPhone
ios-deploy --bundle build/ios/iphoneos/Runner.app --debug
```

### B. 关键文件速查表

| 文件路径 | 用途 |
|---------|------|
| `lib/main.dart` | 应用入口，初始化流程 |
| `lib/core/app_shell.dart` | 路由和深度链接 |
| `lib/services/services.dart` | ServiceManager 服务定位器 |
| `lib/providers/base_provider.dart` | Provider 基类 |
| `lib/backend/http/shared.dart` | HTTP 客户端核心 |
| `lib/services/devices/device_connection.dart` | 设备连接工厂 |
| `lib/services/sockets/transcription_connection.dart` | WebSocket 转录服务 |
| `lib/backend/preferences.dart` | 本地存储封装 |
| `lib/flavors.dart` | 环境配置 |
| `pubspec.yaml` | 依赖配置 |

### C. 环境变量配置

创建 `.dev.env` 文件（开发环境）：
```env
API_BASE_URL=https://dev.api.omi.com/
MIXPANEL_PROJECT_TOKEN=your_dev_token
GROWTHBOOK_API_KEY=your_dev_key
```

创建 `.env` 文件（生产环境）：
```env
API_BASE_URL=https://api.omi.com/
MIXPANEL_PROJECT_TOKEN=your_prod_token
GROWTHBOOK_API_KEY=your_prod_key
```

### D. 架构图总览

```
┌─────────────────────────────────────────────────────────────┐
│                        用户界面层 (UI)                         │
│    pages/ (功能页面) + widgets/ (组件) + ui/ (原子设计)         │
└────────────────────────┬────────────────────────────────────┘
                         │ Provider Consumer
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                     状态管理层 (Providers)                     │
│   AppProvider | MemoriesProvider | DeviceProvider | ...     │
└────────────────────────┬────────────────────────────────────┘
                         │ 调用服务接口
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                       服务层 (Services)                       │
│    ServiceManager: Device | Socket | Mic | Wal | ...       │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTP/WebSocket/BLE
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                      数据层 (Backend)                         │
│       HTTP API Client + Data Models + Local Storage         │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                        外部系统                               │
│    后端服务器 | 可穿戴设备 | Firebase | 第三方服务             │
└─────────────────────────────────────────────────────────────┘
```

### E. 参考资源

**官方文档**
- [Flutter 官方文档](https://flutter.dev/docs)
- [Provider 包文档](https://pub.dev/packages/provider)
- [Flutter Blue Plus 文档](https://pub.dev/packages/flutter_blue_plus)

**设计模式**
- 《设计模式：可复用面向对象软件的基础》
- [Refactoring Guru - 设计模式](https://refactoringguru.cn/design-patterns)

**Flutter 架构**
- [Flutter 应用架构指南](https://docs.flutter.dev/development/data-and-backend/state-mgmt/options)
- [Clean Architecture in Flutter](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

---

**文档版本**：v1.0  
**最后更新**：2025-01-06  
**分析基于**：Omi App 代码库（commit: 42d3bb502）

---

**© 2025 Omi Project. 本文档基于代码库分析生成，用于团队内部参考。**
