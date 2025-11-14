# 录音上传功能开发文档

> 本文档详细记录了 Omi 应用中新增的录音上传功能的设计、实现和使用方法。

**创建日期**: 2025-01-13
**功能版本**: v1.0
**开发状态**: ✅ 已完成

---

## 📋 目录

1. [功能概述](#功能概述)
2. [架构设计](#架构设计)
3. [文件结构](#文件结构)
4. [API 接口说明](#api-接口说明)
5. [使用指南](#使用指南)
6. [代码示例](#代码示例)
7. [测试验证](#测试验证)
8. [扩展建议](#扩展建议)
9. [常见问题](#常见问题)

---

## 1. 功能概述

### 1.1 功能简介

录音上传功能允许用户选择本地音频文件并上传到服务器，采用预签名 URL 的方式直接上传到 S3 对象存储，避免音频文件经过应用服务器，提高性能和安全性。

### 1.2 核心特性

- ✅ **三步上传流程**：获取预签名URL → 上传到S3 → 创建录音记录
- ✅ **多格式支持**：M4A、WAV、MP3、AAC
- ✅ **实时进度显示**：步骤级进度反馈（1/3、2/3、3/3）
- ✅ **错误处理**：自动重试（网络错误）、友好的错误提示
- ✅ **文件验证**：大小、格式、有效性检查
- ✅ **深度链接**：支持 `omi://audio-records` 打开页面

### 1.3 技术栈

- **状态管理**: Provider
- **文件选择**: file_picker
- **网络请求**: http (已有)
- **序列化**: json_serializable

---

## 2. 架构设计

### 2.1 四层架构

严格遵循 Omi 应用的四层架构模式：

```
┌─────────────────────────────────────────────────────────┐
│                    UI 层 (Presentation)                  │
│         AudioRecordPage + AudioUploadWidget             │
└───────────────────────┬─────────────────────────────────┘
                        │ Consumer<AudioRecordProvider>
                        ↓
┌─────────────────────────────────────────────────────────┐
│               状态管理层 (State Management)                │
│                 AudioRecordProvider                      │
└───────────────────────┬─────────────────────────────────┘
                        │ 调用服务接口
                        ↓
┌─────────────────────────────────────────────────────────┐
│                  服务层 (Business Logic)                  │
│                  AudioRecordService                      │
└───────────────────────┬─────────────────────────────────┘
                        │ HTTP/S3 Upload
                        ↓
┌─────────────────────────────────────────────────────────┐
│                  数据层 (Data Layer)                      │
│    audio_record.dart API + Schema Models                │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ↓
              外部系统（S3 + 后端 API）
```

### 2.2 数据流

**上传流程**：

```
用户选择文件
    ↓
AudioUploadWidget 触发上传
    ↓
AudioRecordProvider.uploadAudio()
    ↓
AudioRecordService.uploadAudioRecord()
    ├─ 步骤1: getPresignedUrl(contentType)
    │   └─ GET /v3/get_presigned_url
    ├─ 步骤2: uploadAudioToS3(url, file, contentType)
    │   └─ PUT <S3 预签名URL>
    └─ 步骤3: createAudioRecord(uri, timestamp)
        └─ POST /v3/create_record
    ↓
Provider 更新状态 (isUploading, progress, error)
    ↓
UI 实时响应更新（进度条、提示）
```

### 2.3 设计模式

1. **单一职责原则 (SRP)**
   - Provider 只管理状态
   - Service 只处理业务逻辑
   - API 层只负责网络请求

2. **依赖倒置原则 (DIP)**
   - 各层通过接口交互
   - 上层不依赖下层具体实现

3. **错误处理策略**
   - 网络错误：自动重试1次（1秒延迟）
   - 文件验证失败：立即返回错误
   - S3上传失败：记录日志并提示用户

---

## 3. 文件结构

### 3.1 新增文件清单

```
lib/
├── backend/
│   ├── http/api/
│   │   └── audio_record.dart              # API接口层（3个接口）
│   └── schema/
│       ├── audio_record.dart              # 录音记录模型
│       ├── audio_record.g.dart            # 自动生成
│       ├── presigned_url_response.dart    # 预签名URL响应模型
│       ├── presigned_url_response.g.dart  # 自动生成
│       └── schema.dart                    # 更新：导出新模型
│
├── services/
│   └── audio_record_service.dart          # 服务层（业务逻辑）
│
├── providers/
│   └── audio_record_provider.dart         # 状态管理层
│
├── pages/audio_record/
│   ├── page.dart                          # 录音管理主页面
│   ├── upload_widget.dart                 # 上传组件
│   └── audio_record_card.dart             # 录音卡片（预留）
│
├── pages/settings/
│   └── settings_drawer.dart               # 更新：添加UI入口
│
├── main.dart                              # 更新：注册Provider
└── core/app_shell.dart                    # 更新：深度链接
```

### 3.2 文件职责说明

| 文件 | 层级 | 职责 |
|------|------|------|
| `audio_record.dart` (API) | 数据层 | 定义3个API接口，处理HTTP请求 |
| `audio_record.dart` (Schema) | 数据层 | 录音记录数据模型 |
| `presigned_url_response.dart` | 数据层 | 预签名URL响应数据模型 |
| `audio_record_service.dart` | 服务层 | 封装完整上传流程，错误处理，重试逻辑 |
| `audio_record_provider.dart` | 状态管理层 | 管理上传状态、进度、错误信息 |
| `page.dart` | UI层 | 录音管理主页面，路由入口 |
| `upload_widget.dart` | UI层 | 文件选择和上传UI组件 |
| `audio_record_card.dart` | UI层 | 录音卡片组件（预留） |

---

## 4. API 接口说明

### 4.1 获取预签名上传URL

**接口定义**：
```dart
Future<PresignedUrlResponse?> getPresignedUrl(String contentType)
```

**HTTP 请求**：
```
GET /v3/get_presigned_url?content_type=audio/m4a
```

**查询参数**：
- `content_type`: 音频文件的MIME类型（如 `audio/m4a`, `audio/wav`, `audio/mpeg`, `audio/aac`）
  - 注意：参数值会自动进行 URL 编码，如 `audio/m4a` 编码为 `audio%2Fm4a`

**响应示例**：
```json
{
  "upload_url": "https://your-bucket.s3.amazonaws.com/uploads/test.m4a?X-Amz-Algorithm=...",
  "uri": "uploads/test.m4a"
}
```

**MIME类型映射**：
```dart
.m4a → audio/m4a
.wav → audio/wav
.mp3 → audio/mpeg
.aac → audio/aac
```

### 4.2 上传文件到S3

**接口定义**：
```dart
Future<bool> uploadAudioToS3(String uploadUrl, File audioFile, String contentType)
```

**HTTP 请求**：
```
PUT <预签名URL>
Content-Type: audio/m4a
Content-Length: <文件大小>
Body: <文件二进制数据>
```

**响应状态码**：
- `200 OK` 或 `204 No Content` - 上传成功
- 其他 - 上传失败

### 4.3 创建录音记录

**接口定义**：
```dart
Future<AudioRecord?> createAudioRecord(String audioUri, int recordTs)
```

**HTTP 请求**：
```
POST /v3/create_record
Content-Type: application/json
```

**请求参数**：
```json
{
  "audio_uri": "uploads/test.m4a",
  "record_ts": 1762848873  // 录音时间戳（秒）
}
```

**响应示例**：
```json
{
  "audio_record_id": "1690979656844-00006695-00007167",
  "audio_uri": "uploads/test.m4a",
  "record_ts": 1762848873,
  "status_code": 0,
  "status_message": "success"
}
```

---

## 5. 使用指南

### 5.1 快速开始

#### 方式一：从应用UI访问（推荐）

**步骤**：
1. 打开 Omi 应用
2. 点击右上角的**设置图标**（齿轮图标）
3. 在设置菜单中找到 **"Audio Upload"** 选项
4. 点击进入录音上传页面

**位置**：设置 → Profile & Notifications 区域 → Audio Upload（在 Device Settings 下方）

![设置入口位置示意图]

**文件位置**：`lib/pages/settings/settings_drawer.dart:308`

#### 方式二：导航跳转

```dart
import 'package:omi/pages/audio_record/page.dart';

// 在任何页面中打开录音上传页面
Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => const AudioRecordPage()),
);
```

#### 方式三：深度链接

```
omi://audio-records
```

### 5.2 使用 Provider

#### 监听上传状态

```dart
import 'package:omi/providers/audio_record_provider.dart';
import 'package:provider/provider.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AudioRecordProvider>(
      builder: (context, provider, child) {
        if (provider.isUploading) {
          return Column(
            children: [
              CircularProgressIndicator(value: provider.uploadProgress),
              Text('步骤 ${provider.currentStep} / ${provider.totalSteps}'),
            ],
          );
        }

        if (provider.errorMessage != null) {
          return Text('错误: ${provider.errorMessage}');
        }

        return ElevatedButton(
          onPressed: () => _uploadAudio(context, provider),
          child: Text('上传录音'),
        );
      },
    );
  }
}
```

#### 执行上传

```dart
Future<void> _uploadAudio(BuildContext context, AudioRecordProvider provider) async {
  // 选择文件
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['m4a', 'wav', 'mp3', 'aac'],
  );

  if (result != null && result.files.single.path != null) {
    final file = File(result.files.single.path!);

    // 开始上传
    final success = await provider.uploadAudio(file);

    if (success) {
      print('上传成功！');
      // 获取最新上传的记录
      final record = provider.lastUploadedRecord;
      print('录音ID: ${record?.audioRecordId}');
    } else {
      print('上传失败: ${provider.errorMessage}');
    }
  }
}
```

### 5.3 直接使用 Service

```dart
import 'package:omi/services/audio_record_service.dart';

final service = AudioRecordService();

// 上传文件
final audioRecord = await service.uploadAudioRecord(
  audioFile,
  onProgress: (current, total) {
    print('进度: $current / $total');
  },
);

if (audioRecord != null && audioRecord.isSuccess) {
  print('上传成功: ${audioRecord.audioRecordId}');
} else {
  print('上传失败');
}
```

---

## 6. 代码示例

### 6.1 自定义上传组件

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:omi/providers/audio_record_provider.dart';
import 'package:provider/provider.dart';

class CustomAudioUploader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AudioRecordProvider>(context);

    return Column(
      children: [
        // 上传按钮
        ElevatedButton(
          onPressed: provider.isUploading ? null : () => _pickAndUpload(context),
          child: Text(provider.isUploading ? '上传中...' : '选择录音'),
        ),

        // 进度显示
        if (provider.isUploading) ...[
          SizedBox(height: 16),
          LinearProgressIndicator(value: provider.uploadProgress),
          Text('${(provider.uploadProgress * 100).toInt()}%'),
        ],

        // 错误提示
        if (provider.errorMessage != null) ...[
          SizedBox(height: 16),
          Text(
            provider.errorMessage!,
            style: TextStyle(color: Colors.red),
          ),
        ],
      ],
    );
  }

  Future<void> _pickAndUpload(BuildContext context) async {
    final provider = Provider.of<AudioRecordProvider>(context, listen: false);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['m4a', 'wav', 'mp3', 'aac'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      await provider.uploadAudio(file);
    }
  }
}
```

### 6.2 批量上传

```dart
Future<void> uploadMultipleFiles(
  List<File> files,
  AudioRecordProvider provider,
) async {
  for (final file in files) {
    print('上传文件: ${file.path}');

    final success = await provider.uploadAudio(file);

    if (!success) {
      print('文件上传失败: ${file.path}');
      // 可选：询问用户是否继续
      break;
    }

    // 延迟避免过快请求
    await Future.delayed(Duration(milliseconds: 500));
  }

  print('所有文件上传完成');
}
```

### 6.3 文件验证示例

```dart
import 'package:omi/services/audio_record_service.dart';

final service = AudioRecordService();

// 上传前验证
final isValid = await service.validateAudioFile(audioFile);

if (!isValid) {
  // 文件无效
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('文件无效'),
      content: Text('请选择有效的音频文件（M4A、WAV、MP3、AAC），且大小不超过100MB'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('确定'),
        ),
      ],
    ),
  );
  return;
}

// 验证通过，继续上传
await provider.uploadAudio(audioFile);
```

---

## 7. 测试验证

### 7.1 单元测试建议

```dart
// test/services/audio_record_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:omi/services/audio_record_service.dart';

void main() {
  group('AudioRecordService', () {
    test('should validate file format correctly', () async {
      final service = AudioRecordService();

      // 测试有效格式
      final validFile = File('test.m4a');
      expect(await service.validateAudioFile(validFile), true);

      // 测试无效格式
      final invalidFile = File('test.txt');
      expect(await service.validateAudioFile(invalidFile), false);
    });
  });
}
```

### 7.2 Widget 测试建议

```dart
// test/pages/audio_record/upload_widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:omi/pages/audio_record/upload_widget.dart';
import 'package:omi/providers/audio_record_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('should show upload button when idle', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AudioRecordProvider(),
        child: MaterialApp(home: AudioUploadWidget()),
      ),
    );

    expect(find.text('选择文件'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
```

### 7.3 手动测试清单

- [ ] 选择 M4A 文件并成功上传
- [ ] 选择 WAV 文件并成功上传
- [ ] 选择 MP3 文件并成功上传
- [ ] 选择 AAC 文件并成功上传
- [ ] 选择无效格式文件，显示错误提示
- [ ] 选择超大文件（>100MB），显示错误提示
- [ ] 网络错误时自动重试
- [ ] 上传过程中显示正确的进度
- [ ] 上传成功后显示成功提示
- [ ] 上传失败后显示错误信息
- [ ] 深度链接 `omi://audio-records` 正确打开页面

---

## 8. 扩展建议

### 8.1 近期扩展（优先级高）

#### 1. 录音列表功能

**后端API**：
```
GET /v3/audio_records?limit=50&offset=0
```

**响应示例**：
```json
{
  "records": [
    {
      "audio_record_id": "xxx",
      "audio_uri": "uploads/test.m4a",
      "record_ts": 1762848873,
      "status_code": 0,
      "status_message": "success"
    }
  ],
  "total": 100
}
```

**实现步骤**：
1. 在 `audio_record.dart` API 层添加 `getAudioRecords()` 方法
2. 在 `AudioRecordProvider` 中实现 `loadAudioRecords()` 方法
3. 创建列表页面组件展示录音列表
4. 完善 `audio_record_card.dart` 卡片组件

#### 2. 删除录音功能

**后端API**：
```
DELETE /v3/audio_records/{record_id}
```

**实现步骤**：
1. API 层添加 `deleteAudioRecord(String recordId)` 方法
2. Provider 中实现删除逻辑并更新列表
3. UI 添加删除按钮和确认对话框

### 8.2 中期扩展（优先级中）

#### 1. 上传队列管理

```dart
class AudioRecordProvider extends ChangeNotifier {
  Queue<File> _uploadQueue = Queue();

  Future<void> addToQueue(List<File> files) async {
    _uploadQueue.addAll(files);
    if (!_isProcessingQueue) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    _isProcessingQueue = true;

    while (_uploadQueue.isNotEmpty) {
      final file = _uploadQueue.removeFirst();
      await uploadAudio(file);
    }

    _isProcessingQueue = false;
  }
}
```

#### 2. 音频预览和播放

```dart
// 使用 just_audio 包
import 'package:just_audio/just_audio.dart';

class AudioRecordCard extends StatefulWidget {
  final AudioRecord record;

  @override
  State<AudioRecordCard> createState() => _AudioRecordCardState();
}

class _AudioRecordCardState extends State<AudioRecordCard> {
  final player = AudioPlayer();

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> playAudio() async {
    await player.setUrl(widget.record.audioUri);
    await player.play();
  }

  // ... 播放控制UI
}
```

### 8.3 长期扩展（优先级低）

#### 1. 断点续传

```dart
class ChunkedUploadService {
  Future<AudioRecord?> uploadWithResume(
    File file,
    int chunkSize, // 每片 5MB
  ) async {
    // 1. 获取上传ID
    // 2. 分片上传
    // 3. 支持暂停/恢复
    // 4. 合并分片
    // 5. 创建记录
  }
}
```

#### 2. 音频压缩

```dart
import 'package:flutter_sound/flutter_sound.dart';

Future<File?> compressAudio(File originalFile) async {
  final codec = Codec.aacADTS;
  final outputPath = '${originalFile.path}.compressed.aac';

  // 使用 flutter_sound 压缩
  await flutterSound.startRecorder(
    toFile: outputPath,
    codec: codec,
    bitRate: 96000, // 96kbps
  );

  return File(outputPath);
}
```

#### 3. 后台上传

```dart
// 使用 flutter_background_service
import 'package:flutter_background_service/flutter_background_service.dart';

void initializeBackgroundService() {
  final service = FlutterBackgroundService();

  service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
    ),
  );
}

void onStart(ServiceInstance service) {
  // 后台上传逻辑
}
```

---

## 9. 常见问题

### 9.1 上传失败问题

**Q: 上传总是失败，如何调试？**

A: 检查以下几点：
1. 查看控制台日志，搜索 `AudioRecordService` 相关日志
2. 验证后端 API 是否正常工作
3. 检查网络连接
4. 确认文件格式和大小是否符合要求
5. 使用 Charles/Proxyman 抓包查看 HTTP 请求细节

**调试代码**：
```dart
// 启用详细日志
debugPrint('Upload URL: ${presignedUrl.uploadUrl}');
debugPrint('File size: ${await audioFile.length()}');
debugPrint('Content-Type: $contentType');
```

### 9.2 进度不更新问题

**Q: 上传进度条不更新？**

A: 确保在 `AudioRecordService` 中正确调用了 `onProgress` 回调：

```dart
final audioRecord = await service.uploadAudioRecord(
  audioFile,
  onProgress: (current, total) {
    _currentStep = current;
    _totalSteps = total;
    notifyListeners();  // 关键：通知UI更新
  },
);
```

### 9.3 文件选择器问题

**Q: iOS/Android 上文件选择器无法打开？**

A: 检查权限配置：

**iOS** (`ios/Runner/Info.plist`)：
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问您的照片库以选择音频文件</string>
<key>NSMicrophoneUsageDescription</key>
<string>需要访问麦克风以录制音频</string>
```

**Android** (`android/app/src/main/AndroidManifest.xml`)：
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

### 9.4 大文件上传超时

**Q: 上传大文件时总是超时？**

A: 调整重试次数或实现分片上传：

```dart
// 方式1：增加重试次数
static const int _maxRetries = 3;  // 从1改为3

// 方式2：分片上传（未来扩展）
// 见"扩展建议"章节
```

### 9.5 S3 上传返回 403

**Q: S3 上传时返回 403 Forbidden？**

A: 检查：
1. 预签名 URL 是否过期
2. Content-Type 是否匹配
3. 后端生成的预签名 URL 权限是否正确

```dart
// 添加更详细的错误日志
debugPrint('S3 Upload Status: ${response.statusCode}');
debugPrint('S3 Response Body: ${response.body}');
```

---

## 附录

### A. 相关文档

- [Omi 架构分析文档](./omi-architecture-analysis-cn.md)
- [BLE 设备 API 参考](./ble-device-api-reference.md)
- [项目 README](../README.md)
- [Claude Code 指南](../CLAUDE.md)

### B. 依赖包

- `file_picker: 8.3.2` - 文件选择器
- `http: ^1.4.0` - HTTP 客户端（已有）
- `provider: ^6.1.2` - 状态管理（已有）
- `json_annotation: ^4.9.0` - JSON 注解（已有）
- `json_serializable: ^6.9.5` - JSON 序列化（已有）

### C. Git 提交建议

```bash
# 功能提交
git add lib/backend/schema/audio_record.dart
git add lib/backend/schema/presigned_url_response.dart
git add lib/backend/http/api/audio_record.dart
git add lib/services/audio_record_service.dart
git add lib/providers/audio_record_provider.dart
git add lib/pages/audio_record/
git add lib/main.dart
git add lib/core/app_shell.dart
git add lib/backend/schema/schema.dart
git add pubspec.yaml
git add docs/audio-record-upload-feature.md

git commit -m "feat: add audio record upload feature

- Implement three-step upload flow (presigned URL → S3 → record creation)
- Support M4A, WAV, MP3, AAC formats
- Add real-time upload progress tracking
- Implement automatic retry for network errors
- Add file validation (size, format)
- Create dedicated audio record management page
- Integrate with Provider state management
- Add deep linking support (omi://audio-records)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### D. 性能指标

| 指标 | 目标值 | 实际值 |
|------|--------|--------|
| 小文件上传（<5MB） | <3秒 | 待测试 |
| 中等文件上传（5-20MB） | <10秒 | 待测试 |
| 大文件上传（20-100MB） | <60秒 | 待测试 |
| UI 响应时间 | <100ms | 实时更新 |
| 错误恢复时间 | <2秒 | 1秒重试 |

---

**文档维护**: 本文档应随功能更新同步维护
**反馈渠道**: 通过 GitHub Issues 或团队内部渠道
**最后更新**: 2025-01-13

---

**© 2025 Omi Project. 本文档用于开发团队内部参考。**
