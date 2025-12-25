// AI-generated START - 设置页面状态管理Provider
import 'package:flutter/material.dart';
import 'package:omi/backend/http/api/privacy.dart';
import 'package:omi/backend/http/mp_api/mp_expert.dart';
import 'package:omi/backend/http/mp_api/mp_memo.dart';
import 'package:omi/backend/http/mp_api/mp_speaker.dart';
import 'package:omi/backend/preferences.dart';
import 'package:omi/backend/schema/mp/mp_expert.dart';
import 'package:omi/backend/schema/mp/mp_memo.dart';
import 'package:omi/backend/schema/mp/mp_speaker.dart';
import 'package:omi/pages/mp_newsetting/home/widgets/expert_feedback_card_widget.dart';

/// 设置页面状态管理Provider
/// 管理用户资料数据、speaker 列表和专家列表
class SettingsProvider with ChangeNotifier {
  // AI-generated START - 是否正在加载
  final bool _isLoading = false;
  // AI-generated END - _isLoading

  // AI-generated START - 错误信息
  String? _error;
  // AI-generated END - _error

  // AI-generated START - Speaker 头像列表
  List<String> _friendAvatars = [];
  // AI-generated END - _friendAvatars

  // AI-generated START - 是否正在加载 speaker 列表
  bool _isLoadingSpeakers = false;
  // AI-generated END - _isLoadingSpeakers

  // AI-generated START - 专家列表
  List<ExpertInfo> _experts = [];
  // AI-generated END - _experts

  // AI-generated START - 是否正在加载专家列表
  bool _isLoadingExperts = false;
  // AI-generated END - _isLoadingExperts

  // AI-generated START - 转写模式：true = 确认后转写，false = 立即转写
  bool _transcriptionConfirmMode = true;
  // AI-generated END - _transcriptionConfirmMode

  // AI-generated START - 音频保留时间
  String _audioRetentionPeriod = '1 month';
  // AI-generated END - _audioRetentionPeriod

  // AI-generated START - 获取是否正在加载
  bool get isLoading => _isLoading;
  // AI-generated END - isLoading

  // AI-generated START - 获取错误信息
  String? get error => _error;
  // AI-generated END - error

  // AI-generated START - 获取 friend avatars
  List<String> get friendAvatars => _friendAvatars;
  // AI-generated END - friendAvatars

  // AI-generated START - 获取是否正在加载 speaker 列表
  bool get isLoadingSpeakers => _isLoadingSpeakers;
  // AI-generated END - isLoadingSpeakers

  // AI-generated START - 获取专家列表
  List<ExpertInfo> get experts => _experts;
  // AI-generated END - experts

  // AI-generated START - 获取是否正在加载专家列表
  bool get isLoadingExperts => _isLoadingExperts;
  // AI-generated END - isLoadingExperts

  // AI-generated START - 获取转写模式
  bool get transcriptionConfirmMode => _transcriptionConfirmMode;
  // AI-generated END - transcriptionConfirmMode

  // AI-generated START - 获取音频保留时间
  String get audioRetentionPeriod => _audioRetentionPeriod;
  // AI-generated END - audioRetentionPeriod

