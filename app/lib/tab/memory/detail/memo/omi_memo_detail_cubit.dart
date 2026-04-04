import 'package:omi/tab/memory/detail/memory/omi_memory_detail_cubit.dart';

/// Memo 详情 Cubit：与 [OmiMemoryDetailCubit] 相同（下拉刷新、加载更多、快捷 Todo/Memo 等），
/// 主内容映射使用根级 [MPMemoryStruct.summaryMemory]（见 [mpMemoryStructToMemoDetailBundle]）。
class OmiMemoDetailCubit extends OmiMemoryDetailCubit {
  OmiMemoDetailCubit({required super.memoryId})
      : super(detailSource: OmiMemoryDetailSource.rootSummaryMemory);
}
