/// 蓝牙扫描过滤与业务识别用的 Service UUID（自 `lib/blu/ble/devices_models.dart` 摘录，与主工程 Note GATT 一致）。
///
/// **勿修改** `lib/blu/ble/` 下的参考实现；本文件为 MemoPin 运行时使用的副本。
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// 首轮扫描 [withServices]：仅 aiNote 主服务（及可选附加），不再包含 Omi / Friend Pendant 等其它业务 UUID。
abstract class MPBleScanFilterUuids {
  /// MemoPin / aiNote 主服务（与 [MPNoteBleUUIDs.service] 同一值）。
  static const String aiNoteService = 'e2c1a300-7f4b-5e9d-bc23-1a2f3e4d5c6b';

  /// 固件若在广播里改用 **新的主服务 UUID**（与 [aiNoteService] 不同），在此追加完整 128-bit 字符串。
  ///
  /// 否则 OS 的 `withServices` 过滤与 [matchesMemoPinAdvertisedService] 都认不出设备；
  /// GATT 连接层若也已迁移，请同步修改 [MPNoteBleUUIDs.service] / [aiNoteService]。
  static const List<String> additionalMemoPinAdvertisementServices = <String>[];

  /// 用于识别 MemoPin 的广播服务 UUID（主服务 + 固件附加）。
  static List<String> get memoPinRecognizedServiceUuidStrings => <String>[
        aiNoteService,
        ...additionalMemoPinAdvertisementServices,
      ];

  /// 比较用规范化（去 `-`、小写）；避免插件 `str128` / `toString()` 与常量字面量格式不一致导致误判。
  static String normalizeUuid128(String raw) =>
      raw.toLowerCase().replaceAll('-', '');

  /// 广播中的 [AdvertisementData.serviceUuids] 是否命中 MemoPin 已知主服务列表。
  static bool matchesMemoPinAdvertisedService(Iterable<Guid> advertised) {
    final Set<String> targets =
        memoPinRecognizedServiceUuidStrings.map(normalizeUuid128).toSet();
    for (final Guid g in advertised) {
      if (targets.contains(normalizeUuid128(g.str128))) {
        debugPrint('------>>>memopin matchesMemoPinAdvertisedService: true (str128)');
        return true;
      }
      if (targets.contains(normalizeUuid128(g.toString()))) {
        debugPrint('------>>>memopin matchesMemoPinAdvertisedService: true (toString)');
        return true;
      }
    }
    debugPrint('------>>>memopin matchesMemoPinAdvertisedService: false');
    return false;
  }

  /// 供 [FlutterBluePlus.startScan] / [BluetoothAdapter.startScan] 的 `withServices`。
  ///
  /// 仅 [memoPinRecognizedServiceUuidStrings]（aiNote + [additionalMemoPinAdvertisementServices]），去重。
  static List<Guid> get scanFilterGuids {
    final List<Guid> out = <Guid>[];
    final Set<String> seen = <String>{};
    for (final String s in memoPinRecognizedServiceUuidStrings) {
      final String k = normalizeUuid128(s);
      if (seen.add(k)) {
        out.add(Guid(s));
      }
    }
    debugPrint('------>>>memopin scanFilterGuids: count=${out.length}');
    return out;
  }
}
