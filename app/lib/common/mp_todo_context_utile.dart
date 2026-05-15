import 'package:flutter/foundation.dart';
import 'package:memo_pin/tab/home/insights/mp_insights_list_cubit.dart';

import '../cache/mp_hive_util.dart';
import '../http/api/mp_insight.dart';
import '../http/api/mp_memory.dart';
import '../http/schema/mp_data_model.dart';
import '../http/schema/mp_insight.dart';
import '../http/schema/mp_memory.dart';
import 'mp_date_utils.dart';

/// Todo 弹层 CONTEXT 区块：与 [OmiEditTodoPopupParams] 中 `contextMemory*` / [OmiEditTodoPopupParams.memoryType] 语义对齐。
class MPTodoContextStruct {
  /// [label]：如 `From memory:` / `From insight:`；[title]：主标题；[metaLine]：时间 · 标签等副行。
  const MPTodoContextStruct({
    required this.label,
    required this.title,
    required this.metaLine,
    this.memoryType,
    this.insightType,
  });

  /// 如 `From memory:` / `From insight:`。
  final String label;

  /// 主标题（Memory / Insight 标题）。
  final String title;

  /// 副行：时间 · 时长 · label 等。
  final String metaLine;

  /// 关联 Memory 类型（来自 [MPMemorySimpleInfoStruct.type] 或 Insight 简易详情 `type` 映射）；无关联或未识别时为 `null`。
  final MPMemoryType? memoryType;

  /// 关联 Insight 类型（来自 [MPInsightCardStruct.type]）；无关联或未识别时为 `null`。
  final MPInsightCardType? insightType;

  /// 无关联上下文时的占位。
  static const MPTodoContextStruct empty = MPTodoContextStruct(
    label: '',
    title: '',
    metaLine: '',
    memoryType: null,
    insightType: null,
  );

  /// [label]、[title]、[metaLine] 去空白后是否均可视为空。
  bool get isEffectivelyEmpty =>
      label.trim().isEmpty && title.trim().isEmpty && metaLine.trim().isEmpty;
}

/// Hive：`memory_id` → [MPGetMemoryV2SimpleInfoResponse] JSON（与 [MPHomeCubit] / Insight 详情共用）。
String _memorySimpleInfoHiveKey(int memoryId) => 'mp_insight_memory_simple_info_v1_$memoryId';

/// Hive：`todo_id` → [MPGetInsightSimpleDetailResponse] JSON。
String _insightSimpleDetailHiveKey(String todoId) => 'mp_insight_simple_detail_v1_$todoId';

/// Todo CONTEXT 拉取与组装（网络 + Hive 兜底）。
abstract final class MPTodoContextUtile {
  MPTodoContextUtile._();

  /// 根据 [memoryId]（非 `null` 且非 `0`）或 [insightId]（非空白，作为接口 `todo_id`）获取 Todo CONTEXT。
  ///
  /// - `memoryId` 为 `null` 或 `0` **且** [insightId] 去空白为空 → [MPTodoContextStruct.empty]。
  /// - `memoryId` 非 `null` 且非 `0` → 仅 [_todoContextFromMemorySimple]。
  /// - 否则 [insightId] 非空 → [_todoContextFromInsightSimple]（`get_simple_detail` 的 `todo_id`）。
  static Future<MPTodoContextStruct> getTodoContext({
    int? memoryId,
    String? insightId,
  }) async {
    final String insightTrim = (insightId ?? '').trim();
    final bool memInvalid = memoryId == null || memoryId == 0;
    final bool insightInvalid = insightTrim.isEmpty || insightTrim == '0';
    if (memInvalid && insightInvalid) {
      return MPTodoContextStruct.empty;
    }
    if (!memInvalid) {
      return _todoContextFromMemorySimple(memoryId);
    }
    return _todoContextFromInsightSimple(insightTrim);
  }

  /// Memory 简要信息：网络成功写 Hive；失败读 Hive（与首页 / Insight 详情共用 Hive key）。
  static Future<MPGetMemoryV2SimpleInfoResponse?> _loadMemorySimpleInfoNetworkOrHive(int memoryId) async {
    final String idStr = '$memoryId';
    try {
      final MPGetMemoryV2SimpleInfoResponse? net =
          await getMemoryV2SimpleInfo(MPGetMemoryV2SimpleInfoRequest(memoryId: idStr));
      if (net != null && net.baseResp?.code == 0) {
        await MPHiveUtil.instance.putMap(key: _memorySimpleInfoHiveKey(memoryId), value: net.toJson());
        return net;
      }
    } catch (e, stackTrace) {
      debugPrint('MPTodoContextUtile: memory simple network failed — $e\n$stackTrace');
    }
    try {
      final Map<String, dynamic>? cached =
          await MPHiveUtil.instance.getMap(_memorySimpleInfoHiveKey(memoryId));
      if (cached == null || cached.isEmpty) {
        return null;
      }
      final MPGetMemoryV2SimpleInfoResponse restored = MPGetMemoryV2SimpleInfoResponse.fromJson(cached);
      if (restored.baseResp?.code == 0) {
        return restored;
      }
    } catch (e, stackTrace) {
      debugPrint('MPTodoContextUtile: memory simple hive read failed — $e\n$stackTrace');
    }
    return null;
  }

