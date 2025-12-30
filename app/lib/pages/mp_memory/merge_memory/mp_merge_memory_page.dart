import 'package:flutter/material.dart';
import 'package:growthbook_sdk_flutter/growthbook_sdk_flutter.dart';
import 'package:omi/pages/mp_custom_utils/mp_toast_utils.dart';
import 'package:provider/provider.dart';

import '../../../backend/http/mp_api/mp_memory.dart';
import '../../../backend/schema/mp/mp_memory.dart';
import '../../../pages/mp_newsetting/home/widgets/mp_common_app_bar.dart';
import 'providers/mp_merge_memory_provider.dart';
import 'widgets/mp_merge_memory_item.dart';

/// 合并记忆页面
/// 用于选择要合并的记忆记录
class MPMergeMemoryPage extends StatefulWidget {
  /// 当前记忆ID（要合并到的目标记忆）
  final String currentMemoryId;

  /// 合并成功回调
  final VoidCallback? onMergeSuccess;

  /// 构造函数
  /// @param currentMemoryId 当前记忆ID
  const MPMergeMemoryPage({
    super.key,
    required this.currentMemoryId,
    this.onMergeSuccess,
  });

  @override
  State<MPMergeMemoryPage> createState() => _MPMergeMemoryPageState();

  static void pushPage({required BuildContext context, required String memoryId, VoidCallback? onSuccess}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => MPMergeMemoryProvider(currentMemoryId: memoryId),
          child: MPMergeMemoryPage(
            currentMemoryId: memoryId,
            onMergeSuccess: onSuccess,
          ),
        ),
      ),
    );
  }
}

class _MPMergeMemoryPageState extends State<MPMergeMemoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<MPMergeMemoryProvider>();
        provider.refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const MPCommonAppBar(
        title: '追加总结',
        showBackButton: true,
        backgroundColor: Colors.white,
      ),
      body: Consumer<MPMergeMemoryProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // 顶部提示区域
              _buildTopHint(provider),
              // 列表区域
              Expanded(
                child: _buildList(provider),
              ),
              // 底部按钮
              _buildBottomButton(provider),
            ],
          );
        },
      ),
    );
  }

  /// 构建顶部提示区域
  /// @param provider Provider实例
  /// @returns 顶部提示Widget
  Widget _buildTopHint(MPMergeMemoryProvider provider) {
    final selectedCount = provider.selectedCount;
    final hintText = selectedCount == 0 ? '选择要合并的记忆记录' : '已选择$selectedCount个记忆，将与当前记忆合并';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: selectedCount > 0 ? Color(0xFF306CFF).withOpacity(0.1) : Colors.white,
      child: Text(
        hintText,
        style: TextStyle(
          fontSize: 14,
          color: selectedCount > 0 ? Color(0xFF306CFF) : Color(0xFF666666),
        ),
      ),
    );
  }

  /// 构建列表
  /// @param provider Provider实例
  /// @returns 列表Widget
  Widget _buildList(MPMergeMemoryProvider provider) {
    if (provider.loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF306CFF),
        ),
      );
    }

    if (provider.items.isEmpty) {
      return const Center(
        child: Text(
          '暂无记忆记录',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF999999),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: provider.items.length,
      itemBuilder: (context, index) {
        final item = provider.items[index];
        final isSelected = provider.isSelected(item.memory.id);

        return MPMergeMemoryItem(
          item: item,
          isSelected: isSelected,
          onTap: () {
            provider.toggleSelection(item.memory.id);
          },
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
    );
  }

  /// 构建底部按钮
  /// @param provider Provider实例
  /// @returns 底部按钮Widget
  Widget _buildBottomButton(MPMergeMemoryProvider provider) {
    final selectedCount = provider.selectedCount;
    final buttonText = selectedCount == 0 ? '请选择要合并的记忆' : '开始合并($selectedCount个记忆)';
    final isEnabled = selectedCount > 0;

    return GestureDetector(
      onTap: isEnabled ? () => _handleMerge(provider) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isEnabled ? const Color(0xFF306CFF) : const Color(0xFFE5E5E5),
          borderRadius: BorderRadius.circular(8),
        ),
        width: double.infinity,
        height: 48,
        child: Center(
          child: Text(
            buttonText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isEnabled ? Colors.white : const Color(0xFF999999),
            ),
          ),
        ),
      ),
    );
  }

  /// 处理合并操作
  /// @param provider Provider实例
  void _handleMerge(MPMergeMemoryProvider provider) async {
    List<String> ids = [widget.currentMemoryId];
    ids.addAll(provider.selectedMemoryIds.toList());
    final req = MPAppendMemoryRequest(memoryIds: ids);
    final response = await appendMemory(req);
    if (response != null && response.baseResp.code == 0) {
      widget.onMergeSuccess?.call();
      Navigator.of(context).pop();
    } else {
      final message = response?.baseResp.message ?? '合并失败';
      MPToastUtils.showMessage(message);
    }
  }
}
