import 'package:flutter/foundation.dart';

/// MemoPin BLE 模块统一调试日志前缀。
const String kMemopinDebugLogPrefix = '------>>>memopin';

/// 输出带 [kMemopinDebugLogPrefix] 前缀的调试日志；同一逻辑分支只调用一次。
void mpMemopinDebugPrint(String message) {
  debugPrint('$kMemopinDebugLogPrefix $message');
}
