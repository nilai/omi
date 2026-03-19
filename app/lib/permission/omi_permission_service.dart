import 'package:permission_manager/permission_manager.dart';

class OmiPermissionService {
  /// 申请麦克风权限，并返回详细状态。
  ///
  /// @return `PermissionManagerStatus` 例如 `granted`、`denied`、`permanentlyDenied`
  static Future<PermissionManagerStatus> requestMicrophonePermissionStatus() async {
    return await PermissionManager.request(
      PermissionManagerPermission.microphone,
    );
  }

  /// 申请麦克风权限。
  ///
  /// @return `true` 表示已授予，`false` 表示未授予
  static Future<bool> requestMicrophonePermission() async {
    final PermissionManagerStatus status = await requestMicrophonePermissionStatus();
    return status == PermissionManagerStatus.granted;
  }

  /// 检查麦克风权限是否已授予。
  ///
  /// @return `true` 表示已授予，`false` 表示未授予
  static Future<bool> hasMicrophonePermission() async {
    final PermissionManagerStatus status =
        await PermissionManager.check(PermissionManagerPermission.microphone);
    return status == PermissionManagerStatus.granted;
  }

  /// 检查麦克风权限的详细状态。
  ///
  /// @return `PermissionManagerStatus` 例如 `granted`、`denied`、`permanentlyDenied`
  static Future<PermissionManagerStatus> microphonePermissionStatus() async {
    return await PermissionManager.check(PermissionManagerPermission.microphone);
  }
}
