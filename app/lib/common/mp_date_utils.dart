import 'package:intl/intl.dart';

/// Unix 时间戳与 Todo 截止时间展示文案。
class MPDateUtils {
  MPDateUtils._();

  /// 秒或毫秒时间戳转本地 [DateTime]；`raw > 1e10` 视为毫秒。
  static DateTime? dateTimeFromUnixEpoch(int? raw) {
    if (raw == null) {
      return null;
    }
    return raw > 10000000000
        ? DateTime.fromMillisecondsSinceEpoch(raw)
        : DateTime.fromMillisecondsSinceEpoch(raw * 1000);
  }

  /// 日期部分：当天为 `Today`，否则为 `MMM d, y`；无截止时间为 `No deadline`。
  static String formatWhenLabelFromDeadline(int? deadline) {
    final DateTime? dt = dateTimeFromUnixEpoch(deadline);
    if (dt == null) {
      return 'No deadline';
    }
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(dt.year, dt.month, dt.day);
    if (day == today) {
      return 'Today';
    }
    return DateFormat('MMM d, y').format(dt);
  }

  /// `HH:mm:ss`；无截止时间时为 `--:--:--`。
  static String formatTimeLabelFromDeadline(int? deadline) {
    final DateTime? dt = dateTimeFromUnixEpoch(deadline);
    if (dt == null) {
      return '--:--:--';
    }
    return DateFormat('HH:mm:ss').format(dt);
  }

  /// 列表一行：`Today · HH:mm:ss` 或 `MMM d, y · HH:mm:ss`；无截止为 `No deadline`。
  static String deadlineLineText(int? deadline) {
    final DateTime? dt = dateTimeFromUnixEpoch(deadline);
    if (dt == null) {
      return 'No deadline';
    }
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(dt.year, dt.month, dt.day);
    final String when =
        day == today ? 'Today' : DateFormat('MMM d, y').format(dt);
    final String time = DateFormat('HH:mm:ss').format(dt);
    return '$when · $time';
  }

  static String formatDeadlineLineText(int? deadline) {
    final DateTime? dt = dateTimeFromUnixEpoch(deadline);
    if (dt == null) {
      return '';
    }
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  /// 相对过去时间（英文）：同一天为 `Xm ago` / `Xh ago`，上一日历日为 `Yesterday`，
  /// 2–6 日前为 `Xd ago`，满 7 日及以上为 `weekly`。
  static String formatRelativeTimeAgo(int? raw) {
    final DateTime? dt = dateTimeFromUnixEpoch(raw);
    if (dt == null) {
      return '';
    }
    final DateTime now = DateTime.now();
    final DateTime todayStart = DateTime(now.year, now.month, now.day);
    final DateTime eventDay = DateTime(dt.year, dt.month, dt.day);
    final int diffDays = todayStart.difference(eventDay).inDays;
    if (diffDays < 0) {
      return '';
    }
    if (diffDays >= 7) {
      return 'weekly';
    }
    if (diffDays >= 2) {
      return '${diffDays}d ago';
    }
    if (diffDays == 1) {
      return 'Yesterday';
    }
    final Duration diff = now.difference(dt);
    if (diff.isNegative) {
      return '';
    }
    if (diff.inSeconds < 60) {
      return 'Just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    return '${diff.inHours}h ago';
  }

  /// 展示为 `MM:SS`（分、秒各至少两位）。
  static String formatTranscriptSecondsToMmSs(int seconds) {
    final int s = seconds.clamp(0, 86400);
    final int m = s ~/ 60;
    final int sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}
