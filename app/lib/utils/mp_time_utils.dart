import 'package:intl/intl.dart';

/// 应用时区与 Unix 时间戳标准化（展示、比较、写入均走此处，固定 UTC）。
class MPTimeUtils {
  MPTimeUtils._();

  /// 固定 UTC 时区标识。
  static const String fixedTimeZone = 'UTC';

  /// 当前应用固定时区名（始终为 [fixedTimeZone]）。
  static String get timeZoneName => fixedTimeZone;

  /// 初始化时间工具（冷启动前调用一次即可）。
  static Future<void> ensureInitialized() async {}

  /// 应用固定 UTC 时区（保留以兼容生命周期回调）。
  static Future<void> refreshTimeZone() async {}

  /// 当前 UTC Unix 秒（写入 createAt / record_ts 等）。
  static int nowUnixSeconds() =>
      DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

  /// 当前 UTC Unix 毫秒。
  static int nowUnixMilliseconds() =>
      DateTime.now().toUtc().millisecondsSinceEpoch;

  /// 当前 UTC Unix 微秒（本地 ID 等）。
  static int nowUnixMicroseconds() =>
      DateTime.now().toUtc().microsecondsSinceEpoch;

  /// 相对当前 UTC 时刻偏移 [offset] 后的 Unix 毫秒。
  static int unixMillisecondsWithOffset(Duration offset) =>
      DateTime.now().toUtc().add(offset).millisecondsSinceEpoch;

  /// 文件修改时间等 → UTC Unix 秒。
  static int unixSecondsFromDateTime(DateTime dateTime) =>
      dateTime.toUtc().millisecondsSinceEpoch ~/ 1000;

  /// `null` / `<= 0` 视为无效时间戳。
  static int? normalizeUnixTimestamp(int? raw) {
    if (raw == null || raw <= 0) {
      return null;
    }
    return raw;
  }

  /// 秒或毫秒 Unix 时间戳 → UTC [DateTime]。
  static DateTime? dateTimeFromUnixEpoch(int? raw) {
    final int? normalized = normalizeUnixTimestamp(raw);
    if (normalized == null) {
      return null;
    }
    final int ms =
        normalized > 10000000000 ? normalized : normalized * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  /// UTC 时区下的「现在」。
  static DateTime nowInTimeZone() => DateTime.now().toUtc();

  /// UTC 时区下今日 0 点（用于 Today / Yesterday 等日历比较）。
  static DateTime startOfTodayInTimeZone() {
    final DateTime now = nowInTimeZone();
    return DateTime.utc(now.year, now.month, now.day);
  }

  /// UTC 日历 + 时刻 → Unix 秒（写入服务端 deadline / createAt 等）。
  static int? unixSecondsFromLocalParts({
    required int year,
    required int month,
    required int day,
    int hour = 0,
    int minute = 0,
    int second = 0,
  }) {
    final DateTime dt = DateTime.utc(year, month, day, hour, minute, second);
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
    final DateTime day = DateTime.utc(dt.year, dt.month, dt.day);
    if (day == today) {
      return DateFormat('HH:mm').format(dt);
    }
    final int daysFromToday = day.difference(today).inDays;
    if (daysFromToday > 0 && daysFromToday <= 7) {
      return DateFormat('EEE HH:mm').format(dt);
    }
    return DateFormat('MMM d').format(dt);
  }
}
