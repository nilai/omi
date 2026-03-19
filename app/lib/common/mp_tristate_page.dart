import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';

import 'omi_button.dart';

/// 三态图页面类型
enum MPTristateType {
  /// 加载中
  loading,

  /// 空内容
  empty,

  /// 无网络
  noNetwork,

  /// 异常/错误
  error,
}

/// 三态图页面配置（icon/标题/描述/按钮）
class MPTristatePageData {
  final Widget icon;
  final String title;
  final String description;
  final bool showButton;
  final String buttonText;
  final VoidCallback? onButtonPressed;

  const MPTristatePageData({
    required this.icon,
    this.title = '',
    this.description = '',
    this.showButton = true,
    this.buttonText = '重试',
    this.onButtonPressed,
  });
}

/// 三态图页面：用于在加载/空/错误时展示统一的 UI
class MPTristatePage extends StatelessWidget {
  final MPTristateType type;
  final MPTristatePageData loadingData;
  final MPTristatePageData emptyData;
  final MPTristatePageData noNetworkData;
  final MPTristatePageData errorData;

  const MPTristatePage({
    super.key,
    this.type = MPTristateType.loading,
    MPTristatePageData? loadingData,
    MPTristatePageData? emptyData,
    MPTristatePageData? noNetworkData,
    MPTristatePageData? errorData,
  })  : loadingData = loadingData ??
            const MPTristatePageData(
              icon: SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: '加载中',
              description: '请稍候',
              showButton: false,
            ),
        emptyData = emptyData ??
            const MPTristatePageData(
              icon: Icon(Icons.inbox_outlined, size: 48),
              title: '暂无内容',
              description: '当前没有数据',
              showButton: true,
              buttonText: '刷新',
            ),
        noNetworkData = noNetworkData ??
            const MPTristatePageData(
              icon: Icon(Icons.wifi_off_outlined, size: 48),
              title: '无网络',
              description: '请检查网络连接后重试',
              showButton: true,
              buttonText: '重试',
            ),
        errorData = errorData ??
            const MPTristatePageData(
              icon: Icon(Icons.error_outline, size: 48),
              title: '出错了',
              description: '请稍后重试',
              showButton: true,
              buttonText: '重试',
            );

  MPTristatePageData get _currentData {
    switch (type) {
      case MPTristateType.loading:
        return loadingData;
      case MPTristateType.empty:
        return emptyData;
      case MPTristateType.noNetwork:
        return noNetworkData;
      case MPTristateType.error:
        return errorData;
    }
  }

  @override
  Widget build(BuildContext context) {
    final MPTristatePageData data = _currentData;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            data.icon,
            const SizedBox(height: 12),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mainTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondTextColor.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            if (data.showButton) ...[
              const SizedBox(height: 16),
              SizedBox(
                child: OmiButton(
                  text: data.buttonText,
                  onPressed: data.onButtonPressed,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

