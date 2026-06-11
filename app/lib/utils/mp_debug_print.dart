import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// 全局 [debugPrint] 重写：输出时自动带上本地时:分:秒.毫秒前缀。
class MPDebugPrint {
  MPDebugPrint._();

  static final DateFormat _timeFormat = DateFormat('HH:mm:ss.SSS');

  /// 在 [main] 启动最早阶段调用，重写 [debugPrint]。
  static void setup() {
    final DebugPrintCallback original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      final String prefix = _timeFormat.format(DateTime.now());
      original('$prefix $message', wrapWidth: wrapWidth);
    };
  }
}
