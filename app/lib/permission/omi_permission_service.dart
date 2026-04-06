import 'dart:io' show Platform;

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

  /// 相册与本地文件导入所需权限列表。
  ///
  /// - iOS: `photos`
  /// - Android: `mediaImages`(Android 13+) + `storage`(Android 12 及以下)
  /// - 其他平台: 返回空列表，由系统/插件自行处理
  static List<PermissionManagerPermission> mediaImportPermissions() {
    if (Platform.isIOS) {
      return <PermissionManagerPermission>[PermissionManagerPermission.photos];
    }
    if (Platform.isAndroid) {
      return <PermissionManagerPermission>[
        PermissionManagerPermission.mediaImages,
        PermissionManagerPermission.storage,
      ];
    }
    return <PermissionManagerPermission>[];
  }

  /// 申请相册与本地文件导入权限，并返回是否全部授予。
  ///
  /// @return `true` 表示可继续进行图片/文件导入
  static Future<bool> requestMediaImportPermissions() async {
    final List<PermissionManagerPermission> perms = mediaImportPermissions();
    if (perms.isEmpty) {
      return true;
    }
    final Map<PermissionManagerPermission, PermissionManagerStatus> result =
        await PermissionManager.requestMultiple(perms);
    return result.values.every((PermissionManagerStatus s) => s == PermissionManagerStatus.granted);
  }

  /// 检查相册与本地文件导入权限是否已全部授予。
  static Future<bool> hasMediaImportPermissions() async {
    final List<PermissionManagerPermission> perms = mediaImportPermissions();
    if (perms.isEmpty) {
      return true;
    }
    final Map<PermissionManagerPermission, PermissionManagerStatus> result =
        await PermissionManager.checkMultiple(perms);
    return result.values.every((PermissionManagerStatus s) => s == PermissionManagerStatus.granted);
  }

  /// 返回相册/本地文件导入相关权限中「最不利」的一项状态（用于 UI 提示）。
  static Future<PermissionManagerStatus> mediaImportPermissionWorstStatus() async {
    final List<PermissionManagerPermission> perms = mediaImportPermissions();
    if (perms.isEmpty) {
      return PermissionManagerStatus.granted;
    }
    final Map<PermissionManagerPermission, PermissionManagerStatus> result =
        await PermissionManager.checkMultiple(perms);
    PermissionManagerStatus worst = PermissionManagerStatus.granted;
    for (final PermissionManagerStatus s in result.values) {
      if (s == PermissionManagerStatus.permanentlyDenied) {
        return PermissionManagerStatus.permanentlyDenied;
      }
      if (s == PermissionManagerStatus.restricted) {
        worst = PermissionManagerStatus.restricted;
      } else if (s == PermissionManagerStatus.limited && worst == PermissionManagerStatus.granted) {
        worst = PermissionManagerStatus.limited;
      } else if (s == PermissionManagerStatus.denied &&
          (worst == PermissionManagerStatus.granted || worst == PermissionManagerStatus.limited)) {
        worst = PermissionManagerStatus.denied;
      }
    }
    return worst;
  }

  /// BLE 扫描与连接所需权限列表（iOS 与 Android 策略不同；桌面/Web 返回空列表由系统处理）。
  static List<PermissionManagerPermission> bleScanConnectPermissions() {
    if (Platform.isIOS) {
      return <PermissionManagerPermission>[PermissionManagerPermission.bluetooth];
    }
    if (Platform.isAndroid) {
      return <PermissionManagerPermission>[
        PermissionManagerPermission.bluetoothScan,
        PermissionManagerPermission.bluetoothConnect,
      ];
    }
    return <PermissionManagerPermission>[];
  }

  /// 申请 BLE 扫描与连接相关权限，并返回是否全部授予。
  ///
  /// @return `true` 表示可继续进行 BLE 扫描/连接
  static Future<bool> requestBlePermissionsForScanAndConnect() async {
    final List<PermissionManagerPermission> perms = bleScanConnectPermissions();
    if (perms.isEmpty) {
      return true;
    }
    final Map<PermissionManagerPermission, PermissionManagerStatus> result =
        await PermissionManager.requestMultiple(perms);
    return result.values.every((PermissionManagerStatus s) => s == PermissionManagerStatus.granted);
  }

  /// 检查 BLE 扫描与连接权限是否已全部授予。
  static Future<bool> hasBlePermissionsForScanAndConnect() async {
    final List<PermissionManagerPermission> perms = bleScanConnectPermissions();
    if (perms.isEmpty) {
      return true;
    }
    final Map<PermissionManagerPermission, PermissionManagerStatus> result =
        await PermissionManager.checkMultiple(perms);
    return result.values.every((PermissionManagerStatus s) => s == PermissionManagerStatus.granted);
  }

  /// 返回 BLE 扫描/连接相关权限中「最不利」的一项状态（用于 UI 提示）。
  static Future<PermissionManagerStatus> bleScanConnectPermissionWorstStatus() async {
    final List<PermissionManagerPermission> perms = bleScanConnectPermissions();
    if (perms.isEmpty) {
      return PermissionManagerStatus.granted;
    }
    final Map<PermissionManagerPermission, PermissionManagerStatus> result =
        await PermissionManager.checkMultiple(perms);
    PermissionManagerStatus worst = PermissionManagerStatus.granted;
    for (final PermissionManagerStatus s in result.values) {
      if (s == PermissionManagerStatus.permanentlyDenied) {
        return PermissionManagerStatus.permanentlyDenied;
      }
      if (s == PermissionManagerStatus.restricted) {
        worst = PermissionManagerStatus.restricted;
      } else if (s == PermissionManagerStatus.denied && worst == PermissionManagerStatus.granted) {
        worst = PermissionManagerStatus.denied;
      }
    }
    return worst;
  }
}
