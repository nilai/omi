# Note 设备录音功能 API 使用指南 (normal / memo)

> **文档类型**：API 调用速查（cookbook 风格）
> **目标读者**：开发录音相关 UI / 业务逻辑的工程师
> **互补文档**：
> - 完整 BLE API 索引 → [`ble-api-documentation.md`](./ble-api-documentation.md)
> - 文件传输协议详解 → 同上文档第"文件传输协议详解"章节

本文档聚焦"**给定一个录音业务场景，应该调用哪些 API**"。所有示例均基于 `e2c1a30x` 协议下已实现的方法（分支 `v1.0_ble`）。

---

## 0. 速览：两种录音的关键差异

| 维度 | Normal（正式录音） | Memo（备忘录/灵感） |
|------|-------------------|---------------------|
| 触发方式 | 长按 2.5s | 关闭录音状态下短按 |
| Mode 字节 | `0x00` | `0x01` |
| 时长 | 不限（每 5 min split 新文件） | **固定 ≤60s** |
| 时间戳文件 (`.txt`) | 录音中再短按可标记 | 不适用 |
| 中断方式 | 再长按 2.5s | 60s 闪烁内再短按 / 长按切 normal |
| 文件落点 | `NoteDownloads/` | `NoteDownloads/`（与 normal 同列表） |
| 业务用途 | 会议/对话 | 1 分钟灵感速记 |

> **注意**：Mode 由设备按键决定，**APP 不能通过命令指定**。APP 端只能从设备通知 byte[3] 解析。

---

## 1. 监听录音开始（被动事件）

设备按键启动 / APP 主动启动 / split 续录 → 都会广播到同一个事件流。

### 1.1 订阅 onRecordingStarted

```dart
final connection = ServiceManager.instance().device.activeConnection
    as NoteDeviceConnection;

final sub = connection.onRecordingStarted.listen((event) {
  // event.fileName : "20260512_103045.opus"
  // event.type     : NoteRecordingType.normal | memo
  if (event.type == NoteRecordingType.memo) {
    // memo — UI 显示快闪 + 60s 倒计时
  } else {
    // normal — UI 显示常亮录音指示
  }
});
```

**API 路径**：`NoteDeviceConnection.onRecordingStarted` →
`Stream<({String fileName, NoteRecordingType type})>`
（声明位置：`note_connection.dart:106`）

### 1.2 内部自动行为（无需手动调用）

收到通知后，`_applyRecordingStarted` 会自动完成 4 件事：

1. 更新 `_currentRecordingFileName` / `_currentRecordingType`
2. 启动 `NoteAudioFileWriter`（写到 `NoteDownloads/<fileName>`）
3. 调用 `_storage.appendRecordingMode(fileName, type)` 持久化 (fileName → mode) 索引
4. 广播事件到 `onRecordingStarted`

> 所以业务侧**只需订阅事件**，不需要重复启动写入器。

---

## 2. 监听录音结束（被动事件）

### 2.1 订阅 onRecordingStopped

```dart
final sub = connection.onRecordingStopped.listen((result) {
  final fileName = result['fileName'] as String?;
  final fileId   = result['fileId'] as int?;       // 设备全局文件计数
  final isSplit  = result['split'] == true;        // true=超时分片自动停止

  if (isSplit) {
    // 设备会立即开始下一个文件 — 等 onRecordingStarted 即可
    return;
  }

  // 普通停止：触发后续下载/转码
});
```

**API 路径**：`NoteDeviceConnection.onRecordingStopped` →
`Stream<Map<String, dynamic>>`
（声明位置：`note_connection.dart:77`）

**事件来源**（统一通道）：
- 用户主动调用 `connection.stopRecording()`
- 设备按键长按 2.5s 关闭
- memo 60s 自然结束 / 短按提前结束
- 超时分片（`result == 0x03` → `split: true`）

### 2.2 result 字段对照

| key | 类型 | 含义 |
|-----|------|------|
| `success` | `bool` | 是否成功停止 |
| `fileName` | `String` | 录音文件名 (UTF-8) |
| `fileId` | `int` | 设备全局文件计数 (1B，跨天累加) |
| `split` | `bool?` | true 表示超时自动分片续录 |
| `error` | `String?` | 失败原因 (`file_error`/`exception`) |

---

## 3. 主动控制录音

### 3.1 主动开始（仅触发 normal，无法触发 memo）

```dart
final result = await connection.startRecordingWithStatus();
switch (result) {
  case RecordingStartResult.success:
    // 0x01 0x01 [state] [mode=0x00] [filename] — 总是 normal
    break;
  case RecordingStartResult.alreadyRecording:
    // 设备已在录音
    break;
  case RecordingStartResult.failed:
    // 命令失败
    break;
}
```

**协议**：发送 `[0x01, 0x00, 0x00]`，等待响应。
**API**：`note_connection.dart:654` `Future<RecordingStartResult> startRecordingWithStatus()`

> ⚠️ APP 主动调用**只能产生 normal 录音**。memo 必须由设备按键触发。

