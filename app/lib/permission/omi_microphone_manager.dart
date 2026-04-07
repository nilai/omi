import 'package:permission_manager/permission_manager.dart';

import '../utils/mp_toast_utils.dart';
import 'omi_permission_service.dart';

class OmiMicrophoneManager {
  /// 确保麦克风可用：必要时发起申请，并用全局 Toast 提示结果。
  ///
  /// - 已授权：直接 `true`。
  /// - 本次授权成功：`true`，并提示「麦克风权限已授权」。
  /// - 拒绝 / 永久拒绝 / 异常：`false`，并给出对应提示。
  static Future<bool> ensureMicrophonePermission() async {
    try {
      if (await OmiPermissionService.hasMicrophonePermission()) {
        return true;
      }

      final PermissionManagerStatus status =
          await OmiPermissionService.requestMicrophonePermissionStatus();

      if (status == PermissionManagerStatus.granted) {
        return true;
      }

      if (status == PermissionManagerStatus.permanentlyDenied) {
        MPToastUtils.showMessage('麦克风权限已被永久拒绝，请到系统设置中开启');
        return false;
      }

      MPToastUtils.showMessage('需要麦克风权限，请在弹窗中选择“允许”后重试');
      return false;
    } catch (_) {
      MPToastUtils.showMessage('权限申请失败，请稍后重试');
      return false;
    }
  }
}
