import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      color: Colors.white,
      child: Text(
        hintText,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF666666),
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
        child: CircularProgressIndicator(),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
    final buttonText = selectedCount == 0 ? '请选择要合并的记忆' : '开始合并(${selectedCount + 1}个记忆)';
    final isEnabled = selectedCount > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: isEnabled ? () => _handleMerge(provider) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEnabled ? const Color(0xFF306CFF) : const Color(0xFFE5E5E5),
            foregroundColor: isEnabled ? Colors.white : const Color(0xFF999999),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: Text(
            buttonText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// 处理合并操作
  /// @param provider Provider实例
  void _handleMerge(MPMergeMemoryProvider provider) {
    // TODO: 实现合并逻辑
    debugPrint('开始合并记忆，选中数量: ${provider.selectedCount}');
    // 这里可以调用合并接口，然后返回上一页
    Navigator.of(context).pop();
  }
}
