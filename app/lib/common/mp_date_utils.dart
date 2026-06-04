import 'package:intl/intl.dart';
import 'package:memo_pin/utils/mp_time_utils.dart';

/// Unix 时间戳与 Todo 截止时间展示文案。
class MPDateUtils {
  MPDateUtils._();

  /// 服务端 `deadline` 为 `null`、空或 `0` 时视为无截止时间。
  static int? normalizeTodoDeadline(int? raw) =>
      MPTimeUtils.normalizeUnixTimestamp(raw);

  /// 接口 `show_time`（如 `2026-05-11 02:00:00`）→ UTC Unix 秒；解析失败为 `null`。
  static int? unixSecondsFromShowTime(String? showTime) {
    final String raw = (showTime ?? '').trim();
    if (raw.isEmpty) {
      return null;
    }
    const List<String> patterns = <String>[
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-dd HH:mm',
    ];
    for (final String pattern in patterns) {
      try {
        final DateTime dt = DateFormat(pattern).parseUtc(raw);
        return dt.millisecondsSinceEpoch ~/ 1000;
      } catch (_) {
        // try next pattern
      }
    }
    return null;
  }

  /// 优先解析 [showTime]；失败时使用 [fallbackUnix]（秒或毫秒）。
  static int? resolveTimestampFromShowTime(String? showTime, {int? fallbackUnix}) {
    return unixSecondsFromShowTime(showTime) ??
        MPTimeUtils.normalizeUnixTimestamp(fallbackUnix);
  }

  /// 与 All 列表 [MPMemoryCard] 主标题一致：根级 `title`（trim 后）。
  static String memoryListTitle(String? title) => (title ?? '').trim();

  /// 与 All 列表 [MPAudioRecordingCard] 主/副标题规则一致。
  static ({String primary, String secondary}) resolveAudioRecordingLabels({
    required String? title,
    required String? content,
    required String? showTime,
    required int? createAt,
  }) {
    final String titleTrim = memoryListTitle(title);
    final String contentTrim = (content ?? '').trim();
    if (titleTrim.isEmpty && contentTrim.isEmpty) {
      return (
        primary: formatMemoryShortTimeFromShowTime(showTime, fallbackCreateAt: createAt),
        secondary: formatMemoryLongTimeFromShowTime(showTime, fallbackCreateAt: createAt),
      );
    }
    return (primary: title ?? '', secondary: content ?? '');
  }

  /// 详情导航栏标题：与列表卡片一致，无 title 时用 [formatMemoryShortTimeFromShowTime] 兜底。
  static String resolveMemoryDetailNavTitle({
    required String? title,
    String? showTime,
    int? fallbackCreateAt,
    String emptyFallback = '',
  }) {
    final String trimmed = memoryListTitle(title);
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    final String timeLabel =
        formatMemoryShortTimeFromShowTime(showTime, fallbackCreateAt: fallbackCreateAt);
    if (timeLabel.isNotEmpty) {
      return timeLabel;
    }
    return emptyFallback;
  }

  /// 与 All 列表录音卡片时长格式一致（如 `3m47s`）。
  static String formatMemoryDurationCompact(int? seconds) {
    final int s = seconds ?? 0;
    if (s <= 0) {
      return '0s';
    }
    final int m = s ~/ 60;
    final int sec = s % 60;
    if (m > 0) {
      return '${m}m${sec}s';
    }
    return '${sec}s';
  }

  /// Todo 列表：由 `show_time` 解析后走 [MPTimeUtils.formatTodoDeadlineLabel]。
  static String formatTodoDisplayFromShowTime(String? showTime, {int? fallbackDeadlineUnix}) {
    return MPTimeUtils.formatTodoDeadlineLabel(
      resolveTimestampFromShowTime(showTime, fallbackUnix: fallbackDeadlineUnix),
    );
  }

  /// Memory 列表相对时间：由 `show_time` 解析后走 [formatRelativeTimeAgo]。
  static String formatMemoryRelativeFromShowTime(String? showTime, {int? fallbackCreateAt}) {
    return formatRelativeTimeAgo(
      resolveTimestampFromShowTime(showTime, fallbackUnix: fallbackCreateAt),
    );
  }

  /// Memory 列表短格式：`MMM d, y, h:mm a`。
  static String formatMemoryShortTimeFromShowTime(String? showTime, {int? fallbackCreateAt}) {
    final DateTime? dt = dateTimeFromUnixEpoch(
      resolveTimestampFromShowTime(showTime, fallbackUnix: fallbackCreateAt),
    );
    if (dt == null) {
      return '';
    }
    return DateFormat('MMM d, y, h:mm a').format(dt);
  }

