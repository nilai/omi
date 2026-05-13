import 'package:flutter/material.dart';

import '../blu/mp_ble_preferences.dart';
import '../blu/mp_bluetooth_connection_helper.dart';
import '../cache/omi_cache_manager.dart';
import '../cache/mp_hive_util.dart';
import '../http/api/mp_login.dart';
import '../main.dart';
import 'home/mp_login_page.dart';
import 'mp_user.dart';

/// 登录相关工具。
class MPLoginUtil {
  MPLoginUtil._();

  /// 退出登录：
  /// 1) 尝试调用服务端退出接口（失败不阻断）
  /// 2) 清理本地会话与 BLE 连接
  /// 3) 跳回登录页（支持传入页面 context；未传则走全局 context）
  static Future<void> signOut({BuildContext? context}) async {
    try {
      await logout();
    } catch (_) {
      // 网络失败不阻断本地退出。
    }

    await OmiCacheManager().finalizeServerCacheBeforeLogoutKeepDisk();
    await MPUser.instance.clear();
    await MPBlePreferences.instance.clearLastConnectedBleDevice();
    await MPHiveUtil.instance.close();
    await MPBluetoothConnectionHelper.disconnectAppBleForLogout();

    final BuildContext? targetContext = context ?? MyApp.navigatorKey.currentContext;
    if (targetContext == null || !targetContext.mounted) {
      return;
    }

    await Navigator.of(targetContext).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const MPLoginPage()),
      (Route<dynamic> route) => false,
    );
  }
}
