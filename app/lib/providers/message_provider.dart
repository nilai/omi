import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:omi/backend/http/api/apps.dart';
import 'package:omi/backend/http/api/messages.dart';
import 'package:omi/backend/http/api/users.dart';
import 'package:omi/backend/preferences.dart';
import 'package:omi/backend/schema/app.dart';
import 'package:omi/backend/schema/bt_device/bt_device.dart';
import 'package:omi/backend/schema/message.dart';
import 'package:omi/providers/app_provider.dart';
import 'package:omi/utils/alerts/app_snackbar.dart';
import 'package:omi/utils/analytics/mixpanel.dart';
import 'package:omi/utils/file.dart';
import 'package:omi/utils/platform/platform_service.dart';
import 'package:uuid/uuid.dart';

/// 消息提供者，负责管理聊天消息的发送、接收、文件上传等功能
/// 继承自 ChangeNotifier，用于状态管理和 UI 更新通知
class MessageProvider extends ChangeNotifier {
  /// 桌面端与原生代码通信的方法通道，用于处理 Ask AI 功能
  static late MethodChannel _askAIChannel;

  MessageProvider() {
    if (PlatformService.isDesktop) {
      _askAIChannel = const MethodChannel('com.omi/ask_ai');
      _askAIChannel.setMethodCallHandler(_handleAskAIMethodCall);
    }
  }

  /// 应用提供者实例，用于获取当前选中的聊天应用信息
  AppProvider? appProvider;

  /// 消息列表，按时间倒序排列（最新的在索引 0）
  List<ServerMessage> messages = [];

  /// 标记下一条消息是否来自语音输入（用于统计和分析）
  bool _isNextMessageFromVoice = false;

  /// 是否正在加载消息列表
  bool isLoadingMessages = false;

  /// 是否有缓存的消息可用
  bool hasCachedMessages = false;

  /// 是否正在清空聊天记录
  bool isClearingChat = false;

  /// 是否显示 AI 正在输入的指示器
  bool showTypingIndicator = false;

  /// 是否正在发送消息
  bool sendingMessage = false;

  /// 首次加载时显示的提示文本
  String firstTimeLoadingText = '';

  /// 可用于聊天的应用列表
  List<App> chatApps = [];

  /// 是否正在加载聊天应用列表
  bool isLoadingChatApps = false;

  /// 用户选择的本地文件列表
  List<File> selectedFiles = [];

  /// 对应选中文件的类型列表（'image' 或 'file'）
  List<String> selectedFileTypes = [];

  /// 已上传到服务器的文件列表
  List<MessageFile> uploadedFiles = [];

  /// 是否有文件正在上传
  bool isUploadingFiles = false;

  /// 文件上传状态映射表，key 为文件路径，value 为是否正在上传
  Map<String, bool> uploadingFiles = {};

  /// 更新应用提供者实例
  /// [p] 新的应用提供者实例
  void updateAppProvider(AppProvider p) {
    appProvider = p;
  }

  /// 获取可用于聊天的应用列表
  /// 从服务器获取已安装的应用，并筛选出支持聊天的应用
  Future<void> fetchChatApps() async {
    if (isLoadingChatApps) return;

    isLoadingChatApps = true;
    notifyListeners();

    try {
      final result = await retrieveAppsSearch(
        installedApps: true,
        limit: 50,
      );

      chatApps = result.apps.where((app) => app.worksWithChat()).toList();
    } catch (e) {
      debugPrint('Error fetching chat apps: $e');
      chatApps = [];
    } finally {
      isLoadingChatApps = false;
      notifyListeners();
    }
  }

  /// 设置下一条消息的来源是否为语音输入
  /// [isVoice] 是否为语音输入
  void setNextMessageOriginIsVoice(bool isVoice) {
    _isNextMessageFromVoice = isVoice;
  }

  /// 根据上传状态映射表更新整体上传状态
  /// 如果任何文件正在上传，则设置 isUploadingFiles 为 true
  void setIsUploadingFiles() {
    if (uploadingFiles.values.contains(true)) {
      isUploadingFiles = true;
    } else {
      isUploadingFiles = false;
    }
    notifyListeners();
  }

