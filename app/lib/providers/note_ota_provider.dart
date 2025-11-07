/// Note 设备 OTA 升级状态管理 Provider
/// 负责 OTA 升级流程的状态管理和进度跟踪

import 'package:flutter/foundation.dart';
import '../services/devices/note_ota_service.dart';
import '../services/devices/note_commands.dart';
import 'note_device_provider.dart';
import 'base_provider.dart';

/// OTA 升级状态
enum OtaState {
  /// 空闲状态
  idle,

  /// 正在检查更新
  checking,

  /// 正在下载固件
  downloading,

  /// 正在传输固件到设备
  transferring,

  /// 正在升级
  upgrading,

  /// 升级完成
  completed,

  /// 升级失败
  failed,
}

/// Note 设备 OTA Provider
///
/// 功能:
/// - 检查云端版本更新
/// - 下载固件
/// - 传输固件到设备
/// - 触发设备升级
/// - 跟踪升级进度和状态
class NoteOtaProvider extends BaseProvider {
  final NoteDeviceProvider _deviceProvider;
  NoteOtaService? _otaService;

  /// 当前 OTA 状态
  OtaState _state = OtaState.idle;

  /// 状态消息
  String _statusMessage = '';

  /// 传输进度 (0.0 ~ 1.0)
  double _progress = 0.0;

  /// 版本信息
  OtaVersionInfo? _versionInfo;

  /// 获取当前状态
  OtaState get state => _state;

  /// 获取状态消息
  String get statusMessage => _statusMessage;

  /// 获取进度
  double get progress => _progress;

  /// 是否有更新
  bool get hasUpdate => _versionInfo?.needsUpdate ?? false;

  /// 获取版本信息
  OtaVersionInfo? get versionInfo => _versionInfo;

  NoteOtaProvider(this._deviceProvider) {
    // 监听设备连接状态
    _deviceProvider.addListener(_onDeviceStateChanged);
  }

  /// 设备状态变化时更新 OTA 服务实例
  void _onDeviceStateChanged() {
    final connection = _deviceProvider.connection;
    if (connection != null && _otaService == null) {
      _otaService = NoteOtaService(connection);
      print('[NoteOtaProvider] OTA 服务已初始化');
    } else if (connection == null) {
      _otaService = null;
      print('[NoteOtaProvider] OTA 服务已清理');
    }
  }

  /// 检查更新
  ///
  /// currentVersion: 当前设备版本
  Future<void> checkUpdate(String currentVersion) async {
    if (_otaService == null) {
      throw Exception('设备未连接,无法检查更新');
    }

    _state = OtaState.checking;
    _statusMessage = '正在检查更新...';
    setLoadingState(true);
    notifyListeners();

    try {
      print('[NoteOtaProvider] 开始检查更新: 当前版本 $currentVersion');

      _versionInfo = await _otaService!.checkVersion(currentVersion);

      _state = OtaState.idle;
      _statusMessage = _versionInfo!.needsUpdate ? '发现新版本' : '已是最新版本';

      print('[NoteOtaProvider] 检查更新完成: $_statusMessage');
    } catch (e) {
      _state = OtaState.failed;
      _statusMessage = '检查更新失败: $e';
      print('[NoteOtaProvider] 检查更新失败: $e');
    } finally {
      setLoadingState(false);
      notifyListeners();
    }
  }

