import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_image_loader.dart';
import 'package:omi/utils/omi_textstyle.dart';

import '../generated/assets.dart';


/// 顶部导航栏样式类型（覆盖设计图中的 4 种头部）
enum MPNavigationBarVariant {
  /// Memory：标题 + 右侧搜索
  memory,

  /// Ask AI：左侧圆形图标 + 标题 + 右侧菜单
  askAi,

  /// Preferences：标题 + 右侧设置、用户
  preferences,

  /// MemoPin：左侧圆形图标 + 标题 + 右侧日历、新增
  memoPin,
}

/// 通用导航栏（放在 [Scaffold.appBar] 时需用 [PreferredSize] 包裹）
///
/// ```dart
/// appBar: PreferredSize(
///   preferredSize: MPNavigationBar.preferredSizeOf(context),
///   child: MPNavigationBar(variant: ...),
/// ),
/// ```
class MPNavigationBar extends StatelessWidget {
  const MPNavigationBar({
    super.key,
    required this.variant,
    this.title,
    this.onLeadingTap,
    this.onPrimaryActionTap,
    this.onSecondaryActionTap,
    this.backgroundColor = Colors.transparent,
  });

  /// 状态栏以下内容区最小高度（与 [preferredSizeOf] 一致）
  static const double _kContentMinHeight = 44;

  static const double _kBottomPadding = 0;

  static const double _kHorizontalPadding = 20;

  /// 与 [build] 实际高度一致，供外层 [PreferredSize] 使用
  static Size preferredSizeOf(BuildContext context) {
    final double top = MediaQuery.paddingOf(context).top;
    return Size.fromHeight(top + _kContentMinHeight + _kBottomPadding);
  }

  /// 预设样式
  final MPNavigationBarVariant variant;

  /// 自定义标题；未传时使用各样式默认标题
  final String? title;

  /// 左侧图标点击（有左侧图标的样式可用）
  final VoidCallback? onLeadingTap;

  /// 右侧第一个操作按钮点击
  final VoidCallback? onPrimaryActionTap;

  /// 右侧第二个操作按钮点击（如 preferences / memoPin）
  final VoidCallback? onSecondaryActionTap;

  /// 背景色
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.paddingOf(context).top;
    return ColoredBox(
      color: backgroundColor,
      child: Padding(
        padding: EdgeInsets.only(
          top: topInset,
          left: _kHorizontalPadding,
          right: _kHorizontalPadding,
          bottom: _kBottomPadding,
        ),
        child: SizedBox(
          height: _kContentMinHeight,
          child: Row(
            children: [
              if (_showLeading) ...[
                _buildLeading(),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  _resolvedTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OmiTextStyle.create(
                    fontSize: _isLargeTitle ? 44 / 2 : 40 / 2,
                    fontWeight: OmiFontWeight.medium,
                    color: mainTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ..._buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  bool get _showLeading =>
      variant == MPNavigationBarVariant.askAi ||
      variant == MPNavigationBarVariant.memoPin;

  bool get _isLargeTitle =>
      variant == MPNavigationBarVariant.memory ||
      variant == MPNavigationBarVariant.preferences;

  String get _resolvedTitle {
    if (title != null && title!.trim().isNotEmpty) return title!;
    switch (variant) {
      case MPNavigationBarVariant.memory:
        return 'Memory';
      case MPNavigationBarVariant.askAi:
        return 'Ask AI';
      case MPNavigationBarVariant.preferences:
        return 'Preferences';
      case MPNavigationBarVariant.memoPin:
        return 'MemoPin';
    }
  }

  Widget _buildLeading() {
    switch (variant) {
      case MPNavigationBarVariant.askAi:
        return _buildCircleButton(
          onTap: onLeadingTap,
          child: OmiImageLoader.localImg(
            Assets.omiSparkles,
            width: 16,
            height: 16,
            color: const Color(0xFF8D6EF9),
            fit: BoxFit.cover,
          ),
        );
      case MPNavigationBarVariant.memoPin:
        return _buildCircleButton(
          onTap: onLeadingTap,
          bgColor: Colors.white,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBFC6D4), width: 1.5),
              color: Colors.white,
            ),
          ),
        );
      case MPNavigationBarVariant.memory:
      case MPNavigationBarVariant.preferences:
        return const SizedBox.shrink();
    }
  }

  List<Widget> _buildActions() {
    switch (variant) {
      case MPNavigationBarVariant.memory:
        return <Widget>[
          _buildIconAction(
            icon: Assets.omiSearch,
            onTap: onPrimaryActionTap,
            color: blueTextColor,
          ),
        ];
      case MPNavigationBarVariant.askAi:
        return <Widget>[
          _buildIconAction(
            icon: Assets.omiMore,
            onTap: onPrimaryActionTap,
            color: secondTextColor,
          ),
        ];
      case MPNavigationBarVariant.preferences:
        return <Widget>[
          _buildIconAction(
            icon: Assets.tabSetting,
            onTap: onPrimaryActionTap,
            color: secondTextColor,
          ),
          const SizedBox(width: 16),
          _buildIconAction(
            icon: Assets.omiUser,
            onTap: onSecondaryActionTap,
            color: secondTextColor,
          ),
        ];
      case MPNavigationBarVariant.memoPin:
        return <Widget>[
          _buildIconAction(
            icon: Assets.omiCalendar,
            onTap: onPrimaryActionTap,
            color: blueTextColor,
          ),
          const SizedBox(width: 16),
          _buildCircleButton(
            onTap: onSecondaryActionTap,
            size: 30,
            bgColor: blueTextColor,
            child: OmiImageLoader.localImg(Assets.omiPlus, width: 20, height: 20, color: Colors.white),
          ),
        ];
    }
  }

  Widget _buildIconAction({
    required String icon,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return InkResponse(
      onTap: onTap,
      radius: 18,
      child: OmiImageLoader.localImg(icon, color: color, width: 20, height: 20),
    );
  }

  Widget _buildCircleButton({
    required Widget child,
    required VoidCallback? onTap,
    double size = 34,
    Color bgColor = const Color(0xFFF5F6F8),
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
