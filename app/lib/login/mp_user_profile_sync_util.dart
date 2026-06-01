import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../http/api/mp_user.dart';
import '../http/schema/mp_user.dart';
import '../http/shared.dart';
import 'mp_user.dart';

/// 登录后会话内同步用户资料（语言、时区等）到服务端。
class MPUserProfileSyncUtil {
  MPUserProfileSyncUtil._();

  /// 已登录时上报当前本地资料与设备语言、时区；未登录或无 token 时直接返回。
  static Future<void> syncIfLoggedIn() async {
    if (!ApiTools.hasAccessToken()) {
      return;
    }
    try {
      final MPUpdateUserProfileRequest req = await buildRequest();
      final MPUpdateUserProfileResponse? response = await updateUserProfile(req);
      if (response == null || response.baseResp.code != 0) {
        debugPrint(
          'MPUserProfileSyncUtil.syncIfLoggedIn failed: ${response?.baseResp.message ?? 'null response'}',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('MPUserProfileSyncUtil.syncIfLoggedIn error: $error\n$stackTrace');
    }
  }

  /// 组装更新资料请求：资料字段取 [MPUser] 本地缓存，语言与时区取当前设备值。
  static Future<MPUpdateUserProfileRequest> buildRequest() async {
    final MPUser user = MPUser.instance;
    final String language = PlatformDispatcher.instance.locale.toLanguageTag();
    final String timezone = await FlutterTimezone.getLocalTimezone();
    return MPUpdateUserProfileRequest(
      name: user.name.trim(),
      email: user.email.trim(),
      avatar: user.avatar.trim(),
      phone: user.phone.trim(),
      brithday: user.brithday.trim(),
      language: language,
      timezone: timezone,
    );
  }
}
