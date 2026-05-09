import 'dart:convert';

import 'package:memo_pin/cache/mp_hive_util.dart';

/// 服务端数据缓存的键名（避免魔法字符串、统一多场景）
///
/// 说明：详情类数据通过 [homeDetail] 按业务 id 区分。
/// 实际数据由 [OmiServerCache] 持有：内存 + 磁盘（见 [OmiServerCache.initialize]）。
class OmiCacheKeys {
  OmiCacheKeys._();

  /// 首页列表第一页（服务端返回的 JSON 可序列化对象）
  static const String homeFirstPage = 'mp_srv_home_first_page';

  /// Memory 列表第一页
  static const String memoryFirstPage = 'mp_srv_memory_first_page';

  /// 详情缓存键前缀（完整 key = 前缀 + [detailKind] + '_' + [memoryId]）
  ///
  /// 注意：仅用于“列表第一页”的详情缓存场景；第二页及以后不做详情缓存。
  static const String _memoryDetailPrefix = 'mp_srv_memory_detail_';

  /// [OmiMemoryDetailSource.memoryFeedSummary]：Feed 内 summary 映射的 Memory 详情。
  static const String memoryDetailKindMemoryFeedSummary = 'memoryFeedSummary';

  /// [OmiMemoryDetailSource.rootSummaryMemory]：根级 summary（Memo 详情等）。
  static const String memoryDetailKindRootSummaryMemory = 'rootSummaryMemory';

  /// [MPAudioDetailCubit]：仅录音（only_record）详情。
  static const String memoryDetailKindOnlyRecord = 'onlyRecord';

  /// 详情缓存键（按 [memoryId] + [detailKind]，同 id 不同入口分区存储）
  static String memoryDetail(String memoryId, String detailKind) =>
      '$_memoryDetailPrefix${detailKind}_$memoryId';

  /// 首页点击进入的详情缓存键前缀（完整 key = 前缀 + id）
  static const String _homeDetailPrefix = 'mp_srv_home_detail';

  /// 首页详情缓存键（按 [id]）
  static String homeDetail(String id) => '$_homeDetailPrefix$id';

  /// 是否为首页详情类缓存键（用于批量清理）
  static bool isHomeDetailKey(String key) => key.startsWith(_homeDetailPrefix);
}

/// 服务端返回数据的缓存：内存 + 磁盘持久化
///
/// - **内存**：读写与 [totalSizeBytes] 均基于内存中的 Map
/// - **磁盘**：应用冷启动前请先 `await OmiServerCache().initialize()`，从磁盘恢复到内存；每次
///   [putJson] / [remove] / [clear] / [removeWhere] 后会异步写入磁盘（排队串行，避免并发写坏文件）
///
/// - 适用：接口返回的 `Map` / `List` / 基础类型等可被 [jsonEncode] 的数据
/// - 体积：[totalSizeBytes] 为所有 key + value 字符串的 UTF-8 字节数近似值（与落盘 JSON 体量一致）
class OmiServerCache {
  OmiServerCache._();

  /// 单例（全局一份缓存）
  static final OmiServerCache instance = OmiServerCache._();

  /// 与 [instance] 等价
  factory OmiServerCache() => instance;

  /// Hive 内用于持久化整张缓存表的 key（值为 JSON 字符串）。
  static const String _hiveKey = 'mp_srv_server_cache_map_v1';

  final Map<String, String> _store = <String, String>{};

  /// [initialize] 是否已执行结束（成功或失败都算，避免重复初始化）
  bool _initialized = false;

  /// 串行化持久化写入，避免并发写导致覆盖
  Future<void> _persistChain = Future<void>.value();

  /// 从持久化介质恢复数据到内存；请在 `runApp` 前调用一次（需先 [WidgetsFlutterBinding.ensureInitialized]）
  ///
  /// 重复调用会直接返回，不会重复读盘。
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final String? text = await MPHiveUtil.instance.getString(_hiveKey);
      if (text == null || text.trim().isEmpty) return;
      final Object? decoded = jsonDecode(text);
      if (decoded is! Map) return;
      final Map<String, dynamic> map = Map<String, dynamic>.from(decoded);
      for (final MapEntry<String, dynamic> e in map.entries) {
        final Object? v = e.value;
        if (v == null) continue;
        _store[e.key] = v is String ? v : jsonEncode(v);
      }
    } catch (_) {
      // 读取失败时仅使用内存缓存
    }
  }

  void _schedulePersist() {
    _persistChain = _persistChain.then((_) => _persistToDisk());
  }

  Future<void> _persistToDisk() async {
    try {
      final String payload = jsonEncode(_store);
      await MPHiveUtil.instance.putString(key: _hiveKey, value: payload);
    } catch (_) {
      // 写入失败时保留内存数据；下次启动读取时仍以旧持久化数据为准
    }
  }

  /// 写入任意可被 JSON 编码的数据；[value] 为 `null` 时删除该键
  void putJson(String key, Object? value) {
    if (value == null) {
      remove(key);
      return;
    }
    _store[key] = jsonEncode(value);
    _schedulePersist();
  }

  /// 读取并 [jsonDecode]，无缓存返回 `null`
  dynamic getDecoded(String key) {
    final String? raw = _store[key];
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  /// 读取并转换为你自己的模型（[fromJson] 接收 decode 后的 `dynamic`）
  T? getJson<T>(String key, T Function(dynamic json) fromJson) {
    final dynamic decoded = getDecoded(key);
    if (decoded == null) return null;
    return fromJson(decoded);
  }

  bool containsKey(String key) => _store.containsKey(key);

  void remove(String key) {
    _store.remove(key);
    _schedulePersist();
  }

  /// 当前所有缓存占用的大致字节数（UTF-8 下 key 字符串 + value JSON 字符串）
  int get totalSizeBytes {
    var sum = 0;
    for (final MapEntry<String, String> e in _store.entries) {
      sum += utf8.encode(e.key).length;
      sum += utf8.encode(e.value).length;
    }
    return sum;
  }

  /// 清空全部缓存（内存 + 异步清空磁盘文件）
  void clear() {
    _store.clear();
    _schedulePersist();
  }

  /// 按条件移除多条缓存
  void removeWhere(bool Function(String key) test) {
    _store.removeWhere((String k, String _) => test(k));
    _schedulePersist();
  }
}
