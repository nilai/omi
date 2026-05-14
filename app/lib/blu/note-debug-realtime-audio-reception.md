# Note Debug 页面如何接收实时音频

> 记录 Omi Flutter app 中 BLE Debug 页面 (`note_ble_debug_page.dart`) 接收 Note 设备实时音频的完整链路。  
> 适用版本：本仓库 `lib/services/devices/transports/note_ble_transport.dart` 的 V1.0 协议实现。

---

## 一句话总结

UI 上的 **「Audio Debug → 开始保存」** 按钮触发 `NoteBleDebugProvider.startSavingAudio()`，订阅 `bleTransport.audioStream`（一条 `Broadcast<List<int>>` 流，源头是 `flutter_reactive_ble` 对音频特征 `e2c1a301-…` 的 `subscribeToCharacteristic` notify，原始包经 `AudioPacketReassembler` 自动识别两种格式并重组成 480B Opus 帧），把每一帧**原样**追加写入 `audio_debug_<timestamp>.opus`；**实时阶段不做解码**，只有用户点「转换验证」时才走 `AudioConverterUtils.convertOpusToMp3()` → opus_flutter 解码 → WAV → flutter_lame → MP3。

---

## 1. UI 入口

文件：`lib/pages/note_debug/note_ble_debug_page.dart:190-198`

```dart
// Audio Debug (Save to File)
CommandCategorySection(
  title: 'Audio Debug',
  icon: Icons.save_alt,
  children: [
    _buildAudioSaveStatus(provider),
    _buildAudioSaveButton(provider),
  ],
),
```

两个子部件：
- `_buildAudioSaveStatus` — 实时显示 `packets received` / `bytes saved` / 保存路径。
- `_buildAudioSaveButton` — 「开始保存 / 停止保存 / 转换验证」三态按钮，分别绑定 provider 的 `startSavingAudio()`、`stopSavingAudio()`、`convertSavedAudio()`。

---

## 2. Provider — 状态与生命周期

文件：`lib/providers/note_ble_debug_provider.dart:611-768`

字段：
- `_isSavingAudio: bool` — UI 状态闸
- `_audioPacketsReceived: int` — 已接收包计数
- `_audioBytesSaved: int` — 已落盘字节数
- `_savedAudioPath: String?` — 当前 `.opus` 文件绝对路径
- `_audioFileSink: IOSink?` — 文件写入句柄
- `_audioSaveSubscription: StreamSubscription<List<int>>?` — 音频流订阅

核心方法 `startSavingAudio()`（`:614-689`）：
1. 检查 `_connection != null`，否则 `_lastError = 'Device not connected'`
2. 选择目录：Android → `getExternalStorageDirectory()`，其它 → `getApplicationDocumentsDirectory()`（`:629-632`）
3. 生成路径 `${dir}/audio_debug_${ISO8601_safe}.opus`（`:633-634`）
4. `file.openWrite()` 得到 `IOSink`（`:638`）
5. **订阅音频流**（`:647-678`，关键代码）：

```dart
_audioSaveSubscription = _connection!.bleTransport.audioStream.listen(
  (data) {
    _audioPacketsReceived++;
    _audioBytesSaved += data.length;
    _audioFileSink?.add(data);                           // 原样落盘
    // 前 10 包逐个日志，之后每 10s 节流一次
    final shouldLog = _audioPacketsReceived <= 10 ||
        _lastLogTime == null ||
        now.difference(_lastLogTime!).inSeconds >= 10;
    if (shouldLog) {
      print('[AudioDebug] 保存包#$_audioPacketsReceived: ${data.length}bytes, '
            '总计=$_audioBytesSaved bytes');
      notifyListeners();
    }
  },
  onError: (e, st) { _lastError = 'Audio stream error: $e'; … },
  onDone: ()       { _lastError = '音频流已结束 (共 $_audioPacketsReceived 包)'; … },
  cancelOnError: false,
);
```

`stopSavingAudio()`（`:692-719`）：取消 subscription → `flush()` → `close()` 文件句柄 → 复位 `_isSavingAudio`。

---

## 3. 数据源 — `bleTransport.audioStream`

文件：`lib/services/devices/transports/note_ble_transport.dart`

类型声明（`:275`）：

```dart
final _audioDataController = StreamController<List<int>>.broadcast();
…
Stream<List<int>> get audioStream => _audioDataController.stream;   // :397
```

写入方（`:316-322`，构造函数里把 reassembler 完成回调接到 controller）：

```dart
_reassembler = AudioPacketReassembler(
  tag: 'RT',
  onFrameComplete: (seq, frame) {
    _audioDataController.add(frame);   // ← provider 在这里收到一帧
  },
  onSeqGap: (expectedSeq, receivedSeq) { … 日志/上报 … },
);
```

注意：debug 页面订阅的是**重组后的完整帧**，不是 BLE 原始包。还有第二个 `_fileReassembler`（`:310`、`:334`）是录音文件下载用的，跟实时音频无关。

