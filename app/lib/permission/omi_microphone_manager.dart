import 'package:flutter/material.dart';
import 'package:permission_manager/permission_manager.dart';
import 'omi_permission_service.dart';

class OmiMicrophoneManager {
  /// 申请麦克风权限，并给出可见反馈。
  static Future<void> ensureMicrophonePermission(BuildContext context) async {
    try {
      final PermissionManagerStatus status =
      await OmiPermissionService.requestMicrophonePermissionStatus();
      if (!context.mounted) return;

      final messenger = ScaffoldMessenger.of(context);

      if (status == PermissionManagerStatus.granted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('麦克风权限已授权'),
          ),
        );
        return;
      }

      if (status == PermissionManagerStatus.permanentlyDenied) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('麦克风权限已被永久拒绝，请到系统设置中开启'),
            action: SnackBarAction(
              label: '去设置',
              onPressed: () async {
                await PermissionManager.openAppSettings();
              },
            ),
          ),
        );
        return;
      }

      // 普通拒绝：一般意味着用户点了“拒绝”，此时系统弹窗不会再自动出现了。
      messenger.showSnackBar(
        const SnackBar(
          content: Text('需要麦克风权限，请在弹窗中选择“允许”后重试'),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('权限申请失败，请稍后重试'),
        ),
      );
    }
  }
}