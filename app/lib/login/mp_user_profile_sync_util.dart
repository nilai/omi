import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../http/api/mp_user.dart';
import '../http/schema/mp_user.dart';
import '../http/shared.dart';
import 'mp_user.dart';

/// 登录后会话内同步用户资料（邮箱、语言、时区等）到服务端。
class MPUserProfileSyncUtil {
  MPUserProfileSyncUtil._();

  /// 已登录时上报邮箱与设备语言、时区；未登录或无 token 时直接返回。
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

  /// 组装更新资料请求：仅同步邮箱与设备语言、时区；name/avatar/phone/brithday 传空表示不更新。
  static Future<MPUpdateUserProfileRequest> buildRequest() async {
    final String language = PlatformDispatcher.instance.locale.toLanguageTag();
    final String timezone = await FlutterTimezone.getLocalTimezone();
    return MPUpdateUserProfileRequest(
      email: MPUser.instance.email.trim(),
      language: language,
      timezone: timezone,
    );
  }
}
