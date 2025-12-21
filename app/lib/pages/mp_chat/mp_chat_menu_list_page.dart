import 'package:flutter/material.dart';
import 'package:omi/pages/mp_custom_utils/mp_toast_utils.dart';
import 'package:provider/provider.dart';

import 'mp_chat_people_memory_page.dart';
import 'providers/mp_chat_menu_list_provider.dart';

/// 聊天菜单列表页面
/// 从屏幕右侧滑入的dialog
class MPChatMenuListPage extends StatefulWidget {
  const MPChatMenuListPage({super.key});

  /// 显示菜单dialog的静态方法
  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => const MPChatMenuListPage(),
    );
  }

  @override
  State<MPChatMenuListPage> createState() => _MPChatMenuListPageState();
}

class _MPChatMenuListPageState extends State<MPChatMenuListPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // 从右侧开始
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // 启动动画
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeDialog() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MPChatMenuListProvider(),
      child: GestureDetector(
        onTap: () => _closeDialog(),
        child: Container(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {}, // 阻止点击事件冒泡
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      constraints: const BoxConstraints(maxWidth: 400),
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 24,
                            offset: const Offset(-6, 0),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 40,
                            offset: const Offset(-12, 0),
                          ),
                        ],
                      ),
                      child: const _MenuContent(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 菜单内容
class _MenuContent extends StatelessWidget {
  const _MenuContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部bar
        _buildTopBar(context),
        // 搜索框
        _buildSearchBox(context),
        // 常驻固定item
        _buildFixedItems(context),
        // 动态item列表
        Expanded(
          child: _buildRecentConversations(context),
        ),
      ],
    );
  }

  /// 构建顶部bar
  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          const Text(
            'MemoAI',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.close,
                size: 20,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建搜索框
  Widget _buildSearchBox(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          MPToastUtils.showFeatureComingSoon();
        },
        child: Row(
          children: [
            Icon(
              Icons.search,
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Text(
              '搜索...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建常驻固定item
  Widget _buildFixedItems(BuildContext context) {
    return Column(
      children: [
        _buildMenuItem(
          context,
          icon: Icons.chat_bubble_outline,
          iconColor: Colors.lightBlue,
          title: 'New Chat',
          onTap: () {
            Navigator.of(context).pop();
            // TODO: 处理新建聊天
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.lightbulb_outline,
          iconColor: Colors.purple,
          title: 'Daily insight',
          onTap: () {
            Navigator.of(context).pop();
            // TODO: 处理每日洞察
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.people_outline,
          iconColor: Colors.green,
          title: 'People Memory',
          trailing: Icon(
            Icons.chevron_right,
            size: 20,
            color: Colors.grey[400],
          ),
          onTap: () {
            Navigator.of(context).pop();
            MPChatPeopleMemoryPage.show(context);
          },
        ),
      ],
    );
  }

  /// 构建菜单项
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  /// 构建最近对话列表
  Widget _buildRecentConversations(BuildContext context) {
    return Consumer<MPChatMenuListProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (provider.recentConversations.isEmpty) {
          return const Center(
            child: Text(
              '暂无最近对话',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9CA3AF),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                '最近对话',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: provider.recentConversations.length,
                itemBuilder: (context, index) {
                  final item = provider.recentConversations[index];
                  return _buildConversationItem(context, item);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建对话项
  Widget _buildConversationItem(
    BuildContext context,
    MPChatMenuItem item,
  ) {
    return GestureDetector(
      onTap: item.onTap ??
          () {
            Navigator.of(context).pop();
            // TODO: 处理对话点击
          },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // 图标
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (item.iconColor ?? Colors.grey).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: item.icon != null
                  ? Icon(
                      item.icon,
                      size: 18,
                      color: item.iconColor ?? Colors.grey,
                    )
                  : item.iconUrl != null
                      ? ClipOval(
                          child: Image.network(
                            item.iconUrl!,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.chat_bubble_outline,
                                size: 18,
                                color: Colors.grey[400],
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.chat_bubble_outline,
                          size: 18,
                          color: Colors.grey[400],
                        ),
            ),
            const SizedBox(width: 12),
            // 标题
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1F2937),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
