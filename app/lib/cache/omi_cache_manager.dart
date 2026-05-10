import 'package:memo_pin/cache/omi_server_cache.dart';

class OmiCacheManager {
  /// 从磁盘恢复缓存到内存；请在 `runApp` 前 `await` 一次（需先 [WidgetsFlutterBinding.ensureInitialized]）
  Future<void> initialize() => OmiServerCache().initialize();

      /// 缓存首页第一页数据
  void putHomeFirstPage(Object? value) => OmiServerCache().putJson(OmiCacheKeys.homeFirstPage, value);

  /// 读取首页第一页数据
  dynamic getHomeFirstPage() => OmiServerCache().getDecoded(OmiCacheKeys.homeFirstPage);

  /// 缓存 Memory 第一页数据
  void putMemoryFirstPage(Object? value) => OmiServerCache().putJson(OmiCacheKeys.memoryFirstPage, value);

  /// 读取 Memory 第一页数据
  dynamic getMemoryFirstPage() => OmiServerCache().getDecoded(OmiCacheKeys.memoryFirstPage);

  /// 缓存详情（按 [memoryId] + [detailKind]；仅“列表第一页”的详情允许写入）
  ///
  /// [detailKind] 使用 [OmiCacheKeys.memoryDetailKindMemoryFeedSummary] 等常量。
  void putMemoryDetail(String memoryId, String detailKind, Object? value) =>
      OmiServerCache().putJson(OmiCacheKeys.memoryDetail(memoryId, detailKind), value);

  /// 读取详情（按 [memoryId] + [detailKind]；仅当该 id 属于“列表第一页”时调用方才应使用）
  dynamic getMemoryDetail(String memoryId, String detailKind) =>
      OmiServerCache().getDecoded(OmiCacheKeys.memoryDetail(memoryId, detailKind));

  /// 缓存首页详情（按 [id]）
  void putHomeDetail(String id, Object? value) => OmiServerCache().putJson(OmiCacheKeys.homeDetail(id), value);

  /// 读取首页详情（按 [id]）
  dynamic getHomeDetail(String id) => OmiServerCache().getDecoded(OmiCacheKeys.homeDetail(id));

  /// 删除单条首页详情缓存
  void removeHomeDetail(String id) => OmiServerCache().remove(OmiCacheKeys.homeDetail(id));

  /// Today Focus / All To-Dos：写入分组列表与 candidates 原始 JSON（见 [OmiCacheKeys.todayFocusBundle]）
  void putTodayFocusBundle(Object? value) =>
      OmiServerCache().putJson(OmiCacheKeys.todayFocusBundle, value);

  /// 读取 Today Focus 缓存包（decode 后为 `Map`，含 `grouped` / 可选 `candidates`）
  dynamic getTodayFocusBundle() => OmiServerCache().getDecoded(OmiCacheKeys.todayFocusBundle);

  /// 清空所有缓存数据（首页第一页、Memory 第一页、全部首页详情等）
  void clearAll() => OmiServerCache().clear();
}