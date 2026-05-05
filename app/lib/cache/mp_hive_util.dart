import 'package:hive_flutter/hive_flutter.dart';
import 'package:memo_pin/login/mp_user.dart';

/// 将 Hive 读出的 `Map` / `List` 递归转为 `Map<String, dynamic>` / `List`，避免 `_Map<dynamic,dynamic>` 强转失败。
Map<String, dynamic> _deepHiveJsonMap(Map<dynamic, dynamic> raw) {
  return Map<String, dynamic>.fromEntries(
    raw.entries.map(
      (MapEntry<dynamic, dynamic> e) => MapEntry(e.key.toString(), _deepHiveJsonValue(e.value)),
    ),
  );
}

dynamic _deepHiveJsonValue(dynamic value) {
  if (value is Map) {
    return _deepHiveJsonMap(Map<dynamic, dynamic>.from(value));
  }
  if (value is List) {
    return value.map(_deepHiveJsonValue).toList();
  }
  return value;
}

/// Hive 工具类（按用户邮箱分箱存储）。
///
/// - box 名称：登录邮箱的 md5（小写十六进制）
/// - key 统一使用 [String]
/// - 初始化/打开为幂等，支持多次调用
class MPHiveUtil {
  MPHiveUtil._();

  static final MPHiveUtil instance = MPHiveUtil._();

  Box<dynamic>? _box;
  Future<Box<dynamic>>? _openingFuture;
  bool _hiveInited = false;
  String? _activeBoxName;

  /// 初始化并打开当前用户对应的 box。
  ///
  /// 若多次调用：
  /// - 同邮箱：复用已打开 box
  /// - 新邮箱：自动关闭旧 box，再打开新 box
  Future<Box<dynamic>> initialize() async {
    final String targetBoxName = MPUser().userId;

    if (_box != null &&
        _box!.isOpen &&
        _activeBoxName == targetBoxName) {
      return _box!;
    }

    if (_openingFuture != null) {
      return _openingFuture!;
    }

    _openingFuture = _openBoxInternal(targetBoxName);
    try {
      final Box<dynamic> opened = await _openingFuture!;
      return opened;
    } finally {
      _openingFuture = null;
    }
  }

  Future<Box<dynamic>> _openBoxInternal(String targetBoxName) async {
    if (!_hiveInited) {
      await Hive.initFlutter();
      _hiveInited = true;
    }

    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }

    _box = await Hive.openBox<dynamic>(targetBoxName);
    _activeBoxName = targetBoxName;
    return _box!;
  }

  Future<Box<dynamic>> _ensureBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    return initialize();
  }

  /// 存储字符串。
  Future<void> putString({
    required String key,
    required String value,
  }) async {
    final Box<dynamic> box = await _ensureBox();
    await box.put(key, value);
  }

  /// 获取字符串；类型不匹配或不存在时返回 [defaultValue]。
  Future<String?> getString(
    String key, {
    String? defaultValue,
  }) async {
    final Box<dynamic> box = await _ensureBox();
    final dynamic value = box.get(key, defaultValue: defaultValue);
    if (value is String) {
      return value;
    }
    return defaultValue;
  }

  /// 存储 object（通过 toJson 转为 Map 后保存）。
  Future<void> putObject<T>({
    required String key,
    required T object,
    required Map<String, dynamic> Function(T value) toJson,
  }) async {
    final Box<dynamic> box = await _ensureBox();
    await box.put(key, toJson(object));
  }

  /// 获取 object（读取 Map 后通过 fromJson 反序列化）。
  Future<T?> getObject<T>({
    required String key,
    required T Function(Map<String, dynamic> json) fromJson,
  }) async {
    final Box<dynamic> box = await _ensureBox();
    final dynamic raw = box.get(key);
    if (raw is Map) {
      return fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  /// 存储所有基础类型（String/int/double/bool/num/List/null）。
  Future<void> putPrimitive({
    required String key,
    required dynamic value,
  }) async {
    final Box<dynamic> box = await _ensureBox();
    await box.put(key, value);
  }

  /// 获取基础类型。
  Future<T?> getPrimitive<T>(
    String key, {
    T? defaultValue,
  }) async {
    final Box<dynamic> box = await _ensureBox();
    final dynamic value = box.get(key, defaultValue: defaultValue);
    if (value is T) {
      return value;
    }
    return defaultValue;
  }

  /// 存储 Map。
  Future<void> putMap({
    required String key,
    required Map<String, dynamic> value,
  }) async {
    final Box<dynamic> box = await _ensureBox();
    await box.put(key, value);
  }

  /// 获取 Map。
  ///
  /// Hive 读出的嵌套结构常为 [Map<dynamic, dynamic>]，与接口 [fromJson] 里 `Map<String, dynamic>` 强转不兼容，故递归规范化。
  Future<Map<String, dynamic>?> getMap(String key) async {
    final Box<dynamic> box = await _ensureBox();
    final dynamic value = box.get(key);
    if (value is Map) {
      return _deepHiveJsonMap(value);
    }
    return null;
  }

  /// 删除指定 key。
  Future<void> remove(String key) async {
    final Box<dynamic> box = await _ensureBox();
    await box.delete(key);
  }

  /// 关闭并释放 Hive box。
  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
    _box = null;
    _activeBoxName = null;
  }
}
