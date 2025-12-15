// AI-generated START - 专家反馈卡片组件，显示专家列表和选择入口
import 'package:flutter/material.dart';
import 'package:omi/gen/assets.gen.dart';

/// 专家信息数据模型
class ExpertInfo {
  // AI-generated START - 专家名称
  final String name;
  // AI-generated END - name

  // AI-generated START - 专家头像URL或图标
  final String? avatarUrl;
  // AI-generated END - avatarUrl

  // AI-generated START - 专家角色标签
  final String role;
  // AI-generated END - role

  // AI-generated START - 头像边框颜色
  final Color borderColor;
  // AI-generated END - borderColor

  const ExpertInfo({
    required this.name,
    required this.role,
    this.avatarUrl,
    required this.borderColor,
  });
}

/// 专家反馈卡片组件
/// 显示专家列表，支持选择不同领域的AI专家进行沟通
class ExpertFeedbackCardWidget extends StatelessWidget {
  // AI-generated START - 卡片点击回调
  final VoidCallback? onTap;
  // AI-generated END - onTap

  // AI-generated START - 标题文本
  final String? title;
  // AI-generated END - title

  // AI-generated START - 副标题文本
  final String? subtitle;
  // AI-generated END - subtitle

  // AI-generated START - 专家列表
  final List<ExpertInfo> experts;
  // AI-generated END - experts

  // AI-generated START - 专家头像点击回调
  final Function(ExpertInfo)? onExpertTap;
  // AI-generated END - onExpertTap

  const ExpertFeedbackCardWidget({
    super.key,
    this.onTap,
    this.title,
    this.subtitle,
    this.experts = const [],
    this.onExpertTap,
  });

  // AI-generated START - 获取默认专家列表
  static List<ExpertInfo> getDefaultExperts() {
    return const [
      ExpertInfo(
        name: '商业顾问',
        role: '商业顾问',
        borderColor: Color(0xFF60A5FA), // 浅蓝色
      ),
      ExpertInfo(
        name: '技术专家',
        role: '技术专家',
        borderColor: Color(0xFFA78BFA), // 浅紫色
      ),
      ExpertInfo(
        name: '营销专家',
        role: '营销专家',
        borderColor: Color(0xFF34D399), // 浅绿色
      ),
      ExpertInfo(
        name: '财务顾问',
        role: '财务顾问',
        borderColor: Color(0xFFFB923C), // 浅橙色
      ),
      ExpertInfo(
        name: '法律顾问',
        role: '法律顾问',
        borderColor: Color(0xFFF472B6), // 浅粉色
      ),
    ];
  }
  // AI-generated END - getDefaultExperts

  @override
  Widget build(BuildContext context) {
    final expertList = experts.isEmpty ? ExpertFeedbackCardWidget.getDefaultExperts() : experts;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI-generated START - 顶部：标题和导航箭头
            GestureDetector(
              onTap: onTap,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title ?? '专家反馈',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          subtitle ?? '选择不同领域的AI专家进行沟通',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Assets.images.settingRightArrow2.image(
                    width: 21.0,
                    height: 20.0,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
            // AI-generated END - 顶部：标题和导航箭头

            const SizedBox(height: 12.0),

            // AI-generated START - 专家头像列表
            SizedBox(
              height: 84.0,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: expertList.length,
                itemBuilder: (context, index) {
                  final expert = expertList[index];
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onExpertTap?.call(expert),
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index < expertList.length - 1 ? 16.0 : 0,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 56.0,
                            height: 56.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: expert.borderColor,
                                width: 2.0,
                              ),
                            ),
                            child: ClipOval(
                              child: expert.avatarUrl != null
                                  ? Image.network(
                                      expert.avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return _buildDefaultAvatar(expert);
                                      },
                                    )
                                  : _buildDefaultAvatar(expert),
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          SizedBox(
                            width: 70.0,
                            child: Text(
                              expert.role,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12.0,
                                fontWeight: FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // AI-generated END - 专家头像列表
          ],
        ),
      ),
    );
  }

  // AI-generated START - 构建默认头像
  Widget _buildDefaultAvatar(ExpertInfo expert) {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.person,
          color: Colors.grey.shade400,
          size: 30.0,
        ),
      ),
    );
  }
  // AI-generated END - _buildDefaultAvatar
}
// AI-generated END - expert_feedback_card_widget.dart
