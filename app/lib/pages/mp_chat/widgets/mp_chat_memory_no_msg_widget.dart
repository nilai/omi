import 'package:flutter/material.dart';

/// 基于记忆提问的Widget
/// 显示快速提问选项和记忆卡片
class MPChatMemoryNoMsgWidget extends StatelessWidget {
  /// 点击快速提问后的回调，返回问题文本
  final Function(String)? onQuickQuestionTap;

  /// 点击底部按钮后的回调
  final VoidCallback? onAskAITap;

  /// 点击查看完整记忆后的回调
  final VoidCallback? onViewFullMemoryTap;

  /// 记忆标题
  final String memoryTitle;

  /// 记忆日期（格式：2025-07-22）
  final String memoryDate;

  /// 记忆时长（格式：42分9秒）
  final String memoryDuration;

  /// 参与人列表
  final List<String> participants;

  /// 记忆内容
  final String memoryContent;

  /// 是否可编辑
  final bool editable;

  /// 标题修改回调
  final ValueChanged<String>? onTitleChanged;

  /// 日期修改回调
  final ValueChanged<String>? onDateChanged;

  /// 时长修改回调
  final ValueChanged<String>? onDurationChanged;

  /// 参与人修改回调
  final ValueChanged<List<String>>? onParticipantsChanged;

  /// 内容修改回调
  final ValueChanged<String>? onContentChanged;

  const MPChatMemoryNoMsgWidget({
    super.key,
    this.onQuickQuestionTap,
    this.onAskAITap,
    this.onViewFullMemoryTap,
    this.memoryTitle = '耳机与AI硬件市场需求与产品设计',
    this.memoryDate = '2025-07-22',
    this.memoryDuration = '42分9秒',
    this.participants = const ['叶志伟', '叶天命', '叶成功', 'Speaker1023'],
    this.memoryContent = '本次会议重点讨论了AI硬件市场的需求分析和产品设计方案。团队确定了以用户体验为核心的差异化策略,强调技术门槛作为竞争壁垒的重要性。',
    this.editable = false,
    this.onTitleChanged,
    this.onDateChanged,
    this.onDurationChanged,
    this.onParticipantsChanged,
    this.onContentChanged,
  });

  /// 快速提问的问题列表
  static const List<String> quickQuestions = [
    '有哪些需要跟进的地方?',
    '和对方沟通的风险点是哪些?',
    '还有哪些没有解决的问题?',
    '下次会议需要准备什么材料?',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 可滚动内容区域
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 顶部标题和图标
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    // 快速提问部分
                    _buildQuickQuestions(context),
                    const SizedBox(height: 24),
                    // 记忆卡片
                    _buildMemoryCard(context),
                  ],
                ),
              ),
            ),
            // 底部按钮 - 使用Spacer确保靠近底部，间距最少24
            const SizedBox(height: 24),
            _buildBottomButton(context),
            // 确保底部有足够间距
            SizedBox(
              height: MediaQuery.of(context).padding.bottom + 16,
            ),
          ],
        );
      },
    );
  }

  /// 构建顶部标题和图标
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          // 紫色图标
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6), // 紫色
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.amber,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          // 标题
          const Text(
            '基于记忆提问',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建快速提问部分
  Widget _buildQuickQuestions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 快速提问标题
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            '快速提问',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 快速提问按钮列表
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: quickQuestions.map((question) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildQuestionButton(
                  context: context,
                  question: question,
                  onTap: () {
                    onQuickQuestionTap?.call(question);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// 构建问题按钮
  Widget _buildQuestionButton({
    required BuildContext context,
    required String question,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6), // 浅灰色背景
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1F2937),
            height: 1.4,
          ),
        ),
      ),
    );
  }

  /// 构建记忆卡片
  Widget _buildMemoryCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E8FF), // 浅紫色背景
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 附件标题和关闭按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B82F6), // 蓝色
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.attach_file,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '附件:记忆',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                if (onViewFullMemoryTap != null)
                  GestureDetector(
                    onTap: onViewFullMemoryTap,
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: Color(0xFF6B7280),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // 记忆标题
            _buildEditableField(
              context: context,
              value: memoryTitle,
              onChanged: onTitleChanged,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            // 日期、时长、参与人
            _buildMetadata(context),
            const SizedBox(height: 12),
            // 记忆内容（最多三行）
            _buildContent(context),
            const SizedBox(height: 12),
            // 查看完整记忆链接
            if (onViewFullMemoryTap != null)
              GestureDetector(
                onTap: onViewFullMemoryTap,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '查看完整记忆',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3B82F6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Color(0xFF3B82F6),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建元数据（日期、时长、参与人）
  Widget _buildMetadata(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期
        Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 16,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(width: 6),
            _buildEditableField(
              context: context,
              value: memoryDate,
              onChanged: onDateChanged,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 时长
        Row(
          children: [
            const Icon(
              Icons.access_time,
              size: 16,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(width: 6),
            _buildEditableField(
              context: context,
              value: memoryDuration,
              onChanged: onDurationChanged,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 参与人（可滚动）
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.people,
                size: 16,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildParticipantsList(context),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建参与人列表（可滚动）
  Widget _buildParticipantsList(BuildContext context) {
    final participantsText = participants.join('、');
    if (editable && onParticipantsChanged != null) {
      // 可编辑模式：使用TextField，支持水平滚动
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: TextField(
          controller: TextEditingController(text: participantsText)
            ..selection = TextSelection.collapsed(offset: participantsText.length),
          onChanged: (value) {
            // 将文本按顿号分割成列表
            final newParticipants = value.split('、').where((p) => p.trim().isNotEmpty).toList();
            onParticipantsChanged?.call(newParticipants);
          },
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
    } else {
      // 只读模式：使用Text，支持水平滚动
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          participantsText,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      );
    }
  }

  /// 构建内容（最多三行）
  Widget _buildContent(BuildContext context) {
    return _buildEditableField(
      context: context,
      value: memoryContent,
      onChanged: onContentChanged,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF1F2937),
        height: 1.5,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 构建可编辑字段
  Widget _buildEditableField({
    required BuildContext context,
    required String value,
    ValueChanged<String>? onChanged,
    required TextStyle style,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    if (editable && onChanged != null) {
      return TextField(
        controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length),
        onChanged: onChanged,
        style: style,
        maxLines: maxLines,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      );
    } else {
      return Text(
        value,
        style: style,
        maxLines: maxLines,
        overflow: overflow ?? TextOverflow.visible,
      );
    }
  }

  /// 构建底部按钮
  Widget _buildBottomButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GestureDetector(
        onTap: onAskAITap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6), // 浅灰色背景
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '基于当前记忆向AI提问',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ),
    );
  }
}