  /// 批量设置多个文件的上传状态
  /// [ids] 文件路径列表
  /// [value] 上传状态（true 表示正在上传）
  void setMultiUploadingFileStatus(List<String> ids, bool value) {
    for (var id in ids) {
      uploadingFiles[id] = value;
    }
    setIsUploadingFiles();
    notifyListeners();
  }

  /// 检查指定文件是否正在上传
  /// [id] 文件路径
  /// 返回 true 表示正在上传，false 表示未上传
  bool isFileUploading(String id) {
    return uploadingFiles[id] ?? false;
  }

  /// 设置是否有缓存消息的标志
  /// [value] 是否有缓存消息
  void setHasCachedMessages(bool value) {
    hasCachedMessages = value;
    notifyListeners();
  }

  /// 设置是否正在发送消息的标志
  /// [value] 是否正在发送消息
  void setSendingMessage(bool value) {
    sendingMessage = value;
    notifyListeners();
  }

  /// 设置是否显示输入指示器
  /// [value] 是否显示输入指示器
  void setShowTypingIndicator(bool value) {
    showTypingIndicator = value;
    notifyListeners();
  }

  /// 设置是否正在清空聊天记录
  /// [value] 是否正在清空聊天记录
  void setClearingChat(bool value) {
    isClearingChat = value;
    notifyListeners();
  }

  /// 设置是否正在加载消息
  /// [value] 是否正在加载消息
  void setLoadingMessages(bool value) {
    isLoadingMessages = value;
    notifyListeners();
  }