  /// [memoryId] 已判定非 `0`。
  static Future<MPTodoContextStruct> _todoContextFromMemorySimple(int memoryId) async {
    final MPGetMemoryV2SimpleInfoResponse? resp = await _loadMemorySimpleInfoNetworkOrHive(memoryId);
    final MPMemorySimpleInfoStruct? mi =
        (resp != null && resp.baseResp?.code == 0) ? resp.memoryInfo : null;
    if (mi == null) {
      return MPTodoContextStruct.empty;
    }
    return MPTodoContextStruct(
      label: 'From memory:',
      title: mi.title.trim(),
      metaLine: MPDateUtils.buildMemorySimpleContextMetaLine(
        recordCreateAt: mi.recordCreateAt,
        duration: mi.duration,
        label: mi.label,
      ),
      memoryType: mi.type,
      insightType: null,
    );
  }

  /// Insight 简易详情：网络成功写 Hive；失败读 Hive。请求参数为后端 `todo_id`（入参 [todoId]）。
  static Future<MPGetInsightSimpleDetailResponse?> _loadInsightSimpleDetailNetworkOrHive(String todoId) async {
    try {
      final MPGetInsightSimpleDetailResponse? net = await getInsightSimpleDetail(
        MPGetInsightSimpleDetailRequest(todoId: todoId),
      );
      if (net != null && net.baseResp.code == 0) {
        await MPHiveUtil.instance.putMap(key: _insightSimpleDetailHiveKey(todoId), value: net.toJson());
        return net;
      }
    } catch (e, stackTrace) {
      debugPrint('MPTodoContextUtile: insight simple network failed — $e\n$stackTrace');
    }
    try {
      final Map<String, dynamic>? cached =
          await MPHiveUtil.instance.getMap(_insightSimpleDetailHiveKey(todoId));
      if (cached == null || cached.isEmpty) {
        return null;
      }
      final MPGetInsightSimpleDetailResponse restored = MPGetInsightSimpleDetailResponse.fromJson(cached);
      if (restored.baseResp.code == 0) {
        return restored;
      }
    } catch (e, stackTrace) {
      debugPrint('MPTodoContextUtile: insight simple hive read failed — $e\n$stackTrace');
    }
    return null;
  }

  static MPTodoContextStruct _mapInsightSimpleToContext(MPGetInsightSimpleDetailResponse r) {
    final List<String> parts = <String>[];
    final String timePart = MPDateUtils.formatMemoryRecordContextTime(r.recordCreateAt);
    if (timePart.isNotEmpty) {
      parts.add(timePart);
    }
    final String lab = r.label.trim();
    if (lab.isNotEmpty) {
      parts.add(lab);
    }
    final MPInsightCardType? insightCardType = _insightCardTypeFromCycleTypeInt(r.type);
    final MPMemoryType? memoryType =
        insightCardType != null ? null : _memoryTypeFromInsightSimpleTypeCode(r.type);
    return MPTodoContextStruct(
      label: 'From insight:',
      title: r.title.trim(),
      metaLine: parts.join(' · '),
      memoryType: memoryType,
      insightType: insightCardType,
    );
  }

  /// 将 [MPGetInsightSimpleDetailResponse.type] 在 [MPInsightCycleType.daily]～[MPInsightCycleType.pattern] 时映射为 [MPInsightCardType]。
  static MPInsightCardType? _insightCardTypeFromCycleTypeInt(int type) {
    switch (type) {
      case MPInsightCycleType.daily:
        return MPInsightCardType.daily;
      case MPInsightCycleType.weekly:
        return MPInsightCardType.weekly;
      case MPInsightCycleType.monthly:
        return MPInsightCardType.monthly;
      case MPInsightCycleType.pattern:
        return MPInsightCardType.pattern;
      default:
        return null;
    }
  }

  /// 将 [MPGetInsightSimpleDetailResponse.type]（与 [MPMemoryType] 的 Thrift 取值对齐时）映射为枚举。
  static MPMemoryType? _memoryTypeFromInsightSimpleTypeCode(int type) {
    switch (type) {
      case 1:
        return MPMemoryType.summary;
      case 2:
        return MPMemoryType.onlyRecord;
      case 5:
        return MPMemoryType.memoryFeed;
      case 6:
        return MPMemoryType.memoList;
      default:
        return null;
    }
  }

  /// [todoId] 已 trim 非空；对应 [getInsightSimpleDetail] 的 `todo_id`。
  static Future<MPTodoContextStruct> _todoContextFromInsightSimple(String todoId) async {
    final MPGetInsightSimpleDetailResponse? resp = await _loadInsightSimpleDetailNetworkOrHive(todoId);
    if (resp == null || resp.baseResp.code != 0) {
      return MPTodoContextStruct.empty;
    }
    return _mapInsightSimpleToContext(resp);
  }
}
