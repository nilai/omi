// AI-generated START - App集成卡片组件，显示已集成的应用列表
import 'package:flutter/material.dart';
import 'package:omi/gen/assets.gen.dart';

/// 集成应用信息数据模型
class IntegratedAppInfo {
  // AI-generated START - 应用名称
  final String name;
  // AI-generated END - name

  // AI-generated START - 应用图标URL或图标数据
  final Widget? icon;
  // AI-generated END - icon

  // AI-generated START - 应用图标颜色
  final Color? iconColor;
  // AI-generated END - iconColor

  const IntegratedAppInfo({
    required this.name,
    this.icon,
    this.iconColor,
  });
}

/// App集成卡片组件
/// 显示已集成的应用列表，包含主图标、标题和应用图标列表
class AppIntegrationCardWidget extends StatelessWidget {
  // AI-generated START - 卡片点击回调
  final VoidCallback? onTap;
  // AI-generated END - onTap

  // AI-generated START - 标题文本
  final String? title;
  // AI-generated END - title

  // AI-generated START - 集成应用列表
  final List<IntegratedAppInfo> integratedApps;
  // AI-generated END - integratedApps

  // AI-generated START - 最大显示应用数量（默认3个）
  final int maxVisibleApps;
  // AI-generated END - maxVisibleApps

  const AppIntegrationCardWidget({
    super.key,
    this.onTap,
    this.title,
    this.integratedApps = const [],
    this.maxVisibleApps = 3,
  });

  // AI-generated START - 获取默认集成应用列表
  static List<IntegratedAppInfo> getDefaultApps() {
    return [
      IntegratedAppInfo(
        name: 'Calendar',
        icon: Assets.images.settingCalendar.image(
          fit: BoxFit.contain,
          width: 20.0,
          height: 20.0,
        ),
      ),
      IntegratedAppInfo(
        name: 'Notion',
        icon: Assets.images.settingNotion.image(
          fit: BoxFit.contain,
          width: 20.0,
          height: 20.0,
        ),
      ),
      IntegratedAppInfo(
        name: 'Check',
        icon: Assets.images.settingCheck.image(
          fit: BoxFit.contain,
          width: 20.0,
          height: 20.0,
        ),
      ),
    ];
  }
  // AI-generated END - getDefaultApps

  @override
  Widget build(BuildContext context) {
    final appList = integratedApps.isEmpty ? AppIntegrationCardWidget.getDefaultApps() : integratedApps;
    final visibleApps = appList.take(maxVisibleApps).toList();
    final hasMore = appList.length > maxVisibleApps;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: Colors.green.shade100.withValues(alpha: 0.5),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.1),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // AI-generated START - 左侧：主图标
              Container(
                width: 56.0,
                height: 56.0,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF10B981), // 深绿色
                      Color(0xFF34D399), // 浅绿色
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Assets.images.settingIntegrated.image(
                    fit: BoxFit.cover,
                    width: 56.0,
                    height: 56.0,
                  ),
                ),
              ),
              // AI-generated END - 左侧：主图标

              const SizedBox(width: 16.0),

              // AI-generated START - 中间：标题和应用图标列表
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title ?? 'App集成',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      children: [
                        ...visibleApps.map((app) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8.0),
                            width: 32.0,
                            height: 32.0,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: app.icon ??
                                Center(
                                  child: app.iconColor != null
                                      ? Icon(
                                          _getAppIcon(app.name),
                                          color: app.iconColor,
                                          size: 20.0,
                                        )
                                      : Icon(
                                          Icons.apps,
                                          color: Colors.grey.shade400,
                                          size: 20.0,
                                        ),
                                ),
                          );
                        }),
                        if (hasMore)
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Text(
                              '+更多',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // AI-generated END - 中间：标题和应用图标列表

              const SizedBox(width: 12.0),

              // AI-generated START - 右侧：箭头图标
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 24.0,
              ),
              // AI-generated END - 右侧：箭头图标
            ],
          ),
        ),
      ),
    );
  }

  // AI-generated START - 根据应用名称获取图标
  IconData _getAppIcon(String appName) {
    switch (appName.toLowerCase()) {
      case 'calendar':
        return Icons.calendar_today;
      case 'notion':
        return Icons.note;
      case 'check':
        return Icons.check_circle;
      default:
        return Icons.apps;
    }
  }
  // AI-generated END - _getAppIcon
}
// AI-generated END - app_integration_card_widget.dart
