import 'dart:io';

import 'package:flutter/material.dart';

import '../../../backend/http/mp_api/mp_memory.dart';
import '../../../backend/schema/mp/mp_data_model.dart';
import '../../../backend/schema/mp/mp_memory.dart';
import '../../../services/mp_audio_upload.dart';
import '../../../utils/alerts/mp_share_memory_dialog.dart';
import '../../../utils/mp_local_records_util.dart';
import '../../../utils/mp_user_profile_share.dart';
import '../../mp_custom_utils/mp_timestamp_utils.dart';
import '../../mp_custom_utils/mp_toast_utils.dart';
import '../widgets/mp_delete_memory_dialog.dart';

class MPMemoryItem {
  MPMemoryItem({
    required this.dateText,
    required this.tagText,
    required this.tagColor,
    required this.headerText,
    required this.timeText,
    this.secondsText,
    this.description,
    required this.memory,
    this.localPath,
    this.isUploading = false,
    required this.createAt,
    this.source,
  });

  final String dateText;
  final String tagText;
  final Color tagColor;
  final String headerText;
  final String timeText;
  final String? secondsText;
  final String? description;
  final MPMemoryStruct memory;
  String? localPath;
  final int createAt;
  String? source;
  bool isUploading = false;
}

/// MPMemoryStruct 扩展方法
/// 提供将 MPMemoryStruct 转换为 MPMemoryItem 的方法
extension MPMemoryStructExtension on MPMemoryStruct {
  /// 解析十六进制颜色字符串为 Color 对象
  /// @param hexString 十六进制颜色字符串，例如：#467db4
  /// @returns 解析后的 Color 对象，如果解析失败则返回默认颜色
  Color _parseHexColor(String? hexString) {
    if (hexString == null) {
      return const Color(0xFF8D8D8D);
    }
    try {
      // 移除 # 号（如果存在）
      String hex = hexString.replaceAll('#', '');

      // 如果是 6 位十六进制，添加 FF 作为 alpha 通道
      if (hex.length == 6) {
        hex = 'FF$hex';
      }

      // 转换为整数
      final intValue = int.parse(hex, radix: 16);
      return Color(intValue);
    } catch (e) {
      // 解析失败时返回默认颜色
      return const Color(0xFF8D8D8D);
    }
  }

  /// 将 MPMemoryStruct 转换为 MPMemoryItem
  /// @returns 转换后的 MPMemoryItem 对象
  MPMemoryItem toMPMemoryItem() {
    final dateText = MPTimestampUtils.timestampToRelativeDateString(createAt);

    // 生成 timeText (yyyy-MM-dd HH:mm:ss)
    final timeText = MPTimestampUtils.timestampToDateTime(createAt).toString();

    // 生成 secondsText (从 duration 转换)
    final secondsText = duration > 0 ? '${duration}s' : null;

    // 根据 labelColor 或 type 确定 tagColor
    Color tagColor = _parseHexColor(labelColor);

    return MPMemoryItem(
      dateText: dateText,
      tagText: label,
      tagColor: tagColor,
      headerText: title,
      timeText: timeText,
      secondsText: secondsText,
      description: content,
      memory: this,
      createAt: createAt,
      source: type == MPMemoryType.onlyRecord ? source : null,
    );
  }
}

enum MPHomeImportAudioType {
  local,
  sdCard,
  none,
}

class MPHomePageProvider extends ChangeNotifier {
  String selectedDate = MPTimestampUtils.getCurrentDate();

  /// 上传进度
  double uploadPercent = 10;

  /// 记录数量(顶部数字)
  int recordCount = 0;

  /// 记录索引
  int sdRecordIndex = 0;

  /// SD卡记录数量
  int sdRecordCount = 0;

  /// 记录速度
  double sdRecordSpeed = 0;

  /// 是否正在加载
  bool loading = false;

  /// 是否正在加载更多
  bool loadingMore = false;

  /// 是否有更多
  bool hasMore = true;

  /// 记忆列表
  List<MPMemoryItem> items = [];

  /// 游标
  String _cursor = '';

  MPHomeImportAudioType importAudioType = MPHomeImportAudioType.none;

  List<MPLocalMemoryModel> _localRecords = [];
  List<MPMemoryItem> _remoteItems = [];

  bool _rightNowTranscribe = false;

