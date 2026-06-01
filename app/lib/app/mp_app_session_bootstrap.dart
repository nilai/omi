import '../cache/mp_hive_util.dart';
import '../cache/omi_cache_manager.dart';
import '../login/mp_user_profile_sync_util.dart';
import '../tab/askai/mp_ask_ai_question_util.dart';

/// 会话初始化入口（登录成功 / 已登录冷启动共用）。
class MPAppSessionBootstrap {
  MPAppSessionBootstrap._();

  /// 执行会话初始化。
  ///
  /// @param fromLoginSuccess `true` 表示登录/注册刚成功；`false` 表示已登录冷启动。
  static Future<void> run({required bool fromLoginSuccess}) async {
    // 关键步骤：确保当前用户 hive box 可用。
    await MPHiveUtil.instance.initialize();
    // 与 [OmiServerCache] 内存对齐到当前用户磁盘快照，避免换号后仍读到上一用户内存缓存。
    await OmiCacheManager().reloadServerCacheFromCurrentUserHive();

    // 非关键步骤：后台预热，不阻塞首屏渲染与登录后跳转。
    Future<void>(() async {
      try {
        await MPUserProfileSyncUtil.syncIfLoggedIn();
      } catch (_) {}
    });

    Future<void>(() async {
      try {
        await MPAskAIQuestionUtil.fetchQuestionsAndCache();
      } catch (_) {}
    });
  }
}
