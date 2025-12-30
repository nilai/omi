// AI-generated START - 参与者卡片组件，显示对话的参与人员列表
import 'package:flutter/material.dart';

/// 参与者数据模型
class Participant {
  // AI-generated START - 构造函数
  const Participant({
    required this.id,
    required this.name,
    this.avatarUrl,
  });
  // AI-generated END - 构造函数

  /// 参与者ID
  final String id;

  /// 参与者姓名
  final String name;

  /// 头像URL
  final String? avatarUrl;
}

/// 参与者卡片组件
/// 显示对话的参与人员列表
class ParticipantsCard extends StatelessWidget {
  // AI-generated START - 参与者列表
  final List<Participant> participants;
  // AI-generated END - participants

  // AI-generated START - 标题
  final String? title;
  // AI-generated END - title

  const ParticipantsCard({
    super.key,
    required this.participants,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: EdgeInsets.zero,
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI-generated START - 标题
          Text(
            title ?? '参与人',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          // AI-generated END - 标题

          const SizedBox(height: 16.0),

          // AI-generated START - 参与者列表
          Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            children: participants.map((participant) {
              return _buildParticipantChip(participant);
            }).toList(),
          ),
          // AI-generated END - 参与者列表
        ],
      ),
    );
  }

  // AI-generated START - 构建参与者标签
  Widget _buildParticipantChip(Participant participant) {
    final avatarUrl = participant.avatarUrl ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AI-generated START - 头像
          CircleAvatar(
            radius: 16.0,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? Text(
                    participant.name.isNotEmpty ? participant.name[0] : '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          // AI-generated END - 头像

          const SizedBox(width: 8.0),

          // AI-generated START - 姓名
          Text(
            participant.name,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14.0,
              fontWeight: FontWeight.normal,
            ),
          ),
          // AI-generated END - 姓名
        ],
      ),
    );
  }
  // AI-generated END - _buildParticipantChip
}
// AI-generated END - participants_card.dart
