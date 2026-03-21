import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_image_loader.dart';
import 'package:omi/utils/omi_textstyle.dart';

import '../generated/assets.dart';

/// 通用导航栏：左返回 / 自定义 leading、居中标题、右侧多个控件由外部传入
///
/// 放在 [Scaffold.appBar] 时需用 [PreferredSize] 包裹：
///
/// ```dart
/// appBar: PreferredSize(
///   preferredSize: MPCustomNavBar.preferredSizeOf(context),
///   child: MPCustomNavBar(
///     title: 'Memory',
///     actions: [
///       IconButton(icon: Icon(Icons.share_outlined), onPressed: () {}),
///       IconButton(icon: Icon(Icons.more_vert), onPressed: () {}),
///     ],
///   ),
/// ),
/// ```
class MPCustomNavBar extends StatelessWidget {
  const MPCustomNavBar({
    super.key,
    required this.title,
    this.leading,
    this.showBackButton = true,
    this.onBack,
    this.actions,
    this.backgroundColor = Colors.white,
    this.titleStyle,
  });

  /// 中间标题文案
  final String title;

  /// 左侧区域；不为 `null` 时优先于 [showBackButton] / 默认返回
  final Widget? leading;

  /// 是否展示默认返回按钮（仅当 [leading] 为 `null` 时有效）
  final bool showBackButton;

  /// 返回回调；默认 [Navigator.maybePop]
  final VoidCallback? onBack;

  /// 右侧操作区，由外部自行组合（如图标按钮、[Row]、[PopupMenuButton] 等）
  final List<Widget>? actions;

  final Color backgroundColor;

  /// 标题样式；未传则使用项目默认标题样式
  final TextStyle? titleStyle;

  static const double _kContentMinHeight = 44;

  static const double _kHorizontalPadding = 4;

  /// 与 [build] 实际高度一致，供外层 [PreferredSize] 使用（含状态栏占位）
  static Size preferredSizeOf(BuildContext context) {
    final double top = MediaQuery.paddingOf(context).top;
    return Size.fromHeight(top + _kContentMinHeight);
  }

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.paddingOf(context).top;
    final List<Widget> actionChildren = actions ?? const <Widget>[];

    return ColoredBox(
      color: backgroundColor,
      child: Padding(
        padding: EdgeInsets.only(
          top: topInset,
          left: 0,
          right: 16,
        ),
        child: SizedBox(
          height: _kContentMinHeight,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: _buildLeading(context),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 56),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: titleStyle ??
                        OmiTextStyle.create(
                          fontSize: OmiFontSize.t8_17,
                          fontWeight: OmiFontWeight.medium,
                          color: mainTextColor,
                        ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actionChildren,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    if (leading != null) {
      return leading!;
    }
    if (!showBackButton) {
      return const SizedBox.shrink();
    }
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 44,
        minHeight: 44,
      ),
      icon: OmiImageLoader.localImg(Assets.omiLeftBack, color: blueTextColor, width: 20, height: 20),
      onPressed: onBack ?? () => Navigator.maybePop(context),
    );
  }
}