  /// 录音卡片副行：`MMMM d, y · h:mm a`。
  static String formatMemoryLongTimeFromShowTime(String? showTime, {int? fallbackCreateAt}) {
    final DateTime? dt = dateTimeFromUnixEpoch(
      resolveTimestampFromShowTime(showTime, fallbackUnix: fallbackCreateAt),
    );
    if (dt == null) {
      return '';
    }
    return DateFormat('MMMM d, y · h:mm a').format(dt);
  }

  /// Memory / Memo 详情 meta 时间片段：`MMM d, y, h:mm a`。
  static String formatMemoryDetailMetaTimeFromShowTime(String? showTime, {int? fallbackCreateAt}) {
    final DateTime? dt = dateTimeFromUnixEpoch(
      resolveTimestampFromShowTime(showTime, fallbackUnix: fallbackCreateAt),
    );
    if (dt == null) {
      return '';
    }
    return DateFormat('MMM d, y, h:mm a').format(dt);
  }

  /// Feed 卡片时间：`MMM d, h:mm a`；无有效时间戳时为 [emptyFallback]。
  static String formatFeedCardTimeFromShowTime(
    String? showTime, {
    int? fallbackCreateAt,
    String emptyFallback = ' ',
  }) {
    final DateTime? dt = dateTimeFromUnixEpoch(
      resolveTimestampFromShowTime(showTime, fallbackUnix: fallbackCreateAt),
    );
    if (dt == null) {
      return emptyFallback;
    }
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  /// 秒或毫秒时间戳转 UTC [DateTime]；`raw > 1e10` 视为毫秒。
  static DateTime? dateTimeFromUnixEpoch(int? raw) =>
      MPTimeUtils.dateTimeFromUnixEpoch(raw);

  /// 日期部分：当天为 `Today`，否则为 `MMM d, y`；无截止时间为 `No deadline`。
  static String formatWhenLabelFromDeadline(int? deadline) {
    final DateTime? dt = dateTimeFromUnixEpoch(deadline);
    if (dt == null) {
      return 'No deadline';
    }
    final DateTime today = MPTimeUtils.startOfTodayInTimeZone();
    final DateTime day = DateTime.utc(dt.year, dt.month, dt.day);
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
    final DateTime today = MPTimeUtils.startOfTodayInTimeZone();
    final DateTime day = DateTime.utc(dt.year, dt.month, dt.day);
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
    final DateTime now = MPTimeUtils.nowInTimeZone();
    final DateTime todayStart = MPTimeUtils.startOfTodayInTimeZone();
    final DateTime eventDay = DateTime.utc(dt.year, dt.month, dt.day);
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

  /// Memory 卡片副标题时间：`Today, h:mm a`；非当天为 `MMM d, y, h:mm a`。
  static String formatMemoryRecordContextTime(int? raw) {
    if (raw == null || raw <= 0) {
      return '';
    }
    final DateTime? dt = dateTimeFromUnixEpoch(raw);
    if (dt == null) {
      return '';
    }
    final DateTime today = MPTimeUtils.startOfTodayInTimeZone();
    final DateTime day = DateTime.utc(dt.year, dt.month, dt.day);
    final String timePart = DateFormat('h:mm a').format(dt);
    if (day == today) {
      return 'Today, $timePart';
    }
    return '${DateFormat('MMM d, y').format(dt)}, $timePart';
  }

  /// 时长（秒）展示为 `12m34s`、`12m`、`34s`。
  static String formatDurationCompactMinutesSeconds(int totalSeconds) {
    final int s = totalSeconds.clamp(0, 86400 * 365);
    final int m = s ~/ 60;
    final int sec = s % 60;
    if (m > 0 && sec > 0) {
      return '${m}m${sec}s';
    }
    if (m > 0) {
      return '${m}m';
    }
    return '${sec}s';
  }

  /// Memory 简要信息 meta：`时间 · 时长 · label`（无时间戳则不展示时间段；[label] 空则省略）。
  static String buildMemorySimpleContextMetaLine({
    required int? recordCreateAt,
    required int duration,
    String? label,
  }) {
    final List<String> parts = <String>[];
    final String timePart = formatMemoryRecordContextTime(recordCreateAt);
    if (timePart.isNotEmpty) {
      parts.add(timePart);
    }
    parts.add(formatDurationCompactMinutesSeconds(duration));
    final String? trimmedLabel = label?.trim();
    if (trimmedLabel != null && trimmedLabel.isNotEmpty) {
      parts.add(trimmedLabel);
    }
    return parts.join(' · ');
  }
}
