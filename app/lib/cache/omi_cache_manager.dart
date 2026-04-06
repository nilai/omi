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

  /// 缓存首页详情（按 [id]）
  void putHomeDetail(String id, Object? value) => OmiServerCache().putJson(OmiCacheKeys.homeDetail(id), value);

  /// 读取首页详情（按 [id]）
  dynamic getHomeDetail(String id) => OmiServerCache().getDecoded(OmiCacheKeys.homeDetail(id));

  /// 删除单条首页详情缓存
  void removeHomeDetail(String id) => OmiServerCache().remove(OmiCacheKeys.homeDetail(id));

  /// 清空所有缓存数据（首页第一页、Memory 第一页、全部首页详情等）
  void clearAll() => OmiServerCache().clear();
}