// AI-generated START - 时间戳转换工具类

/// 时间戳转换工具类
/// 提供时间戳与 DateTime 之间的转换方法
class MPTimestampUtils {
  /// 将秒级时间戳转换为 DateTime
  ///
  /// [timestamp] 秒级时间戳
  /// 返回 [DateTime] 对象
  static DateTime timestampToDateTime(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }

  /// 将毫秒级时间戳转换为 DateTime
  ///
  /// [timestamp] 毫秒级时间戳
  /// 返回 [DateTime] 对象
  static DateTime timestampMsToDateTime(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// 将秒级时间戳转换为日期字符串（YYYY-MM-DD）
  ///
  /// [timestamp] 秒级时间戳
  /// 返回格式化的日期字符串，如 "2025-01-15"
  static String timestampToDateString(int timestamp) {
    final dateTime = timestampToDateTime(timestamp);
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  /// 将秒级时间戳转换为相对时间格式
  ///
  /// [timestamp] 秒级时间戳
  /// 返回格式化的相对时间字符串：
  /// - 今天：返回 "今天"
  /// - 昨天：返回 "昨天"
  /// - 2-6天前：返回 "X天前"
  /// - 7天前（1周前）：返回 "1周前"
  /// - 超过7天：返回 "年-月-日" 格式，如 "2025-01-15"
  static String timestampToRelativeDateString(int timestamp) {
    final dateTime = timestampToDateTime(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final difference = today.difference(date).inDays;

    if (difference == 0) {
      return '今天';
    } else if (difference == 1) {
      return '昨天';
    } else if (difference < 7) {
      return '$difference天前';
    } else if (difference == 7) {
      return '1周前';
    } else {
      // 超过1周，返回年-月-日格式
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }

  /// 将 DateTime 转换为秒级时间戳
  ///
  /// [dateTime] DateTime 对象
  /// 返回秒级时间戳
  static int dateTimeToTimestamp(DateTime dateTime) {
    return dateTime.millisecondsSinceEpoch ~/ 1000;
  }

  /// 将 DateTime 转换为毫秒级时间戳
  ///
  /// [dateTime] DateTime 对象
  /// 返回毫秒级时间戳
  static int dateTimeToTimestampMs(DateTime dateTime) {
    return dateTime.millisecondsSinceEpoch;
  }

  /// 将秒级时间戳转换为本地时区的 DateTime
  ///
  /// [timestamp] 秒级时间戳
  /// 返回本地时区的 [DateTime] 对象
  static DateTime timestampToLocalDateTime(int timestamp) {
    return timestampToDateTime(timestamp).toLocal();
  }

  /// 将毫秒级时间戳转换为本地时区的 DateTime
  ///
  /// [timestamp] 毫秒级时间戳
  /// 返回本地时区的 [DateTime] 对象
  static DateTime timestampMsToLocalDateTime(int timestamp) {
    return timestampMsToDateTime(timestamp).toLocal();
  }
}
// AI-generated END - mp_timestamp_utils.dart