  /// 初始化
  MPHomePageProvider() {
    loadLocalRecords();
    // 加载用户资料
    MPUserProfileShare.instance.getUserProfile().then((value) {
      if (value != null) {
        _rightNowTranscribe = value.user.rightNowTranscribe ?? false;
      }
    });
  }

  /// 刷新记忆列表
  /// 从服务器获取最新的记忆列表数据
  /// @returns 无返回值
  Future<void> refresh() async {
    try {
      loading = true;
      notifyListeners();
      _cursor = '';
      final req = MPGetMemoryListRequest(pageSize: 20, cursor: _cursor, date: selectedDate);
      final response = await getMemoryList(req);
      if (response != null) {
        // items.clear();
        // items.addAll(response.memorys.map((memory) => memory.toMPMemoryItem()));
        hasMore = response.hasMore;
        if (response.memorys.isNotEmpty) {
          _cursor = response.memorys.last.id;
        }
        recordCount = response.memoryTotal;
        final list = response.memorys.map((memory) => memory.toMPMemoryItem()).toList();
        for (var element in response.memorys) {
          print('------hj----- resonpose memory: ${element.toJson()}');
        }
        _remoteItems.clear();
        _remoteItems = list;
        _updateItems();
      } else {
        // 请求失败，但不清空已有数据，保持当前显示状态
        debugPrint('Failed to refresh memory list: response is null');
      }
    } catch (e, stackTrace) {
      // 捕获异常，确保 loading 状态被重置
      debugPrint('Error in refresh: $e, $stackTrace');
    } finally {
      // 确保 loading 状态总是被重置
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (loadingMore || !hasMore) return;
    loadingMore = true;
    notifyListeners();
    final req = MPGetMemoryListRequest(pageSize: 20, cursor: _cursor, date: selectedDate);
    final response = await getMemoryList(req);
    if (response != null) {
      hasMore = response.hasMore;
      _cursor = response.memorys.last.id;
      recordCount = response.memoryTotal;
      final list = response.memorys.map((memory) => memory.toMPMemoryItem()).toList();
      _remoteItems.addAll(list);
      _updateItems();
    }
    loadingMore = false;
    notifyListeners();
  }

  void updateSDRecordCountAndIndex({required int value, required int index}) {
    if (value <= 0 || index < 0 || index >= value) {
      sdRecordCount = 0;
      sdRecordIndex = 0;
      importAudioType = MPHomeImportAudioType.none;
      notifyListeners();
      return;
    }
    sdRecordCount = value;
    sdRecordIndex = index;
    importAudioType = MPHomeImportAudioType.sdCard;
    notifyListeners();
  }

  void updateSDRecordIndex(int value) {
    if (value < 0 || value >= sdRecordCount) {
      sdRecordIndex = 0;
      importAudioType = MPHomeImportAudioType.none;
      notifyListeners();
      return;
    }
    sdRecordIndex = value;
    importAudioType = MPHomeImportAudioType.sdCard;
    notifyListeners();
  }

  void updateUploadPercent(double value) {
    uploadPercent = value;
    notifyListeners();
  }

  void updateImportAudioType(MPHomeImportAudioType type) {
    importAudioType = type;
    notifyListeners();
  }

  void updateSDRecordSpeed(double value) {
    sdRecordSpeed = value;
    notifyListeners();
  }

  void updateRecordCount(int value) {
    recordCount = value;
    notifyListeners();
  }

  /// 将日期字符串（yyyy-MM-dd 或 yyyy-M-d）转换为 MMM d 格式
  ///
  /// [dateString] 日期字符串，例如：2025-12-8 或 2025-12-08
  /// @returns 格式化后的日期字符串，例如：Dec 8
  String formatDateToMonthDay(String dateString) {
    return MPTimestampUtils.dateStringToMonthDay(dateString);
  }

  void updateSelectedDate(DateTime date) {
    final timestamp = MPTimestampUtils.dateTimeToTimestamp(date);
    final dateString = MPTimestampUtils.timestampToDateString(timestamp);
    if (selectedDate == dateString) return;
    selectedDate = dateString;
    notifyListeners();
    refresh();
  }

  /// 添加本地记录
  /// @param item 本地记录
  Future<void> addLocalRecord(String path, {int? duration, String? fileName, required String source}) async {
    // 通过path获取到filename

    final String name = fileName ?? path.split('/').last;
    _localRecords = await MPLocalRecordsUtil.instance
        .addLocalRecord(path, createAt: MPTimestampUtils.timestampNow, fileName: name, source: source);
    _updateItems();
  }

  Future<void> addLocalRecordModel(MPLocalMemoryModel model) async {
    _localRecords = await MPLocalRecordsUtil.instance.addLocalRecord(model.path,
        duration: model.duration, createAt: model.createAt, fileName: model.fileName, source: model.source);
    _updateItems();
  }

  /// 删除本地记录
  /// @param item 本地记录
  Future<void> removeLocalRecord(String path, {required String fildId}) async {
    _localRecords = await MPLocalRecordsUtil.instance.removeLocalRecord(path, fildId: fildId);
    _updateItems();
  }

  /// 加载本地记录
  /// @returns 无返回值
  Future<void> loadLocalRecords() async {
    _localRecords = await MPLocalRecordsUtil.instance.getLocalRecords();
    _updateItems();
  }

  /// 更新items
  void _updateItems() {
    List<MPMemoryItem> localItems = [];
    for (var element in _localRecords) {
      if (element.isRemoved) continue;
      final memory = MPMemoryStruct(
        id: 'local_${element.createAt}',
        createAt: element.createAt,
        duration: 0,
        type: MPMemoryType.onlyRecord,
        label: '',
        title: element.showName,
        content: '',
      );
      final item = memory.toMPMemoryItem();
      item.localPath = element.path;
      item.isUploading = true;
      print('------hj------create localitem: ${item.headerText}, isUploading: ${item.isUploading}');
      localItems.add(item);
    }
    List<MPMemoryItem> list = [];
    // 合并 _remoteItems 和 localItems，根据 createAt 排序生成新 list
    list.addAll(_remoteItems);
    list.addAll(localItems);
    list.sort((a, b) => b.memory.createAt.compareTo(a.memory.createAt)); // 降序，最新在前
    for (var element in list) {
      print('------hj------list item: ${element.headerText}, isUploading: ${element.isUploading}');
    }
    items = list;
    notifyListeners();
  }

  /// 上传本地记录
  /// @returns 无返回值
  void uploadLocalRecords() async {
    for (var element in _localRecords) {
      if (element.isRemoved) continue;
      final file = File(element.path);
      final uri = await MPAudioUploadService().uploadMPAudio(file, onProgress: (current, total) {});
      if (uri != null) {
        final req = MPCreateRecordRequest(
          recordFile: uri,
          createAt: element.createAt,
          duration: 0,
          source: element.source,
        );

        if (_rightNowTranscribe) {
          final res = await createRecord(req);
          if (res != null) {
            final summaryReq = MPSummaryRecordRequest(
              memoryId: res.memoryId,
              recordUrl: res.recordUrl,
              recordMemoAt: element.createAt,
            );
            final summaryRes = await summaryRecord(summaryReq);
            if (summaryRes != null) {
              await removeLocalRecord(element.path, fildId: MPLocalRecordsUtil.getFileIdFromUrl(uri));
              refresh();
            }
          }
        } else {
          final res = await createRecord(req);
          if (res != null) {
            await removeLocalRecord(element.path, fildId: MPLocalRecordsUtil.getFileIdFromUrl(uri));
            refresh();
          }
        }
      }
    }
  }

  /// 分享卡片
  /// @param context 上下文
  /// @param item 记忆项
  void onCardShare(BuildContext context, MPMemoryItem item) {
    MPShareMemoryDialog.show(context: context, memoryId: item.memory.id);
  }

  /// 删除卡片
  /// @param context 上下文
  /// @param item 记忆项
  void onCardDelete(BuildContext context, MPMemoryItem item) {
    debugPrint('Delete tapped for ${item.headerText}');
    // 显示确认对话框
    MPDeleteMemoryDialog.show(
      context: context,
      onCancel: () {
        debugPrint('Delete cancelled');
      },
      onConfirm: () async {
        // 执行删除操作
        if (item.isUploading == true) {
          await removeLocalRecord(item.localPath ?? '', fildId: '');
          uploadLocalRecords();
        } else {
          final req = MPDeleteMemoryRequest(memoryId: item.memory.id);
          final response = await deleteMemory(req);
          if (response != null) {
            if (response.baseResp.code == 0) {
              refresh();
            } else {
              MPToastUtils.showMessage(response.baseResp.message);
            }
          }
        }
      },
    );
  }
}
