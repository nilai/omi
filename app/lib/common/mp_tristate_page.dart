import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';

import '../generated/assets.dart';
import '../utils/omi_font_utils.dart';
import '../utils/omi_image_loader.dart';
import '../utils/omi_space_utils.dart';
import '../utils/omi_textstyle.dart';
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

/// 可选覆盖配置：未传的字段由 [MPTristateType] 对应的内置默认文案/图标补齐
class MPTristatePageData {
  final Widget? icon;
  final String? title;
  final String? description;
  final bool? showButton;
  final String? buttonText;
  final Color? buttonColor;
  final Color? buttonBgColor;

  final VoidCallback? onButtonPressed;

  const MPTristatePageData({
    this.icon,
    this.title,
    this.description,
    this.showButton = true,
    this.buttonText,
    this.buttonColor,
    this.buttonBgColor,
    this.onButtonPressed,
  });
}

/// 合并后的展示数据（内部使用）
class _ResolvedTristate {
  const _ResolvedTristate({
    this.icon,
    required this.title,
    required this.description,
    required this.showButton,
    required this.buttonText,
    this.buttonColor,
    this.buttonBgColor,
    this.onButtonPressed,
  });

  final Widget? icon;
  final String title;
  final String description;
  final bool showButton;
  final String buttonText;
  final Color? buttonBgColor;
  final Color? buttonColor;
  final VoidCallback? onButtonPressed;
}

/// 三态图页面：根据 [type] 选择默认文案；[data] 仅用于覆盖部分字段
class MPTristatePage extends StatelessWidget {
  final MPTristateType type;

  /// 可选：覆盖当前 [type] 下的标题、描述、按钮等；无需区分 loading/empty 等不同参数
  final MPTristatePageData? data;

  const MPTristatePage({
    super.key,
    this.type = MPTristateType.loading,
    this.data,
  });

  /// 默认插图：`redColor` 浅底、圆角容器内放 [Assets.omiWarning]
  static Widget _buildOmiWarningIcon() {
    return Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: redColor.withValues(alpha: 0.12),
      ),
      child: OmiImageLoader.localImg(
        Assets.omiWarning,
        color: redColor,
        width: 30,
      ),
    );
  }

  static _ResolvedTristate _defaultsFor(MPTristateType type) {
    switch (type) {
      case MPTristateType.loading:
        return const _ResolvedTristate(
          icon: SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title: 'Loading',
          description: 'Please wait...',
          showButton: false,
          buttonText: 'Retry',
          buttonBgColor: blueTextColor,
            buttonColor: Colors.white
        );
      case MPTristateType.empty:
        return _ResolvedTristate(
          icon: _buildOmiWarningIcon(),
          title: '暂无内容',
          description: '当前没有数据',
          showButton: true,
          buttonText: 'Refresh',
            buttonBgColor: blueTextColor,
            buttonColor: Colors.white
        );
      case MPTristateType.noNetwork:
        return _ResolvedTristate(
          icon: _buildOmiWarningIcon(),
          title: 'Not connected',
          description: 'Please check your connection and try again.',
          showButton: true,
          buttonText: 'Retry',
            buttonBgColor: blueTextColor,
            buttonColor: Colors.white
        );
      case MPTristateType.error:
        return _ResolvedTristate(
          icon: _buildOmiWarningIcon(),
          title: '出错了',
          description: '请稍后重试',
          showButton: true,
          buttonText: 'Retry',
            buttonBgColor: blueTextColor,
            buttonColor: Colors.white
        );
    }
  }

  static _ResolvedTristate _merge(_ResolvedTristate base, MPTristatePageData? o) {
    if (o == null) return base;
    return _ResolvedTristate(
      icon: o.icon ?? base.icon,
      title: o.title ?? base.title,
      description: o.description ?? base.description,
      showButton: o.showButton ?? base.showButton,
      buttonText: o.buttonText ?? base.buttonText,
      buttonBgColor: o.buttonBgColor ?? base.buttonBgColor,
      buttonColor: o.buttonColor ?? base.buttonColor,
      onButtonPressed: o.onButtonPressed ?? base.onButtonPressed,
    );
  }

  _ResolvedTristate get _resolved => _merge(_defaultsFor(type), data);

  @override
  Widget build(BuildContext context) {
    final _ResolvedTristate d = _resolved;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            d.icon ?? _buildOmiWarningIcon(),
            SizedBox(height: textLargePadding),
            Text(
              d.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mainTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: textSmallPadding),
            Text(
              d.description,
              textAlign: TextAlign.center,
              style: OmiTextStyle.create(
                color: secondTextColor.withValues(alpha: 0.7),
                fontSize: OmiFontSize.smallTextFontSize,
              ),
            ),
            if (d.showButton) ...[
              SizedBox(height: textLargePadding),
              SizedBox(
                child: OmiButton(
                  textFontSize: OmiFontSize.secondTextFontSize,
                  bgColor: d.buttonBgColor ?? blueTextColor,
                  textColor: d.buttonColor,
                  text: d.buttonText,
                  onPressed: d.onButtonPressed,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