### 3.2 主动停止

```dart
final result = await connection.stopRecording();
if (result['success'] == true) {
  final fileName = result['fileName'];
  // 注意：本调用同时也会触发 onRecordingStopped 事件
}
```

**协议**：`[0x02, 0x00]`
**API**：`note_connection.dart:711` `Future<Map<String, dynamic>> stopRecording()`

> 主动调用 `stopRecording()` 时，事件流仍会收到通知；监听者需注意 **不重复处理**（Provider 层通常通过 `_responseCompleter` 是否存在来区分）。

---

## 4. 区分 Normal vs Memo

### 4.1 实时区分（开始通知中）

```dart
connection.onRecordingStarted.listen((event) {
  switch (event.type) {
    case NoteRecordingType.normal:  // mode = 0x00
    case NoteRecordingType.memo:    // mode = 0x01
  }
});
```

### 4.2 通过 currentRecordingType 即时查询

```dart
final type = connection.currentRecordingType;  // null 表示当前未录音
// 来源：note_connection.dart:101
```

### 4.3 通过 fileName → mode 索引（历史文件）

```dart
final storage = connection.storageManager;
final mode = await storage.getRecordingMode(fileName);
// 来源：NoteStorageManager.appendRecordingMode 持久化的索引
```

---

## 5. 处理 Memo → Normal 切换

**场景**：用户在 memo 录音中长按 2.5s，要求中断 memo 切到 normal。

设备会**顺序发出两个通知**，APP 自然衔接：

```dart
connection.onRecordingStopped.listen((result) {
  // 第 1 步：memo 文件已保存
  if (result['fileName']?.endsWith('.opus') == true) {
    // 业务可在此触发 memo 文件下载（如果需要）
  }
});

connection.onRecordingStarted.listen((event) {
  // 第 2 步：紧接着 normal 录音开始
  if (event.type == NoteRecordingType.normal) {
    // _applyRecordingStarted 内部自动重置文件写入器
  }
});
```

**无需手动调用任何方法** — 只要订阅了两个事件流就能正确响应这种切换。

---

## 6. 时间戳文件（录音中短按）

**协议表现**：录音过程中，用户在设备上短按按钮 → 设备生成一个 `.txt` 时间戳文件，文件名形如 `20260512_103210.txt`。该文件出现在 `getFileList()` 响应中，需 APP 主动下载。

### 6.1 列出文件并区分类型

```dart
import 'package:omi/services/devices/note_timestamp_file.dart';

final files = await connection.getFileList();
for (final file in files) {
  if (isNoteTimestampFileName(file.name)) {
    // .txt 时间戳文件
  } else {
    // .opus 录音 (normal 或 memo, 需查 mode 索引区分)
  }
}
```

### 6.2 下载（自动路由到独立目录）

```dart
final fileListProvider = Provider.of<NoteFileListProvider>(context, listen: false);
await fileListProvider.downloadFile(file);
// 内部自动判断:
//   .txt → NoteTimestamps/  (纯字节流模式, _isRawFileTransfer=true)
//   .opus → NoteDownloads/  ([Seq 4B][480B] 分帧)
```

**API 路径**：
- 类型识别：`isNoteTimestampFileName()` (`note_timestamp_file.dart:15`)
- 路由判定：`note_file_list_provider.dart:305-311`
- 模式切换：`NoteBleTransport.resetFileReassembler()` (`note_ble_transport.dart:365-373`)

### 6.3 列出本地全部时间戳文件（批量上传场景）

```dart
final files = await listNoteTimestampFiles();  // 返回 List<File>
// 或通过 provider:
final files = await fileListProvider.listTimestampFiles();
```

---

## 7. 录音文件下载 + MP3 转码

### 7.1 自动触发（推荐路径）

`NoteBleDebugProvider` 内置自动下载转码，触发时机：

```dart
// 自动触发场景（无需手动调用）：
// 1. 用户主动停止录音 → sendStopRecording() 成功后
// 2. 设备主动停止 → onRecordingStopped 事件
// 3. 重连后待下载 → onPendingDownloads 事件

// 监听三阶段状态
final stage = debugProvider.downloadConvertStage;
// DownloadConvertStage.downloading | converting | null

final progress = debugProvider.downloadConvertProgress;  // 0.0 ~ 1.0
final mp3Path  = debugProvider.convertedMp3Path;         // 转码完成后
final error    = debugProvider.downloadConvertError;
```

**API 路径**：`note_ble_debug_provider.dart:774-870`

### 7.2 手动触发（业务场景）

```dart
// 仅下载，不转码
await fileListProvider.downloadFile(noteFileInfo);
final opusPath = fileListProvider.lastDownloadedFilePath;

// 单独转码
await fileListProvider.convertToMp3(opusPath);
final mp3Path = fileListProvider.lastConvertedMp3Path;

// 一步：下载完后直接转最近一个
await fileListProvider.convertLastDownloadedToMp3();
```

### 7.3 已转码缓存检查