---

## 4. BLE 订阅层 — UUID 与 notify

文件：`lib/services/devices/note_commands.dart`

> 字面值：service = `e2c1a300-7f4b-5e9d-bc23-1a2f3e4d5c6b`，audioData = `e2c1a301-7f4b-5e9d-bc23-1a2f3e4d5c6b`。

```dart
class NoteUUIDs {
  static const uuidPre = "e2c1a30";
  static final service   = Uuid.parse("${uuidPre}0-7f4b-5e9d-bc23-1a2f3e4d5c6b");  // :14
  static final audioData = Uuid.parse("${uuidPre}1-7f4b-5e9d-bc23-1a2f3e4d5c6b");  // :17  ← 实时音频
  static final command   = Uuid.parse("${uuidPre}2-…");
  static final response  = Uuid.parse("${uuidPre}3-…");
  static final otaFile   = Uuid.parse("${uuidPre}4-…");
  static final recordFile= Uuid.parse("${uuidPre}5-…");  // 录音文件下载，与实时音频分开
  static final logFile   = Uuid.parse("${uuidPre}6-…");
}
```

订阅代码 `note_ble_transport.dart:710-759`：

```dart
final audioChar = QualifiedCharacteristic(
  serviceId: NoteUUIDs.service,
  characteristicId: NoteUUIDs.audioData,
  deviceId: device.id,
);
_audioSubscription = _ble.subscribeToCharacteristic(audioChar).listen(
  (data) {
    rawPacketCount++;
    if (rawPacketCount <= 10) { /* 调试：打印原始包头与格式判定 */ }
    _reassembler.process(data);   // 进入重组器
  },
  onError: (e) => _handleSubscriptionError('音频', e),
  onDone:  ()  => print('[BLE Audio] ⚠️ 音频流结束!'),
  cancelOnError: false,
);
```

`_ble` 是 `flutter_reactive_ble`，`subscribeToCharacteristic` 自动启用 GATT notify（不是 indicate）。

---

## 5. 重组器 — `AudioPacketReassembler`

文件：`lib/services/devices/transports/note_ble_transport.dart:33-232`

**支持两种包格式，按长度自动识别（`:99-100`）：**

| 格式 | 头部 | 数据区 | 总长 | 说明 |
|------|------|--------|------|------|
| **无 Flag**（当前固件实际行为） | `Seq 4B` | `Data 480B` | **484B** | 一包即一帧，不需要分包 |
| **有 Flag**（协议文档定义） | `Seq 4B` + `Flag 1B` | 变长 | 485+ | `Flag` 高低位编码 `total/index`，需要重组 |

判定逻辑（`:100`）：

```dart
final isNoFlagFormat =
    (rawPacket.length == AudioPacketConstants.headerSizeSeqOnly
                       + AudioPacketConstants.frameSize);   // 4 + 480 == 484
```

- **无 Flag 路径**（`:102-113`）：截掉前 4B，直接 `_onFrameReady(seq, data)`。
- **有 Flag 路径**（`:115-170`）：
  - `flag == 0x00` → 单包不分包，直接 emit。
  - 否则按 `flag` 解出 `total/partIndex`，缓存到 `_pending[seq][partIndex]`；凑齐 `total` 个子包后按序拼接 emit。
  - `_pending.length >= 50` 时丢弃最旧 seq（`:141-146`）。
  - 重组超时 `AudioPacketConstants.reassemblyTimeoutMs`（`:200`），超时清空 `_pending` 并计入 `_discardedFrameCount`。

**Seq 间隙检测**（`:183-195`）：每帧完成时比较 `seq` 与 `_lastCompletedSeq+1`，缺失时回调 `onSeqGap(gapStart, seq)`。Debug provider 用这个做补传测试。

---

## 6. 编解码 — 何时解码？

**实时阶段：不解码。** 落盘的 `.opus` 是设备直出的 Opus 帧（每帧 40 字节，CBR 16 kbps，20 ms/帧；一次 480B 即 12 帧 = 240 ms 音频）。

**「转换验证」阶段**：`NoteBleDebugProvider.convertSavedAudio()`（`:722-768`）调用 `AudioConverterUtils.convertOpusToMp3()`，文件 `lib/utils/audio_converter_utils.dart:35-86`：

```
.opus  ─ opus_flutter.load() + _OpusDecoderFFI ─►  PCM16 16kHz mono
PCM16  ─ _saveAsWav (44B header + raw PCM)      ─►  .wav  (中间产物，便于调试)
.wav   ─ flutter_lame                            ─►  .mp3
```

依赖：
- `opus_flutter: any`（FFI wrapper，加载 libopus）
- `flutter_lame: any`（MP3 编码）

时长自校验（`:756-764`）：转换完成后用 WAV 大小 ÷ (16000×2) 算出秒数，与 `fileSize/40 × 0.02` 的理论值比对，误差 >0 秒会打到日志。