  /// 执行升级
  ///
  /// 按顺序升级所有需要更新的模块
  Future<void> performUpgrade() async {
    if (_otaService == null) {
      throw Exception('设备未连接,无法执行升级');
    }

    if (_versionInfo == null || !_versionInfo!.needsUpdate) {
      throw Exception('没有可用的更新');
    }

    setLoadingState(true);

    try {
      print('[NoteOtaProvider] 开始执行升级');

      // 升级 8711 模块
      if (_versionInfo!.need8711Update && _versionInfo!.url8711 != null) {
        print('[NoteOtaProvider] 开始升级 8711 模块');
        await _upgradeModule(
          NoteOtaModule.module8711,
          _versionInfo!.url8711!,
        );
        print('[NoteOtaProvider] 8711 模块升级完成');
      }

      // 升级 3085 模块
      if (_versionInfo!.need3085Update && _versionInfo!.url3085 != null) {
        print('[NoteOtaProvider] 开始升级 3085 模块');
        await _upgradeModule(
          NoteOtaModule.module3085,
          _versionInfo!.url3085!,
        );
        print('[NoteOtaProvider] 3085 模块升级完成');
      }

      _state = OtaState.completed;
      _statusMessage = '升级完成';
      print('[NoteOtaProvider] 所有模块升级完成');
    } catch (e) {
      _state = OtaState.failed;
      _statusMessage = '升级失败: $e';
      print('[NoteOtaProvider] 升级失败: $e');
    } finally {
      setLoadingState(false);
      notifyListeners();
    }
  }

  /// 升级单个模块
  ///
  /// module: 模块类型
  /// url: 固件下载地址
  Future<void> _upgradeModule(NoteOtaModule module, String url) async {
    final moduleName = module == NoteOtaModule.module8711 ? '8711' : '3085';

    try {
      // 1. 下载固件
      _state = OtaState.downloading;
      _statusMessage = '正在下载 $moduleName 固件...';
      _progress = 0.0;
      notifyListeners();

      print('[NoteOtaProvider] 下载 $moduleName 固件: $url');
      final firmwareFile = await _otaService!.downloadFirmware(url, moduleName);
      print('[NoteOtaProvider] $moduleName 固件下载完成');

      // 2. 传输固件到设备
      _state = OtaState.transferring;
      _statusMessage = '正在传输 $moduleName 固件到设备...';
      _progress = 0.0;
      notifyListeners();

      print('[NoteOtaProvider] 开始传输 $moduleName 固件');
      final transferSuccess = await _otaService!.transferFirmware(
        firmwareFile,
        module,
        (progress) {
          _progress = progress;
          if (progress % 0.1 < 0.01 || progress >= 0.99) {
            // 每 10% 更新一次 UI
            notifyListeners();
          }
        },
      );

      if (!transferSuccess) {
        throw Exception('固件传输失败');
      }

      print('[NoteOtaProvider] $moduleName 固件传输完成');

      // 3. 触发升级
      _state = OtaState.upgrading;
      _statusMessage = '正在升级 $moduleName 模块...';
      _progress = 1.0;
      notifyListeners();

      print('[NoteOtaProvider] 触发 $moduleName 模块升级');
      final upgradeSuccess = await _otaService!.triggerUpgrade(module);

      if (!upgradeSuccess) {
        throw Exception('升级触发失败');
      }

      print('[NoteOtaProvider] $moduleName 模块升级成功');

      // 等待设备完成升级
      await Future.delayed(Duration(seconds: 2));
    } catch (e) {
      print('[NoteOtaProvider] 升级 $moduleName 模块失败: $e');
      rethrow;
    }
  }

  /// 重置状态
  void reset() {
    _state = OtaState.idle;
    _statusMessage = '';
    _progress = 0.0;
    _versionInfo = null;
    setLoadingState(false);
    notifyListeners();
    print('[NoteOtaProvider] 状态已重置');
  }

  /// 获取状态描述文本
  String getStateDescription() {
    switch (_state) {
      case OtaState.idle:
        return '就绪';
      case OtaState.checking:
        return '检查更新中';
      case OtaState.downloading:
        return '下载中';
      case OtaState.transferring:
        return '传输中 ${(_progress * 100).toStringAsFixed(0)}%';
      case OtaState.upgrading:
        return '升级中';
      case OtaState.completed:
        return '升级完成';
      case OtaState.failed:
        return '升级失败';
    }
  }

  @override
  void dispose() {
    _deviceProvider.removeListener(_onDeviceStateChanged);
    super.dispose();
  }
}
