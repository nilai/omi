// AI-generated START - Todo 任务卡片组件
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Todo 任务卡片组件
/// 显示任务信息，包含标题、描述、日期、标签和操作按钮
/// 支持左滑显示完成按钮，点击完成按钮后执行完成操作
class TodoTaskCard extends StatefulWidget {
  // AI-generated START - 任务ID（用于 Dismissible 的 key）
  final String id;
  // AI-generated END - id

  // AI-generated START - 任务标题
  final String title;
  // AI-generated END - title

  // AI-generated START - 任务描述
  final String description;
  // AI-generated END - description

  // AI-generated START - 任务日期（格式：YYYY-MM-DD 或 Dec 16）
  final String date;
  // AI-generated END - date

  // AI-generated START - 优先级标签（如：High, Normal, Low）
  final String? priorityTag;
  // AI-generated END - priorityTag

  // AI-generated START - 任务状态（1-进行中，0-已删除，2-已完成, 3-已超期）
  final int? status;
  // AI-generated END - status

  // AI-generated START - 点击回调
  final VoidCallback? onTap;
  // AI-generated END - onTap

  // AI-generated START - 完成回调
  final VoidCallback? onComplete;
  // AI-generated END - onComplete

  // AI-generated START - 删除回调
  final VoidCallback? onDelete;
  // AI-generated END - onDelete

  const TodoTaskCard({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.status,
    this.priorityTag,
    this.onTap,
    this.onComplete,
    this.onDelete,
  });

  @override
  State<TodoTaskCard> createState() => _TodoTaskCardState();
}

class _TodoTaskCardState extends State<TodoTaskCard> with SingleTickerProviderStateMixin {
  // AI-generated START - 滑动偏移量
  double _dragOffset = 0.0;
  // AI-generated END - _dragOffset

  // AI-generated START - 动画控制器
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  // AI-generated END - _animationController

  // AI-generated START - 完成按钮宽度
  static const double _completeButtonWidth = 80.0;
  // AI-generated END - _completeButtonWidth

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

  // AI-generated START - 获取优先级标签颜色
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'normal':
        return Colors.orange;
      case 'low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
  // AI-generated END - _getPriorityColor

  // AI-generated START - 根据状态获取操作文案
  String _getActionText() {
    // 任务状态：1-进行中，0-已删除，2-已完成, 3-已超期
    switch (widget.status) {
      case 1: // 进行中
        return '完成';
      case 2: // 已完成
        return '删除';
      case 3: // 已超期
        return '删除';
      default: // 默认或未知状态
        return '完成';
    }
  }
  // AI-generated END - _getActionText

  // AI-generated START - 处理完成按钮点击
  void _handleCompleteClick() {
    HapticFeedback.mediumImpact();
    // 执行完成或删除
    if (widget.status == 1) {
      widget.onComplete?.call();
    } else {
      widget.onDelete?.call();
    }
  }
  // AI-generated END - _handleCompleteClick

  // AI-generated START - 处理水平拖拽更新
  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    // 只允许向左滑动（负值）
    final newOffset = (_dragOffset + details.delta.dx).clamp(-_completeButtonWidth, 0.0);
    setState(() {
      _dragOffset = newOffset;
    });
  }
  // AI-generated END - _onHorizontalDragUpdate

  // AI-generated START - 处理水平拖拽结束
  void _onHorizontalDragEnd(DragEndDetails details) {
    const threshold = _completeButtonWidth * 0.5; // 滑动超过一半宽度时保持显示

    if (_dragOffset.abs() > threshold) {
      // 滑动超过阈值，保持完成按钮显示
      _slideToCompletePosition();
    } else {
      // 滑动未超过阈值，恢复原位置
      _resetCardPosition();
    }
  }
  // AI-generated END - _onHorizontalDragEnd

  // AI-generated START - 滑动到完成位置
  void _slideToCompletePosition() {
    _slideAnimation = Tween<double>(begin: _dragOffset, end: -_completeButtonWidth).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _dragOffset = -_completeButtonWidth;
        });
      }
    });
  }
  // AI-generated END - _slideToCompletePosition

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
        // AI-generated START - 完成按钮背景
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(16.0),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: _handleCompleteClick,
              child: Text(
                _getActionText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        // AI-generated END - 完成按钮背景

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
                                  color: Colors.black87,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              // AI-generated END - 标题

                              const SizedBox(height: 8.0),

                              // AI-generated START - 描述
                              Text(
                                widget.description,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14.0,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              // AI-generated END - 描述

                              const SizedBox(height: 12.0),

                              // AI-generated START - 日期和优先级标签
                              Row(
                                children: [
                                  // 日期（带日历图片）
                                  Row(
                                    children: [
                                      Image.asset(
                                        'assets/images/mp_todo_cancendar.png',
                                        width: 14.0,
                                        height: 14.0,
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(width: 4.0),
                                      Text(
                                        widget.date,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (widget.priorityTag != null && widget.priorityTag!.isNotEmpty) ...[
                                    const SizedBox(width: 12.0),
                                    // 优先级标签
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10.0,
                                        vertical: 4.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getPriorityColor(widget.priorityTag!),
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                      child: Text(
                                        widget.priorityTag!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              // AI-generated END - 日期和优先级标签
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
                          child: Container(
                            width: 36.0,
                            height: 36.0,
                            decoration: const BoxDecoration(
                              color: Color(0xFF007AFF),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.asset(
                                'assets/images/mp_todo_edit.png',
                                width: 20.0,
                                height: 20.0,
                                fit: BoxFit.contain,
                              ),
                            ),
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
// AI-generated END - todo_task_card.dart