  // 保存转写模式到服务器
  Future<bool> saveTranscriptionMode(bool confirmMode) async {
    try {
      // confirmMode 和 rightNowTranscribe 是相反的
      // confirmMode = true (确认后转写) -> rightNowTranscribe = false
      // confirmMode = false (立即转写) -> rightNowTranscribe = true
      final rightNowTranscribe = !confirmMode;

      final request = MPUpdateMemoAIRequest(
        rightNowTranscribe: rightNowTranscribe,
      );

      final response = await updateMemoAI(request);

      if (response != null) {
        _transcriptionConfirmMode = confirmMode;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to save transcription mode: $e');
      return false;
    }
  }
  // AI-generated END - saveTranscriptionMode

  // AI-generated START - 设置音频保留时间
  void setAudioRetentionPeriod(String period) {
    _audioRetentionPeriod = period;
    SharedPreferencesUtil().audioRetentionPeriod = period;
    notifyListeners();
  }
  // AI-generated END - setAudioRetentionPeriod

  // AI-generated START - 初始化音频保留时间（从 SharedPreferences 加载）
  void initAudioRetentionPeriod() {
    _audioRetentionPeriod = SharedPreferencesUtil().audioRetentionPeriod;
  }
  // AI-generated END - initAudioRetentionPeriod

  // AI-generated START - 从服务器加载转写模式
  /// 从 getUserProfile API 获取 right_now_transcribe 并更新转写模式
  /// right_now_transcribe = true 表示立即转写（对应 _transcriptionConfirmMode = false）
  /// right_now_transcribe = false 表示确认后转写（对应 _transcriptionConfirmMode = true）
  Future<void> loadTranscriptionMode() async {
    try {
      final userProfile = await PrivacyApi.getUserProfile();
      debugPrint('loadTranscriptionMode - userProfile: $userProfile');

      final rightNowTranscribe = userProfile['right_now_transcribe'] as bool?;
      debugPrint('loadTranscriptionMode - right_now_transcribe: $rightNowTranscribe');

      if (rightNowTranscribe != null) {
        // right_now_transcribe 和 _transcriptionConfirmMode 是相反的
        // right_now_transcribe = true (立即转写) -> _transcriptionConfirmMode = false
        // right_now_transcribe = false (确认后转写) -> _transcriptionConfirmMode = true
        _transcriptionConfirmMode = !rightNowTranscribe;
        debugPrint('loadTranscriptionMode - _transcriptionConfirmMode updated to: $_transcriptionConfirmMode');
        notifyListeners();
      } else {
        debugPrint('loadTranscriptionMode - right_now_transcribe is null, keeping default value');
      }
    } catch (e) {
      debugPrint('Failed to load transcription mode: $e');
      // 如果加载失败，保持默认值（false = 立即转写）
    }
  }
  // AI-generated END - loadTranscriptionMode

  // AI-generated START - 从接口加载 speaker 列表
  Future<void> loadSpeakerList() async {
    if (_isLoadingSpeakers) return;

    _isLoadingSpeakers = true;
    notifyListeners();

    try {
      final request = MPGetSpeakerListRequest(
        pageSize: 10, // 获取前10个 speaker
        cursor: '', // 从第一页开始
      );
      final response = await getSpeakerList(request);

      if (response != null && response.speakers.isNotEmpty) {
        // 提取所有 speaker 的 avatar URL
        _friendAvatars =
            response.speakers.where((speaker) => speaker.avatar.isNotEmpty).map((speaker) => speaker.avatar).toList();
      }
    } catch (e) {
      debugPrint('Failed to load speaker list: $e');
      _error = 'Failed to load speaker list: $e';
    } finally {
      _isLoadingSpeakers = false;
      notifyListeners();
    }
  }
  // AI-generated END - 从接口加载 speaker 列表

  // AI-generated START - 从接口加载专家列表
  Future<void> loadExpertList() async {
    if (_isLoadingExperts) return;

    _isLoadingExperts = true;
    notifyListeners();

    try {
      final request = MPGetExpertListRequest(
        pageSize: 10, // 获取前10个专家
        cursor: '', // 从第一页开始
      );
      final response = await getExpertList(request);

      if (response != null && response.experts.isNotEmpty) {
        // 将 API 返回的专家数据转换为 ExpertInfo
        _experts = response.experts.map((expertMerge) {
          final expert = expertMerge.expert;
          // 根据专家名称或 capabilities 生成边框颜色
          final borderColor = _getBorderColorForExpert(expert.name);
          return ExpertInfo(
            name: expert.name,
            role: expert.name,
            avatarUrl: (expert.avatar != null && expert.avatar!.isNotEmpty) ? expert.avatar : null,
            borderColor: borderColor,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Failed to load expert list: $e');
      _error = 'Failed to load expert list: $e';
    } finally {
      _isLoadingExperts = false;
      notifyListeners();
    }
  }
  // AI-generated END - 从接口加载专家列表

  // AI-generated START - 根据专家名称获取边框颜色
  Color _getBorderColorForExpert(String name) {
    // 根据专家名称或类型返回不同的颜色
    final nameLower = name.toLowerCase();
    if (nameLower.contains('商业') || nameLower.contains('business')) {
      return const Color(0xFF60A5FA); // 浅蓝色
    } else if (nameLower.contains('技术') || nameLower.contains('tech')) {
      return const Color(0xFFA78BFA); // 浅紫色
    } else if (nameLower.contains('营销') || nameLower.contains('marketing')) {
      return const Color(0xFF34D399); // 浅绿色
    } else if (nameLower.contains('财务') || nameLower.contains('finance')) {
      return const Color(0xFFFB923C); // 浅橙色
    } else if (nameLower.contains('法律') || nameLower.contains('legal')) {
      return const Color(0xFFF472B6); // 浅粉色
    } else {
      // 默认颜色，可以根据需要调整
      return const Color(0xFF60A5FA); // 浅蓝色
    }
  }
  // AI-generated END - _getBorderColorForExpert
}
// AI-generated END - settings_provider.dart
