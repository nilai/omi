import 'package:intl/intl.dart';
import 'package:memo_pin/common/mp_date_utils.dart';

/// Todo 截止时间等时间展示文案。
class MPTimeUtils {
  MPTimeUtils._();

  /// [deadlineSec] 为 Unix 秒；`null` / `0` 展示为 `No deadline`。
  ///
  /// 当天仅 `HH:mm`；未来 7 日内为 `EEE HH:mm`；更远为 `MMM d`。
  static String formatTodoDeadlineLabel(int? deadlineSec) {
    final DateTime? dt = MPDateUtils.dateTimeFromUnixEpoch(deadlineSec);
    if (dt == null) {
      return 'No deadline';
    }
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
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
}
