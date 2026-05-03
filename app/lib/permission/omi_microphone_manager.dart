import 'package:permission_manager/permission_manager.dart';

import '../utils/mp_toast_utils.dart';
import 'omi_permission_service.dart';

class OmiMicrophoneManager {
  /// 确保麦克风可用：必要时发起申请，并用全局 Toast 提示结果。
  ///
  /// - 已授权：直接 `true`。
  /// - 本次授权成功：`true`。
  /// - 拒绝 / 永久拒绝 / 异常：`false`，并给出对应英文提示（含再次进入时的明确说明）。
  static Future<bool> ensureMicrophonePermission() async {
    try {
      final PermissionManagerStatus current =
          await OmiPermissionService.microphonePermissionStatus();
      if (current == PermissionManagerStatus.granted) {
        return true;
      }
      if (current == PermissionManagerStatus.permanentlyDenied) {
        MPToastUtils.showMessage(
          'Microphone access is blocked. Open Settings and allow microphone access for this app.',
          duration: const Duration(seconds: 5),
        );
        return false;
      }
      if (current == PermissionManagerStatus.restricted) {
        MPToastUtils.showMessage(
          'Microphone access is restricted on this device.',
          duration: const Duration(seconds: 5),
        );
        return false;
      }

      final PermissionManagerStatus status =
          await OmiPermissionService.requestMicrophonePermissionStatus();

      if (status == PermissionManagerStatus.granted) {
        return true;
      }

      if (status == PermissionManagerStatus.permanentlyDenied) {
        MPToastUtils.showMessage(
          'Microphone access is blocked. Open Settings and allow microphone access for this app.',
          duration: const Duration(seconds: 5),
        );
        return false;
      }

      if (status == PermissionManagerStatus.restricted) {
        MPToastUtils.showMessage(
          'Microphone access is restricted on this device.',
          duration: const Duration(seconds: 5),
        );
        return false;
      }

      MPToastUtils.showMessage(
        'Microphone permission is required to record. Tap Allow if prompted, or enable it in Settings.',
        duration: const Duration(seconds: 5),
      );
      return false;
    } catch (_) {
      MPToastUtils.showMessage(
        'Could not request microphone permission. Please try again.',
        duration: const Duration(seconds: 5),
      );
      return false;
    }
  }
}