```dart
final exists = await fileListProvider.hasConvertedMp3(opusPath);
final cached = await fileListProvider.getConvertedMp3Path(opusPath);
// 文件命名规则: <opus>.opus → <opus>.mp3 (同目录同名替换扩展名)
```

---

## 8. 重连后处理待下载文件

**场景**：APP 与设备断开期间，用户在设备上完成了一段录音；重连后该文件需补下载。

```dart
final pendingSub = connection.onPendingDownloads.listen((files) {
  // files: List<String> — 文件名列表
  // NoteBleDebugProvider 已自动调用 _startDownloadAndConvert(fileName) 下载并转码
  // 业务侧通常只需展示进度即可
});

// 也可即时查询
final pending = connection.pendingDownloadFiles;
connection.clearPendingDownloads();  // 处理完后清空
```

**API 路径**：`NoteDeviceConnection.onPendingDownloads` (`note_connection.dart:81`)

**触发条件（三场景判定）**：见 `_restoreRetransmitStateOnReconnect` (`note_connection.dart:366-415`):
- 场景 A：设备仍在录原文件 → 不入待下载，走补传
- 场景 B：设备录新文件 → 旧文件入待下载
- 场景 C：设备空闲 → 旧文件入待下载

---

## 9. UI 状态展示建议

基于现有 API 字段，UI 至少应展示：

| UI 元素 | 数据来源 |
|--------|---------|
| 当前是否录音 | `connection.currentRecordingType != null` |
| 当前类型 (Normal / Memo) | `connection.currentRecordingType` |
| 文件名 | `_currentRecordingFileName` 或事件中的 `fileName` |
| Memo 倒计时 | 从 `onRecordingStarted` 时刻起 60s 倒计时（设备端实际计时） |
| 实时帧统计 | `connection.bleTransport.completedFrameCount` |
| 最后帧序号 | `connection.bleTransport.lastCompletedSeq` |
| Seq 间隙数 | `connection.getSeqGaps().length` |
| 下载进度 | `fileListProvider.downloadProgress` |
| 转码进度 | `fileListProvider.conversionProgress` |
| 待下载文件数 | `connection.pendingDownloadFiles.length` |
| 电量 / 充电 | `connection.performRetrieveBatteryLevel()` |

---

## 10. Provider 层方法速查

### NoteBleDebugProvider（Debug 页面用）

| 方法 | 说明 |
|------|------|
| `sendStartRecording()` | 主动开始 normal 录音；带状态码返回 |
| `sendStopRecording()` | 主动停止；成功后**自动触发** `_startDownloadAndConvert` |
| `sendSetRecordingMode(mode)` | 设置推流策略（仅录音 / 边录边传） |
| `lastRecordingFileName` | 最近一次录音的文件名（停止后填充） |
| `downloadConvertStage` | 自动流程当前阶段 |
| `convertedMp3Path` | 自动流程产物 |
| `testRetransmit(name, start, end)` | 手动发起补传请求（调试用） |

### NoteFileListProvider（文件管理用）

| 方法 | 说明 |
|------|------|
| `refreshFileList()` | 拉取设备上的全部文件 |
| `downloadFile(file)` | 下载单文件，自动按 `.txt` 路由 |
| `cancelDownload()` | 取消并删除不完整文件 |
| `deleteFile(file)` | 按文件名删除设备上的文件 |
| `convertToMp3(path)` | Opus → MP3 转码 |
| `convertLastDownloadedToMp3()` | 转最近一个下载完成的文件 |
| `hasConvertedMp3()` / `getConvertedMp3Path()` | 缓存查询 |
| `getDownloadPath()` / `getTimestampFolderPath()` | 目录获取 |
| `listTimestampFiles()` | 枚举本地 .txt 文件 |

---

## 11. 不支持 / 待澄清项

| 功能 | 当前 API 状态 | 备注 |
|------|--------------|------|
| 麦克风增益调节 | ❌ 协议未定义命令字 | 产品定义 §1.2.c.ii 要求"软件可调"，但 `NoteCommands` 中无对应命令；`performSetMicGain` 是空实现 |
| Memo 时长自定义 | ❌ 设备端固定 60s | APP 不可调整 |
| APP 主动触发 memo 录音 | ❌ 仅按键可触发 | 协议设计如此 |
| 录音中实时打点事件流 | ⚠️ 待澄清 | 现有 `.txt` 时间戳走文件传输流（停止后才能下），如果设备实际是录音中实时推送事件，需新增通道 |

---

## 12. 一句话指南

- 业务侧**只需订阅 3 个事件流** + **使用 1 个 Provider**：
  - `connection.onRecordingStarted` / `onRecordingStopped` / `onPendingDownloads`
  - `NoteFileListProvider`（列表 / 下载 / 转码 / 时间戳路由）
- **不需要手动启动文件写入器** — `_applyRecordingStarted` 已经在内部完成
- **不需要手动监听 0x04 0x02 完成信号** — Provider 已封装
- **不要尝试用命令切换 normal/memo** — 协议设计上由设备按键决定
