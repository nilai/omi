import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:memo_pin/utils/mp_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// 应用时区与 Unix 时间戳标准化（展示、比较、写入均走此处）。
class MPTimeUtils {
  MPTimeUtils._();

  static const String _prefTimeZoneKey = 'mp_cached_time_zone';

  static bool _dbInitialized = false;
  static String? _cachedTimeZoneName;

  /// 当前缓存的 IANA 时区名（如 `Asia/Shanghai`）；未初始化时为空。
  static String? get timeZoneName => _cachedTimeZoneName;

  /// 加载偏好缓存并初始化时区数据库（冷启动前调用一次即可）。
  static Future<void> ensureInitialized() async {
    if (!_dbInitialized) {
      tz_data.initializeTimeZones();
      _dbInitialized = true;
    }
    _cachedTimeZoneName ??= _readTimeZoneFromPrefs();
  }

  /// 从系统读取本地时区并写入内存与 [MPPreferences]。
  static Future<void> refreshTimeZone() async {
    await ensureInitialized();
    try {
      final String name = await FlutterTimezone.getLocalTimezone();
      if (name.trim().isEmpty) {
        return;
      }
      await _applyTimeZoneName(name.trim());
    } catch (e, stackTrace) {
      debugPrint('MPTimeUtils.refreshTimeZone failed — $e\n$stackTrace');
      _ensureFallbackTimeZone();
    }
  }

  /// `null` / `<= 0` 视为无效时间戳。
  static int? normalizeUnixTimestamp(int? raw) {
    if (raw == null || raw <= 0) {
      return null;
    }
    return raw;
  }

  /// 秒或毫秒 Unix 时间戳 → 当前应用时区下的本地 [DateTime]。
  static DateTime? dateTimeFromUnixEpoch(int? raw) {
    final int? normalized = normalizeUnixTimestamp(raw);
    if (normalized == null) {
      return null;
    }
    final int ms =
        normalized > 10000000000 ? normalized : normalized * 1000;
    return _toLocalDateTime(ms);
  }

  /// 当前应用时区下的「现在」。
  static DateTime nowInTimeZone() {
    final tz.Location loc = _location();
    return tz.TZDateTime.now(loc);
  }

  /// 当前应用时区下今日 0 点（用于 Today / Yesterday 等日历比较）。
  static DateTime startOfTodayInTimeZone() {
    final DateTime now = nowInTimeZone();
    return DateTime(now.year, now.month, now.day);
  }

  /// 本地日历 + 时刻 → Unix 秒（写入服务端 deadline / createAt 等）。
  static int? unixSecondsFromLocalParts({
    required int year,
    required int month,
    required int day,
    int hour = 0,
    int minute = 0,
    int second = 0,
  }) {
    final tz.Location loc = _location();
    final tz.TZDateTime dt = tz.TZDateTime(
      loc,
      year,
      month,
      day,
      hour,
      minute,
      second,
    );
    return dt.millisecondsSinceEpoch ~/ 1000;
  }

  /// Todo 截止时间等时间展示文案。
  ///
  /// [deadlineSec] 为 Unix 秒；`null` / `0` 展示为 `No deadline`。
  /// 当天仅 `HH:mm`；未来 7 日内为 `EEE HH:mm`；更远为 `MMM d`。
  static String formatTodoDeadlineLabel(int? deadlineSec) {
    final DateTime? dt = dateTimeFromUnixEpoch(deadlineSec);
    if (dt == null) {
      return 'No deadline';
    }
    final DateTime today = startOfTodayInTimeZone();
    final DateTime day = DateTime(dt.year, dt.month, dt.day);
    if (day == today) {
      return DateFormat('HH:mm').format(dt);
    }
    final int daysFromToday = day.difference(today).inDays;
    if (daysFromToday > 0 && daysFromToday <= 7) {
      return DateFormat('EEE HH:mm').format(dt);
    }
    return DateFormat('MMM d').format(dt);
  }

  static DateTime _toLocalDateTime(int epochMs) {
    final tz.Location loc = _location();
    return tz.TZDateTime.fromMillisecondsSinceEpoch(loc, epochMs);
  }

  static tz.Location _location() {
    _ensureFallbackTimeZone();
    final String name = _cachedTimeZoneName!;
    try {
      return tz.getLocation(name);
    } catch (_) {
      return tz.UTC;
    }
  }

  static void _ensureFallbackTimeZone() {
    if (_cachedTimeZoneName != null && _cachedTimeZoneName!.isNotEmpty) {
      return;
    }
    final String offsetName = DateTime.now().timeZoneName;
    _cachedTimeZoneName =
        offsetName.isNotEmpty ? offsetName : 'UTC';
  }

  static String? _readTimeZoneFromPrefs() {
    final String stored = MPPreferences().getString(_prefTimeZoneKey);
    return stored.isEmpty ? null : stored;
  }

  static Future<void> _applyTimeZoneName(String name) async {
    _cachedTimeZoneName = name;
    await MPPreferences().saveString(_prefTimeZoneKey, name);
  }
}