---

## 7. 完整数据通路

```
┌──────────────┐   GATT Notify on UUID 301        ┌─────────────────────┐
│  Note 设备   │ ───────────────────────────────► │  flutter_reactive_  │
│ (Opus 16kbps)│        484B 原始包                │  ble subscribe…     │
└──────────────┘                                  └──────────┬──────────┘
                                                             │ List<int> 原始
                                                             ▼
                                              ┌──────────────────────────┐
                                              │ AudioPacketReassembler   │
                                              │  · 长度判定无/有 Flag    │
                                              │  · 分包缓冲(_pending)    │
                                              │  · Seq 间隙回调          │
                                              └────────────┬─────────────┘
                                                           │ 480B 完整帧
                                                           ▼
                                              ┌──────────────────────────┐
                                              │ _audioDataController     │
                                              │ StreamController.broadcast│
                                              └────────────┬─────────────┘
                                                           │ audioStream (Stream<List<int>>)
                                                           ▼
                                              ┌──────────────────────────┐
                                              │ NoteBleDebugProvider     │
                                              │  _audioSaveSubscription  │
                                              │  · 计数+UI 节流通知       │
                                              │  · IOSink.add(data)       │
                                              └────────────┬─────────────┘
                                                           │
                                                           ▼
                                              audio_debug_<ISO>.opus
                                              (原始 Opus 帧拼接)

  ── 用户点「转换验证」时 ───────────────────────────────────────────────
                                                           │
                                                           ▼
                                          AudioConverterUtils.convertOpusToMp3
                                          opus_flutter → PCM → .wav → flutter_lame → .mp3
```

---

## 8. 与生产采集路径（capture_provider）的对比

| 维度 | Debug 页面 (`NoteBleDebugProvider`) | 生产采集 (`CaptureProvider`) |
|------|--------------------------------------|------------------------------|
| 触发 | UI 按钮手动开关 | 录音状态机自动 |
| 流源 | `bleTransport.audioStream`（重组后帧） | 同一条流（`connection.getBleAudioBytesListener()` 抽象） |
| 编解码 | **采集期不解码**，落盘原始 Opus | 直接转发至转录 WebSocket，由后端处理 |
| 输出 | `audio_debug_<ts>.opus` + 可选 `.mp3` | 实时上行转录，不落盘 |
| 编解码器 | 硬编码 Opus（Note 设备就是 Opus） | 从 `BtDevice.audioCodec` 读，多设备通用 |
| Seq/丢帧 | 由 reassembler 计数 + `onSeqGap` 回调，UI 展示补传测试用 | 同一回调，但用途偏诊断/上报 |

**关键差异**：debug 页面的设计目标是「**抓现场**」—— 把设备直出的原始字节流忠实落盘，便于离线复盘和工具链对拍；生产路径则是「**走管道**」—— 数据进入立即上行，不留本地副本。

---

## 9. 排障线索（按现象→看哪里）

| 现象 | 第一站 |
|------|--------|
| 点「开始保存」无反应 | `note_ble_debug_provider.dart:614-625`（连接检查 + `_isSavingAudio` 闸） |
| `onDone` 触发，流提前结束 | BLE 连接断开 / 系统取消订阅 → `note_ble_transport.dart:753-756` |
| 文件大小不是 40 的整数倍 | 包格式判定错位 → `AudioPacketReassembler:84-113`（看前 10 包打印的 `head=[…]`） |
| MP3 时长 ≠ 预期 | `convertSavedAudio` 自检日志（`:761-763`）+ opus 解码失败 → `audio_converter_utils.dart:108-112` |
| 「Seq 间隙」频繁 | 实时丢包，`AudioPacketReassembler._onFrameReady:184-189` |

---

## 10. 引用一览（file:line）

- `lib/pages/note_debug/note_ble_debug_page.dart:190-198`（UI 入口）
- `lib/providers/note_ble_debug_provider.dart:614-689`（startSavingAudio）
- `lib/providers/note_ble_debug_provider.dart:692-719`（stopSavingAudio）
- `lib/providers/note_ble_debug_provider.dart:722-768`（convertSavedAudio）
- `lib/services/devices/transports/note_ble_transport.dart:33-232`（AudioPacketReassembler）
- `lib/services/devices/transports/note_ble_transport.dart:275`（_audioDataController.broadcast）
- `lib/services/devices/transports/note_ble_transport.dart:316-322`（reassembler→stream wiring）
- `lib/services/devices/transports/note_ble_transport.dart:397`（audioStream getter）
- `lib/services/devices/transports/note_ble_transport.dart:710-759`（_subscribeCharacteristics: audio）
- `lib/services/devices/note_commands.dart:10-37`（NoteUUIDs）
- `lib/utils/audio_converter_utils.dart:35-86`（convertOpusToMp3 pipeline）

---

*最后更新：2026-05-14（由 Algorithm v6.3.0 / E2 记录）*
