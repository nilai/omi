// AI-generated START - Memo 任务卡片组件
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Memo 任务卡片组件
/// 显示任务信息，包含标题、描述、日期、标签和操作按钮
/// 支持左滑显示删除按钮，点击删除按钮后确认删除
class MemoTaskCard extends StatefulWidget {
  // AI-generated START - 任务ID（用于 Dismissible 的 key）
  final String id;
  // AI-generated END - id

  // AI-generated START - 任务标题
  final String title;
  // AI-generated END - title

  // AI-generated START - 任务描述
  final String description;
  // AI-generated END - description

  // AI-generated START - 任务日期（格式：YYYY-MM-DD）
  final String date;
  // AI-generated END - date

  // AI-generated START - 标签列表
  final List<String> tags;
  // AI-generated END - tags

  // AI-generated START - 点击回调
  final VoidCallback? onTap;
  // AI-generated END - onTap

  // AI-generated START - 删除回调
  final VoidCallback? onDelete;
  // AI-generated END - onDelete

  const MemoTaskCard({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.tags = const [],
    this.onTap,
    this.onDelete,
  });

  @override
  State<MemoTaskCard> createState() => _MemoTaskCardState();
}

class _MemoTaskCardState extends State<MemoTaskCard> with SingleTickerProviderStateMixin {
  // AI-generated START - 滑动偏移量
  double _dragOffset = 0.0;
  // AI-generated END - _dragOffset

  // AI-generated START - 动画控制器
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  // AI-generated END - _animationController

  // AI-generated START - 删除按钮宽度
  static const double _deleteButtonWidth = 80.0;
  // AI-generated END - _deleteButtonWidth

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // AI-generated START - 处理删除按钮点击
  Future<void> _handleDeleteClick() async {
    HapticFeedback.mediumImpact();
    // 执行删除
    widget.onDelete?.call();
  }
  // AI-generated END - _handleDeleteClick

  // AI-generated START - 处理水平拖拽更新
  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    // 只允许向左滑动（负值）
    final newOffset = (_dragOffset + details.delta.dx).clamp(-_deleteButtonWidth, 0.0);
    setState(() {
      _dragOffset = newOffset;
    });
  }
  // AI-generated END - _onHorizontalDragUpdate

  // AI-generated START - 处理水平拖拽结束
  void _onHorizontalDragEnd(DragEndDetails details) {
    const threshold = _deleteButtonWidth * 0.5; // 滑动超过一半宽度时保持显示

    if (_dragOffset.abs() > threshold) {
      // 滑动超过阈值，保持删除按钮显示
      _slideToDeletePosition();
    } else {
      // 滑动未超过阈值，恢复原位置
      _resetCardPosition();
    }
  }
  // AI-generated END - _onHorizontalDragEnd

  // AI-generated START - 滑动到删除位置
  void _slideToDeletePosition() {
    _slideAnimation = Tween<double>(begin: _dragOffset, end: -_deleteButtonWidth).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _dragOffset = -_deleteButtonWidth;
        });
      }
    });
  }
  // AI-generated END - _slideToDeletePosition

  // AI-generated START - 恢复卡片位置
  void _resetCardPosition() {
    _slideAnimation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _dragOffset = 0.0;
        });
      }
    });
  }
  // AI-generated END - _resetCardPosition

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // AI-generated START - 删除按钮背景
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(16.0),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: _handleDeleteClick,
              child: const Text(
                '删除',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        // AI-generated END - 删除按钮背景

        // AI-generated START - 可滑动的卡片
        AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            final offset = _animationController.isAnimating ? _slideAnimation.value : _dragOffset;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: GestureDetector(
                onHorizontalDragUpdate: _onHorizontalDragUpdate,
                onHorizontalDragEnd: _onHorizontalDragEnd,
                onTap: () {
                  // 如果卡片已滑动，点击时恢复位置；否则执行 onTap
                  if (_dragOffset < 0) {
                    _resetCardPosition();
                  } else {
                    widget.onTap?.call();
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 4.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // AI-generated START - 左侧内容区域
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // AI-generated START - 标题
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              // AI-generated END - 标题

                              const SizedBox(height: 8.0),

                              // AI-generated START - 描述
                              Text(
                                widget.description,
                                style: const TextStyle(
                                  color: Color(0xFF4B5563),
                                  fontSize: 12.0,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              // AI-generated END - 描述

                              const SizedBox(height: 12.0),

                              // AI-generated START - 日期和标签
                              Row(
                                children: [
                                  // 日期
                                  Text(
                                    widget.date,
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 12.0,
                                    ),
                                  ),
                                  // 过滤掉空字符串，只显示有效的标签
                                  if (widget.tags.where((tag) => tag.isNotEmpty).isNotEmpty) ...[
                                    const SizedBox(width: 12.0),
                                    // 标签
                                    ...widget.tags.where((tag) => tag.isNotEmpty).map((tag) => Padding(
                                          padding: const EdgeInsets.only(right: 6.0),
                                          child: Container(
                                            height: 20.0,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10.0,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(10.0),
                                            ),
                                            child: Text(
                                              tag,
                                              style: const TextStyle(
                                                color: Color(0xFF2563EB),
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        )),
                                  ],
                                ],
                              ),
                              // AI-generated END - 日期和标签
                            ],
                          ),
                        ),
                        // AI-generated END - 左侧内容区域

                        const SizedBox(width: 12.0),

                        // AI-generated START - 右侧操作按钮
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onTap?.call();
                          },
                          child: Image.asset(
                            'assets/images/mp_memo_edit.png',
                            width: 32.0,
                            height: 32.0,
                            fit: BoxFit.contain,
                          ),
                        ),
                        // AI-generated END - 右侧操作按钮
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        // AI-generated END - 可滑动的卡片
      ],
    );
  }
}
// AI-generated END - memo_task_card.dart
