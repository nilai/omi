# iOS/Android BLE 后台保活方案技术文档

> 本文档基于 Omi Flutter App 的实际实现，总结 iOS/Android 端 BLE 设备后台通信与保活的最佳实践。
>
> **相关文档**：[BLE 设备协议文档](./BLE-Device-Protocol-Guide.md)

---

## 目录

1. [方案概述](#方案概述)
2. [iOS 后台保活](#ios-后台保活)
3. [Android 后台保活](#android-后台保活)
4. [跨平台保活机制](#跨平台保活机制)
5. [Apple Watch 通信方案](#apple-watch-通信方案)
6. [WebSocket 保活策略](#websocket-保活策略)
7. [最佳实践](#最佳实践)
8. [文件索引](#文件索引)

---

## 方案概述

### 核心策略对比

| 平台 | 核心策略 | 系统依赖 | 应用层机制 |
|-----|---------|---------|-----------|
| **iOS** | 系统后台模式 + 事件驱动重连 | `bluetooth-central` 后台模式 | 15秒定时重连 |
| **Android** | 前台服务 + 多重保活 | 前台服务通知 | START_STICKY + 任务移除监听 |

### 各层保活机制汇总

| 层级 | 机制 | iOS | Android | 周期 | 触发条件 |
|-----|------|-----|---------|-----|---------|
| **系统层** | 后台模式/前台服务 | bluetooth-central | ForegroundService | 持续 | 始终 |
| **DeviceProvider** | 定时重连检查 | ✅ | ✅ | 15秒 | 设备断开时 |
| **WebSocket** | Ping 帧 | ✅ | ✅ | 20秒 | 始终 |
| **CaptureProvider** | 应用层保活 | ✅ | ✅ | 15秒 | Socket 错误时 |
| **心跳监控** | Ping/Pong | ❌ | ✅ | 5秒 | 后台服务运行时 |
| **任务移除恢复** | 通知召回 | ❌ | ✅ | 事件触发 | 用户划掉应用时 |

---

## iOS 后台保活

### Info.plist 配置

```xml
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>  <!-- BLE 中心模式，必需 -->
    <string>audio</string>              <!-- 音频处理 -->
    <string>processing</string>         <!-- iOS 13+ 后台处理 -->
    <string>remote-notification</string> <!-- 推送通知唤醒 -->
    <string>fetch</string>              <!-- 后台获取 -->
    <string>location</string>           <!-- 位置更新 -->
</array>

<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>dev.flutter.background.refresh</string>
    <string>com.pravera.flutter_foreground_task.refresh</string>
</array>
```

### 后台模式说明

| 模式 | 作用 | 使用场景 |
|-----|------|---------|
| `bluetooth-central` | 允许后台维护 BLE 连接 | BLE 设备通信（必需） |
| `audio` | 持续音频处理 | 音频流传输 |
| `processing` | iOS 13+ BGProcessingTask | 长时间后台任务 |
| `remote-notification` | 推送通知唤醒 | 静默推送触发后台任务 |
| `location` | 位置更新 | 位置追踪场景 |

### iOS 保活架构图

```
┌─────────────────────────────────────────────────────────────┐
│                      Application Layer                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │ CaptureProvider │  │ DeviceProvider  │  │ WebSocket    │ │
│  │ (15s keep-alive)│  │ (15s reconnect) │  │ (20s ping)   │ │
│  └────────┬────────┘  └────────┬────────┘  └──────┬───────┘ │
└───────────┼────────────────────┼───────────────────┼─────────┘
            │                    │                   │
┌───────────┼────────────────────┼───────────────────┼─────────┐
│           ▼                    ▼                   ▼         │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                    Service Layer                         │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌────────────────┐ │ │
│  │  │ BleTransport │  │WatchTransport│  │  PureSocket    │ │ │
│  │  │ (RSSI ping)  │  │(WCSession)   │  │ (exp backoff)  │ │ │
│  │  └──────────────┘  └──────────────┘  └────────────────┘ │ │
│  └──────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────┘
            │
┌───────────┼───────────────────────────────────────────────────┐
│           ▼                                                   │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │              iOS Background Modes                         │ │
│  │  bluetooth-central | audio | processing | remote-notif   │ │
│  └──────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────┘
```

### iOS 关键特点

1. **依赖系统调度**：`bluetooth-central` 让 iOS 自动维护 BLE 连接
2. **无固定心跳**：BLE 层不主动发心跳，依赖原生 BLE 栈
3. **事件驱动重连**：断开后才启动 15 秒定时器

---

## Android 后台保活

### AndroidManifest.xml 配置

```xml
<!-- 权限声明 -->
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>

<!-- 前台服务声明 -->
<service
    android:name="com.pravera.flutter_foreground_task.service.ForegroundService"
    android:exported="false"
    android:foregroundServiceType="dataSync|connectedDevice"
    android:stopWithTask="true" />

<service
    android:name="id.flutter.flutter_background_service.BackgroundService"
    android:foregroundServiceType="microphone"
    tools:node="merge" />

<!-- 自定义任务移除恢复服务 -->
<service
    android:name=".NotificationOnKillService"
    android:enabled="true"
    android:exported="false"/>
```

### Android 保活架构图

```
┌─────────────────────────────────────────────────────────────┐
│                      Application Layer                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │ CaptureProvider │  │ DeviceProvider  │  │ WebSocket    │ │
│  │ (15s keep-alive)│  │ (15s reconnect) │  │ (20s ping)   │ │
│  └────────┬────────┘  └────────┬────────┘  └──────┬───────┘ │
└───────────┼────────────────────┼───────────────────┼─────────┘
            │                    │                   │
┌───────────┼────────────────────┼───────────────────┼─────────┐
│           ▼                    ▼                   ▼         │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                    Service Layer                         │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌────────────────┐ │ │
│  │  │ BleTransport │  │BackgroundSvc │  │  PureSocket    │ │ │
│  │  │              │  │(5s heartbeat)│  │ (exp backoff)  │ │ │
│  │  └──────────────┘  └──────────────┘  └────────────────┘ │ │
│  └──────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────┘
            │
┌───────────┼───────────────────────────────────────────────────┐
│           ▼                                                   │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │              Android Native Services                      │ │
│  │  ┌────────────────┐  ┌─────────────────────────────────┐ │ │
│  │  │ ForegroundSvc  │  │ NotificationOnKillService       │ │ │
│  │  │ - WakeLock     │  │ - START_STICKY                  │ │ │
│  │  │ - WiFi Lock    │  │ - onTaskRemoved() 通知召回       │ │ │
│  │  │ - 持久通知      │  │                                 │ │ │
│  │  └────────────────┘  └─────────────────────────────────┘ │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │              System Integration                           │ │
│  │  Battery Doze Exemption | Boot Receiver | Alarm Manager  │ │
│  └──────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────┘
```

### 原生服务实现

#### 1. NotificationOnKillService（任务移除恢复）

```kotlin
// android/app/src/main/kotlin/.../NotificationOnKillService.kt

class NotificationOnKillService: Service() {

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // START_STICKY: 系统杀死后自动重启服务
        return START_STICKY
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onTaskRemoved(rootIntent: Intent?) {
        // 用户划掉应用时触发，显示高优先级通知召回用户
        val notificationBuilder = NotificationCompat.Builder(this, "com.friend.ios")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(description)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setContentIntent(pendingIntent)
            .setSound(Settings.System.DEFAULT_NOTIFICATION_URI)

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE)
            as NotificationManager
        notificationManager.notify(123, notificationBuilder.build())
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
```

#### 2. MainActivity（服务启动桥接）

```kotlin
// android/app/src/main/kotlin/.../MainActivity.kt

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.friend.ios/notifyOnKill"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "setNotificationOnKillService") {
                    val title = call.argument<String>("title")
                    val description = call.argument<String>("description")

                    val serviceIntent = Intent(this, NotificationOnKillService::class.java)
                    serviceIntent.putExtra("title", title)
                    serviceIntent.putExtra("description", description)
                    startService(serviceIntent)

                    result.success(true)
                }
            }
    }
}
```

### Flutter 前台服务配置

```dart
// lib/utils/audio/foreground.dart

static Future<void> initializeForegroundService() async {
    FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
            channelId: 'foreground_service',
            channelName: 'Foreground Service Notification',
            channelDescription: 'Transcription service is running in the background.',
            channelImportance: NotificationChannelImportance.LOW,
            priority: NotificationPriority.HIGH,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
            showNotification: false,
            playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
            eventAction: ForegroundTaskEventAction.repeat(60 * 1000 * 5),  // 5分钟
            autoRunOnBoot: false,
            allowWakeLock: true,   // CPU 保持唤醒
            allowWifiLock: true,   // WiFi 保持连接
        ),
    );
}

// 请求电池优化白名单
static Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
        if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
            await FlutterForegroundTask.requestIgnoreBatteryOptimization();
        }
    }
}
```

### 后台麦克风服务（心跳监控）

```dart
// lib/services/services.dart

@pragma('vm:entry-point')
Future onStart(ServiceInstance service) async {
    // 录音器设置
    service.on('recorder.start').listen((event) async {
        recorder = MicRecorderService(isInBG: Platform.isAndroid ? true : false);
        recorder?.start(onByteReceived: (bytes) {
            service.invoke("recorder.ui.audioBytes", {"data": audioBytesList});
        });
    });

    // 心跳监控：检测 UI 是否响应
    var pongAt = DateTime.now();
    Timer.periodic(const Duration(seconds: 5), (timer) async {
        // 15秒无响应则认为 UI 崩溃，停止服务
        if (pongAt.isBefore(DateTime.now().subtract(const Duration(seconds: 15)))) {
            recorder?.stop();
            service.stopSelf();
            return;
        }
        service.invoke("ui.ping");  // 向 UI 发送 ping
    });

    // 接收 UI 的 pong 响应
    service.on('ui.pong').listen((event) {
        pongAt = DateTime.now();
    });
}
```

### Android 保活策略总结

| 机制 | 实现方式 | 作用 |
|-----|---------|-----|
| **START_STICKY** | Service flag | 系统杀死后自动重启 |
| **onTaskRemoved()** | Service callback | 用户划掉应用时发通知召回 |
| **WakeLock** | `allowWakeLock: true` | 防止 CPU 休眠 |
| **WiFi Lock** | `allowWifiLock: true` | 防止 WiFi 断开 |
| **电池优化白名单** | `requestIgnoreBatteryOptimization` | 绕过 Doze 模式 |
| **前台服务** | 持久通知 | 提高进程优先级 |
| **心跳监控** | 5秒 ping/pong | 检测 UI 崩溃并恢复 |

---

## 跨平台保活机制

### DeviceProvider 定时重连

```dart
// lib/providers/device_provider.dart

class DeviceProvider extends BaseProvider {
  Timer? _reconnectionTimer;
  final int _connectionCheckSeconds = 15;  // 15秒周期

  /// 启动定时重连（仅在断开时调用）
  Future periodicConnect(String printer, {bool boundDeviceOnly = false}) async {
    _reconnectionTimer?.cancel();

    _reconnectionTimer = Timer.periodic(
      Duration(seconds: _connectionCheckSeconds),
      (t) async {
        // 限流检查
        if (_reconnectAt != null && _reconnectAt!.isAfter(DateTime.now())) {
          return;
        }

        // 未连接时尝试重连
        if (!isConnected && connectedDevice == null && !isConnecting) {
          await scanAndConnectToDevice();
        } else {
          t.cancel();  // 连接成功后取消
        }
      }
    );
  }

  /// 设备断开回调
  void onDeviceDisconnected() async {
    setConnectedDevice(null);
    setIsConnected(false);

    // 1秒延迟防止竞态条件
    Future.delayed(const Duration(seconds: 1), () {
      periodicConnect('coming from onDisconnect');
    });
  }
}
```

**关键点**：
- **事件驱动**：仅在断开时启动定时器
- **15秒周期**：平衡电量消耗与重连及时性
- **1秒延迟**：避免 BLE 设备断电时的竞态条件
- **自动取消**：连接成功后停止定时器

### CaptureProvider 应用层保活

```dart
// lib/providers/capture_provider.dart

class CaptureProvider extends BaseProvider {
  Timer? _keepAliveTimer;
  DateTime? _keepAliveLastExecutedAt;

  void _startKeepAliveServices() {
    _keepAliveTimer?.cancel();

    _keepAliveTimer = Timer.periodic(const Duration(seconds: 15), (t) async {
      // 限流：每15秒最多执行一次
      if (_keepAliveLastExecutedAt != null &&
          DateTime.now().subtract(const Duration(seconds: 15))
              .isBefore(_keepAliveLastExecutedAt!)) {
        return;
      }

      _keepAliveLastExecutedAt = DateTime.now();

      // 检查是否需要保活
      if (!recordingDeviceServiceReady ||
          _socket?.state == SocketServiceState.connected) {
        t.cancel();
        return;
      }

      // 重新初始化 WebSocket
      if (_recordingDevice != null) {
        BleAudioCodec codec = await _getAudioCodec(_recordingDevice!.id);
        await _initiateWebsocket(
          audioCodec: codec,
          source: _getConversationSourceFromDevice()
        );
      }
    });
  }

  @override
  void onError(Object err) {
    _startKeepAliveServices();  // 错误时启动保活
  }
}
```

---

## Apple Watch 通信方案

### 双路传输策略

Apple Watch 使用 WatchConnectivity 框架，采用双路传输保证后台可靠性：

```swift
// ios/omiWatchApp/WatchAudioRecorderViewModel.swift

class WatchAudioRecorderViewModel {
    private let bufferDuration: TimeInterval = 1.5  // 1.5秒分块

    func sendAudioChunk(_ data: Data, chunkIndex: Int, isLast: Bool) {
        let messageData: [String: Any] = [
            "method": "sendAudioChunk",
            "audioChunk": data,
            "chunkIndex": chunkIndex,
            "isLast": isLast,
            "sampleRate": 16000.0
        ]

        // 双路传输
        if session.isReachable {
            // 前台/可达：使用 sendMessage（即时）
            session.sendMessage(messageData, replyHandler: nil) { error in
                // 失败时回退到 transferUserInfo
                self.session.transferUserInfo(messageData)
            }
        } else {
            // 后台/不可达：使用 transferUserInfo（保证送达）
            session.transferUserInfo(messageData)
        }
    }
}
```

### iPhone 端接收

```swift
// ios/Runner/AppDelegate.swift

extension AppDelegate: WCSessionDelegate {
    // 前台消息接收
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleWatchMessage(message)
    }

    // 后台消息接收（关键！）
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        // 即使 App 在后台或被挂起，此方法也会被调用
        handleWatchMessage(userInfo)
    }
}
```

**关键点**：
- **1.5秒分块**：平衡延迟与传输可靠性
- **双路策略**：`sendMessage` 优先，失败回退 `transferUserInfo`
- **`transferUserInfo`**：iOS 保证送达，即使 App 被挂起

---

## WebSocket 保活策略

### 固定周期 Ping + 指数退避重连

```dart
// lib/services/sockets/pure_socket.dart

class PureSocket {
  WebSocketChannel? _channel;
  int _retries = 0;

  Future<bool> _connect() async {
    _channel = IOWebSocketChannel.connect(
      url,
      headers: headers,
      pingInterval: const Duration(seconds: 20),  // 20秒 ping
      connectTimeout: const Duration(seconds: 15),
    );

    _channel?.stream.listen(
      (message) {
        if (message == "ping") {
          _channel?.sink.add([0x8A, 0x00]);  // 手动响应 pong
          return;
        }
        onMessage(message);
      },
      onError: (error) => _reconnect(),
      onDone: () => _reconnect(),
    );

    return true;
  }

  void _reconnect() async {
    const int initialBackoffTimeMs = 1000;
    const double multiplier = 1.5;
    const int maxRetries = 8;

    // 指数退避计算
    int waitMs = pow(multiplier, _retries).toInt() * initialBackoffTimeMs;
    await Future.delayed(Duration(milliseconds: waitMs));

    _retries++;
    if (_retries > maxRetries) {
      _listener?.onMaxRetriesReach();
      return;
    }

    _reconnect();
  }
}
```

### 重连间隔计算

| 重试次数 | 等待时间 |
|---------|---------|
| 1 | 1.0s |
| 2 | 1.5s |
| 3 | 2.25s |
| 4 | 3.4s |
| 5 | 5.1s |
| 6 | 7.6s |
| 7 | 11.4s |
| 8 | 17.1s |

**总超时**：约 49 秒后放弃

---

## 最佳实践

### 1. 不要实现固定心跳

```dart
// ❌ 错误做法：固定周期心跳
Timer.periodic(Duration(seconds: 5), (_) {
  bleDevice.ping();
});

// ✅ 正确做法：事件驱动 + 系统后台模式
connectionStateStream.listen((state) {
  if (state == DeviceTransportState.disconnected) {
    startReconnectionTimer();
  }
});
```

### 2. 合理设置重连间隔

| 场景 | 推荐间隔 | 说明 |
|-----|---------|-----|
| 普通设备 | 15秒 | 平衡电量与及时性 |
| 关键设备 | 5秒 | 如 AI Note |
| WebSocket | 指数退避 | 避免服务器压力 |

### 3. 断开重连必须延迟

```dart
void onDeviceDisconnected() {
  // 1秒延迟，避免 BLE 设备断电时的竞态条件
  Future.delayed(const Duration(seconds: 1), () {
    startReconnection();
  });
}
```

### 4. 限流保护

```dart
DateTime? _lastExecutedAt;

void keepAlive() {
  if (_lastExecutedAt != null &&
      DateTime.now().difference(_lastExecutedAt!) < Duration(seconds: 15)) {
    return;  // 限流
  }
  _lastExecutedAt = DateTime.now();
  // 执行保活逻辑
}
```

### 5. Watch 通信必须双路

```swift
// 始终准备 transferUserInfo 作为后备
if session.isReachable {
  session.sendMessage(data) { error in
    session.transferUserInfo(data)  // 失败回退
  }
} else {
  session.transferUserInfo(data)
}
```

### 6. 后台模式组合推荐

| 场景 | 推荐后台模式 |
|-----|------------|
| BLE 设备通信 | `bluetooth-central` |
| 音频流传输 | `bluetooth-central` + `audio` |
| 位置追踪 | `bluetooth-central` + `location` |
| 推送唤醒 | `bluetooth-central` + `remote-notification` |

---

## 文件索引

### 平台配置文件

| 文件 | 职责 |
|-----|------|
| `ios/Runner/Info.plist` | iOS 后台模式配置 |
| `android/app/src/main/AndroidManifest.xml` | Android 权限与服务声明 |
| `android/app/.../NotificationOnKillService.kt` | Android 任务移除恢复服务 |
| `android/app/.../MainActivity.kt` | Android 服务启动桥接 |

### Flutter 核心文件

| 文件 | 职责 |
|-----|------|
| `lib/utils/audio/foreground.dart` | Flutter 前台服务配置 |
| `lib/services/services.dart` | 后台麦克风服务 |
| `lib/providers/device_provider.dart` | 设备连接状态管理 |
| `lib/providers/capture_provider.dart` | 录音/转写保活 |
| `lib/services/sockets/pure_socket.dart` | WebSocket 客户端 |

### iOS 原生文件

| 文件 | 职责 |
|-----|------|
| `ios/Runner/AppDelegate.swift` | WatchConnectivity 代理 |
| `ios/omiWatchApp/WatchAudioRecorderViewModel.swift` | Watch 端录音 |

### 依赖包

```yaml
# pubspec.yaml
dependencies:
  flutter_blue_plus: ^1.33.6         # BLE 通信
  flutter_foreground_task: ^8.11.0   # 前台服务
  flutter_background_service: ^5.0.5 # 后台服务
  web_socket_channel: ^2.4.0         # WebSocket
```

---

## 总结

### iOS 后台保活核心思路

1. **信任系统**：使用 `bluetooth-central` 后台模式，让 iOS 管理 BLE 连接
2. **事件驱动**：断开时启动重连定时器，连接后取消
3. **双路保障**：Watch 通信使用 `sendMessage` + `transferUserInfo` 双路

### Android 后台保活核心思路

1. **前台服务**：持久通知提高进程优先级
2. **多重保活**：START_STICKY + onTaskRemoved + WakeLock
3. **心跳监控**：5秒 ping/pong 检测 UI 崩溃

### 跨平台共同策略

1. **分层处理**：Transport 层负责通信，Provider 层负责重连策略
2. **合理限流**：避免频繁重连消耗电量
3. **指数退避**：WebSocket 重连避免服务器压力

---

*文档版本：2.0*
*基于 Omi Flutter App 实现*
*最后更新：2026-01-19*