  /// 使用相机拍摄照片
  /// 仅在移动端可用，桌面端会显示错误提示
  /// 拍摄成功后自动上传文件
  void captureImage() async {
    if (PlatformService.isDesktop) {
      AppSnackbar.showSnackbarError('Camera capture is not available on this platform');
      return;
    }

    try {
      var res = await ImagePicker().pickImage(source: ImageSource.camera);
      if (res != null) {
        selectedFiles.add(File(res.path));
        selectedFileTypes.add('image');
        var index = selectedFiles.length - 1;
        await uploadFiles([selectedFiles[index]], appProvider?.selectedChatAppId);
        notifyListeners();
      }
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied') {
        AppSnackbar.showSnackbarError('Camera permission denied. Please allow access to camera');
      } else {
        AppSnackbar.showSnackbarError('Error accessing camera: ${e.message ?? e.code}');
      }
    } catch (e) {
      AppSnackbar.showSnackbarError('Error taking photo. Please try again.');
    }
  }

  /// 从相册或文件系统选择图片
  /// 最多可选择 4 张图片（包括已选择的）
  /// 桌面端使用文件选择器，移动端使用图片选择器
  /// 选择成功后自动上传文件
  void selectImage() async {
    if (selectedFiles.length >= 4) {
      AppSnackbar.showSnackbarError('You can only select up to 4 images');
      return;
    }

    try {
      List<File> files = [];

      if (PlatformService.isDesktop) {
        try {
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
            allowMultiple: true,
            dialogTitle: 'Select image files',
            withData: false,
            withReadStream: false,
          );

          if (result != null && result.files.isNotEmpty) {
            for (var file in result.files) {
              if (file.path != null && files.length < (4 - selectedFiles.length)) {
                files.add(File(file.path!));
              }
            }
          } else {
            return;
          }
        } on PlatformException catch (e) {
          AppSnackbar.showSnackbarError('Error opening file picker: ${e.message}');
          return;
        } catch (e) {
          debugPrint('FilePicker general error: $e');
          AppSnackbar.showSnackbarError('Error selecting images: $e');
          return;
        }
      } else {
        List res = [];
        if (4 - selectedFiles.length == 1) {
          var image = await ImagePicker().pickImage(source: ImageSource.gallery);
          if (image != null) {
            res = [image];
          }
        } else {
          res = await ImagePicker().pickMultiImage(limit: 4 - selectedFiles.length);
        }

        for (var r in res) {
          files.add(File(r.path));
        }
      }

      if (files.isNotEmpty) {
        selectedFiles.addAll(files);
        selectedFileTypes.addAll(files.map((e) => 'image'));
        await uploadFiles(files, appProvider?.selectedChatAppId);
      }
      notifyListeners();
    } on PlatformException catch (e) {
      debugPrint('🖼️ PlatformException during image picking: ${e.code} - ${e.message}');
      if (e.code == 'photo_access_denied') {
        AppSnackbar.showSnackbarError('Photos permission denied. Please allow access to photos to select images');
      } else {
        AppSnackbar.showSnackbarError('Error selecting images: ${e.message ?? e.code}');
      }
    } catch (e) {
      debugPrint('🖼️ General exception during image picking: $e');
      AppSnackbar.showSnackbarError('Error selecting images. Please try again.');
    }
  }

  /// 从文件系统选择文件（非图片）
  /// 最多可选择 4 个文件（包括已选择的）
  /// 支持的文件类型：jpeg, md, pdf, gif, doc, png, pptx, txt, xlsx, webp
  /// 选择成功后自动上传文件
  void selectFile() async {
    if (selectedFiles.length >= 4) {
      AppSnackbar.showSnackbarError('You can only select up to 4 files');
      return;
    }

    try {
      var res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: ['jpeg', 'md', 'pdf', 'gif', 'doc', 'png', 'pptx', 'txt', 'xlsx', 'webp'],
        dialogTitle: 'Select files',
        withData: false,
        withReadStream: false,
      );

      if (res != null && res.files.isNotEmpty) {
        List<File> files = [];
        for (var r in res.files) {
          if (r.path != null && files.length < (4 - selectedFiles.length)) {
            files.add(File(r.path!));
          }
        }

        if (files.isNotEmpty) {
          selectedFiles.addAll(files);
          selectedFileTypes.addAll(files.map((e) => 'file'));
          await uploadFiles(files, appProvider?.selectedChatAppId);
        }
        notifyListeners();
      }
    } on PlatformException catch (e) {
      AppSnackbar.showSnackbarError('Error selecting files: ${e.message ?? e.code}');
    } catch (e) {
      AppSnackbar.showSnackbarError('Error selecting files. Please try again.');
    }
  }

  /// 清除指定索引的选中文件
  /// [index] 要清除的文件索引
  void clearSelectedFile(int index) {
    selectedFiles.removeAt(index);
    selectedFileTypes.removeAt(index);
    uploadedFiles.removeAt(index);
    notifyListeners();
  }

  /// 清除所有选中的文件
  /// 仅清除本地选择的文件列表，不清除已上传的文件列表
  void clearSelectedFiles() {
    selectedFiles.clear();
    selectedFileTypes.clear();
    notifyListeners();
  }

  /// 清除所有已上传的文件列表
  void clearUploadedFiles() {
    uploadedFiles.clear();
    notifyListeners();
  }

  /// 上传文件到服务器
  /// [files] 要上传的文件列表
  /// [appId] 关联的应用 ID，如果为 null 则上传到默认聊天
  /// 返回上传成功后的文件信息列表，失败返回 null
  Future<List<MessageFile>?> uploadFiles(List<File> files, String? appId) async {
    if (files.isNotEmpty) {
      setMultiUploadingFileStatus(files.map((e) => e.path).toList(), true);
      var res = await uploadFilesServer(files, appId: appId);
      if (res != null) {
        uploadedFiles.addAll(res);
      } else {
        clearSelectedFiles();
        AppSnackbar.showSnackbarError('Failed to upload file, please try again later');
      }
      setMultiUploadingFileStatus(files.map((e) => e.path).toList(), false);
      notifyListeners();
      return res;
    }

    return null;
  }

  /// 从本地消息列表中移除指定 ID 的消息
  /// [id] 要移除的消息 ID
  void removeLocalMessage(String id) {
    messages.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  /// 刷新消息列表
  /// [dropdownSelected] 是否从下拉选择的应用获取消息
  /// 优先从服务器获取，如果失败则使用缓存的消息
  Future refreshMessages({bool dropdownSelected = false}) async {
    setLoadingMessages(true);
    if (SharedPreferencesUtil().cachedMessages.isNotEmpty) {
      setHasCachedMessages(true);
    }
    messages = await getMessagesFromServer(dropdownSelected: dropdownSelected);
    if (messages.isEmpty) {
      messages = SharedPreferencesUtil().cachedMessages;
    } else {
      SharedPreferencesUtil().cachedMessages = messages;
      setHasCachedMessages(true);
    }
    setLoadingMessages(false);
    notifyListeners();
  }

  /// 从缓存中加载消息列表
  /// 如果缓存中有消息，则直接使用缓存的消息并设置缓存标志
  void setMessagesFromCache() {
    if (SharedPreferencesUtil().cachedMessages.isNotEmpty) {
      setHasCachedMessages(true);
      messages = SharedPreferencesUtil().cachedMessages;
    }
    notifyListeners();
  }

  /// 从服务器获取消息列表
  /// [dropdownSelected] 是否从下拉选择的应用获取消息
  /// 首次加载时会显示加载提示文本
  /// 返回获取到的消息列表
  Future<List<ServerMessage>> getMessagesFromServer({bool dropdownSelected = false}) async {
    if (!hasCachedMessages) {
      firstTimeLoadingText = 'Reading your memories...';
      notifyListeners();
    }
    setLoadingMessages(true);
    var mes = await getMessagesServer(
      appId: appProvider?.selectedChatAppId,
      dropdownSelected: dropdownSelected,
    );
    if (!hasCachedMessages) {
      firstTimeLoadingText = 'Learning from your memories...';
      notifyListeners();
    }
    messages = mes;
    setLoadingMessages(false);
    notifyListeners();
    return messages;
  }

  /// 设置消息的 NPS（净推荐值）评分
  /// [message] 要评分的消息
  /// [value] 评分值
  /// 评分后隐藏该消息的 NPS 询问提示
  Future setMessageNps(ServerMessage message, int value) async {
    await setMessageResponseRating(message.id, value);
    message.askForNps = false;
    notifyListeners();
  }

  /// 清空当前聊天记录
  /// 清空服务器上的消息，并更新本地消息列表
  Future clearChat() async {
    setClearingChat(true);
    var mes = await clearChatServer(appId: appProvider?.selectedChatAppId);
    messages = mes;
    setClearingChat(false);
    notifyListeners();
  }

  /// 在本地添加一条用户消息（发送前显示）
  /// [messageText] 消息文本内容
  /// 创建一条临时消息并插入到消息列表顶部，包含已上传的文件信息
  /// 如果消息 ID 已存在则不会重复添加
  void addMessageLocally(String messageText) {
    List<String> fileIds = uploadedFiles.map((e) => e.id).toList();
    var appId = appProvider?.selectedChatAppId;
    if (appId == 'no_selected') {
      appId = null;
    }
    var message = ServerMessage(
      const Uuid().v4(),
      DateTime.now(),
      messageText,
      MessageSender.human,
      MessageType.text,
      appId,
      false,
      List.from(uploadedFiles),
      fileIds,
      [],
    );
    if (messages.firstWhereOrNull((m) => m.id == message.id) != null) {
      return;
    }
    messages.insert(0, message);
    notifyListeners();
  }

  /// 添加一条服务器返回的消息到消息列表
  /// [message] 要添加的消息对象
  /// 如果消息 ID 已存在则不会重复添加
  void addMessage(ServerMessage message) {
    if (messages.firstWhereOrNull((m) => m.id == message.id) != null) {
      return;
    }
    messages.insert(0, message);
    notifyListeners();
  }

  /// 发送语音消息流到服务器
  /// [audioBytes] 音频字节数据列表
  /// [onFirstChunkRecived] 收到第一个数据块时的回调函数
  /// [codec] 音频编解码器，用于确定帧大小
  /// 将音频数据保存为临时文件后，通过流式方式发送到服务器
  /// 实时处理服务器返回的消息块（思考过程、数据、完成、错误等）
  Future sendVoiceMessageStreamToServer(List<List<int>> audioBytes,
      {Function? onFirstChunkRecived, BleAudioCodec? codec}) async {
    var file = await FileUtils.saveAudioBytesToTempFile(
      audioBytes,
      DateTime.now().millisecondsSinceEpoch ~/ 1000 - (audioBytes.length / 100).ceil(),
      codec?.getFrameSize() ?? 160,
    );

    var currentAppId = appProvider?.selectedChatAppId;
    if (currentAppId == 'no_selected') {
      currentAppId = null;
    }
    String chatTargetId = currentAppId ?? 'omi';
    App? targetApp = currentAppId != null ? appProvider?.apps.firstWhereOrNull((app) => app.id == currentAppId) : null;
    bool isPersonaChat = targetApp != null ? !targetApp.isNotPersona() : false;

    MixpanelManager().chatVoiceInputUsed(
      chatTargetId: chatTargetId,
      isPersonaChat: isPersonaChat,
    );

    setShowTypingIndicator(true);
    var message = ServerMessage.empty();
    messages.insert(0, message);
    notifyListeners();

    try {
      bool firstChunkRecieved = false;
      await for (var chunk in sendVoiceMessageStreamServer([file])) {
        if (!firstChunkRecieved && [MessageChunkType.data, MessageChunkType.done].contains(chunk.type)) {
          firstChunkRecieved = true;
          if (onFirstChunkRecived != null) {
            onFirstChunkRecived();
          }
        }

        if (chunk.type == MessageChunkType.think) {
          message.thinkings.add(chunk.text);
          notifyListeners();
          continue;
        }

        if (chunk.type == MessageChunkType.data) {
          message.text += chunk.text;
          notifyListeners();
          continue;
        }

        if (chunk.type == MessageChunkType.done) {
          message = chunk.message!;
          messages[0] = message;
          notifyListeners();
          continue;
        }

        if (chunk.type == MessageChunkType.message) {
          messages.insert(1, chunk.message!);
          notifyListeners();
          continue;
        }

        if (chunk.type == MessageChunkType.error) {
          message.text = chunk.text;
          notifyListeners();
          continue;
        }
      }
    } catch (e) {
      message.text = ServerMessageChunk.failedMessage().text;
      notifyListeners();
    }

    setShowTypingIndicator(false);
  }

  /// 发送文本消息流到服务器
  /// [text] 要发送的消息文本
  /// 通过流式方式发送消息，实时接收并显示 AI 的回复
  /// 使用缓冲区机制优化 UI 更新频率（每 100ms 刷新一次）
  /// 处理思考过程、数据流、完成和错误等不同类型的消息块
  Future sendMessageStreamToServer(String text) async {
    setShowTypingIndicator(true);
    var currentAppId = appProvider?.selectedChatAppId;
    if (currentAppId == 'no_selected') {
      currentAppId = null;
    }

    String chatTargetId = currentAppId ?? 'omi';
    App? targetApp = currentAppId != null ? appProvider?.apps.firstWhereOrNull((app) => app.id == currentAppId) : null;
    bool isPersonaChat = targetApp != null ? !targetApp.isNotPersona() : false;

    MixpanelManager().chatMessageSent(
      message: text,
      includesFiles: uploadedFiles.isNotEmpty,
      numberOfFiles: uploadedFiles.length,
      chatTargetId: chatTargetId,
      isPersonaChat: isPersonaChat,
      isVoiceInput: _isNextMessageFromVoice,
    );
    _isNextMessageFromVoice = false;

    var message = ServerMessage.empty(appId: currentAppId);
    messages.insert(0, message);
    notifyListeners();
    List<String> fileIds = uploadedFiles.map((e) => e.id).toList();
    clearSelectedFiles();
    clearUploadedFiles();
    String textBuffer = '';
    Timer? timer;

    void flushBuffer() {
      if (textBuffer.isNotEmpty) {
        message.text += textBuffer;
        textBuffer = '';
        HapticFeedback.lightImpact();
        notifyListeners();
      }
    }

    try {
      await for (var chunk in sendMessageStreamServer(text, appId: currentAppId, filesId: fileIds)) {
        if (chunk.type == MessageChunkType.think) {
          flushBuffer();
          message.thinkings.add(chunk.text);
          notifyListeners();
          continue;
        }

        if (chunk.type == MessageChunkType.data) {
          textBuffer += chunk.text;
          timer ??= Timer.periodic(const Duration(milliseconds: 100), (_) {
            flushBuffer();
          });
          continue;
        }

        timer?.cancel();
        timer = null;
        flushBuffer();

        if (chunk.type == MessageChunkType.done) {
          message = chunk.message!;
          messages[0] = message;
          notifyListeners();
          continue;
        }

        if (chunk.type == MessageChunkType.error) {
          message.text = chunk.text;
          notifyListeners();
          continue;
        }
      }
    } catch (e) {
      message.text = ServerMessageChunk.failedMessage().text;
      notifyListeners();
    } finally {
      timer?.cancel();
      flushBuffer();
      setShowTypingIndicator(false);
    }
  }

  /// 发送应用的初始欢迎消息
  /// [app] 目标应用对象，如果为 null 则发送默认欢迎消息
  /// 从服务器获取应用的初始消息并添加到消息列表
  Future sendInitialAppMessage(App? app) async {
    setSendingMessage(true);
    ServerMessage message = await getInitialAppMessage(app?.id);
    addMessage(message);
    setSendingMessage(false);
    notifyListeners();
  }

  /// 根据应用 ID 获取应用对象
  /// [appId] 应用 ID
  /// 返回对应的应用对象，如果不存在则返回 null
  App? messageSenderApp(String? appId) {
    return appProvider?.apps.firstWhereOrNull((p) => p.id == appId);
  }

  /// 处理桌面端 Ask AI 功能的方法调用
  /// [call] 来自原生代码的方法调用
  /// 支持发送查询消息（可包含附件），并将 AI 响应通过方法通道返回给原生代码
  Future<void> _handleAskAIMethodCall(MethodCall call) async {
    if (!PlatformService.isDesktop) {
      return;
    }
    switch (call.method) {
      case 'sendQuery':
        final args = call.arguments as Map<dynamic, dynamic>;
        final message = args['message'] as String;
        final filePath = args['filePath'] as String?;

        List<String>? fileIds;
        if (filePath != null && filePath.isNotEmpty) {
          final file = File(filePath);
          final uploadedFilesResult = await uploadFiles([file], null);
          if (uploadedFilesResult != null) {
            fileIds = uploadedFilesResult.map((f) => f.id).toList();
          } else {
            _askAIChannel.invokeMethod('aiResponseChunk', {
              'type': 'error',
              'text': 'Failed to upload the attached file.',
            });
            return;
          }
        }

        try {
          await for (var chunk in sendMessageStreamServer(message, filesId: fileIds)) {
            final chunkMap = {
              'type': chunk.type.toString().split('.').last,
              'text': chunk.text,
              'messageId': chunk.messageId,
            };
            if (chunk.type == MessageChunkType.done && chunk.message != null) {
              chunkMap['text'] = chunk.message!.text;
            }
            _askAIChannel.invokeMethod('aiResponseChunk', chunkMap);
          }
        } catch (e) {
          final failedChunk = ServerMessageChunk.failedMessage();
          final chunkMap = {
            'type': failedChunk.type.toString().split('.').last,
            'text': failedChunk.text,
            'messageId': failedChunk.messageId,
          };
          _askAIChannel.invokeMethod('aiResponseChunk', chunkMap);
        }
        break;
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'Method ${call.method} not implemented.',
        );
    }
  }
}
