import 'package:flutter/cupertino.dart';
import 'package:permission_manager/permission_manager.dart';
import 'package:omi/permission/omi_permission_service.dart';

/// 麦克风权限说明与申请页，与 Home 录音入口、系统设置串联。
class MPRecordingPermissionPage extends StatefulWidget {
  const MPRecordingPermissionPage({super.key});

  @override
  State<MPRecordingPermissionPage> createState() => _MPRecordingPermissionPageState();
}

class _MPRecordingPermissionPageState extends State<MPRecordingPermissionPage> {
  PermissionManagerStatus? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  /// 读取当前麦克风权限状态（不弹系统对话框）
  Future<void> _refreshStatus() async {
    setState(() => _loading = true);
    try {
      final s = await OmiPermissionService.microphonePermissionStatus();
      if (mounted) {
        setState(() {
          _status = s;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _status = null;
          _loading = false;
        });
      }
    }
  }

  /// 触发系统权限弹窗并刷新展示
  Future<void> _requestPermission() async {
    setState(() => _loading = true);
    try {
      final s = await OmiPermissionService.requestMicrophonePermissionStatus();
      if (mounted) {
        setState(() {
          _status = s;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// 打开系统应用设置（iOS/Android 兼容由 permission_manager 处理）
  Future<void> _openSystemSettings() async {
    await PermissionManager.openAppSettings();
    await _refreshStatus();
  }

  String _statusLabel(PermissionManagerStatus? s) {
    if (s == null) {
      return '未知';
    }
    return switch (s) {
      PermissionManagerStatus.granted => '已授权',
      PermissionManagerStatus.denied => '已拒绝',
      PermissionManagerStatus.permanentlyDenied => '已永久拒绝（需到系统设置开启）',
      _ => '其他：$s',
    };
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Microphone Permission'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '录音权限管理',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                '录音功能需要访问麦克风。若曾拒绝，可在系统设置中手动开启；永久拒绝时需通过「去设置」跳转。',
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Center(child: CupertinoActivityIndicator())
              else
                Text(
                  '当前状态：${_statusLabel(_status)}',
                  style: const TextStyle(fontSize: 15),
                ),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                onPressed: _loading ? null : _requestPermission,
                child: const Text('请求权限'),
              ),
              CupertinoButton(
                onPressed: _openSystemSettings,
                child: const Text('打开系统设置'),
              ),
              CupertinoButton(
                onPressed: _refreshStatus,
                child: const Text('刷新状态'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
