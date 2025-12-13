// AI-generated START - 通用 AppBar 组件
import 'package:flutter/material.dart';

/// 通用 AppBar 组件
/// 包含返回按钮（可选）和标题
class MPCommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// 标题文本
  final String title;

  /// 是否显示返回按钮，默认为 true
  final bool showBackButton;

  /// 返回按钮点击回调，如果为 null 则使用默认的 Navigator.pop()
  final VoidCallback? onBackPressed;

  /// 右侧操作按钮列表
  final List<Widget>? actions;

  /// 背景色，默认为白色
  final Color? backgroundColor;

  /// 标题文字颜色
  final Color? titleColor;

  /// 返回按钮图标颜色
  final Color? iconColor;

  const MPCommonAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.backgroundColor,
    this.titleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? Colors.white,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: iconColor ?? Colors.grey.shade800,
              ),
              onPressed: onBackPressed ??
                  () {
                    Navigator.of(context).pop();
                  },
            )
          : null,
      automaticallyImplyLeading: false,
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? Colors.grey.shade800,
          fontSize: 18.0,
          fontWeight: FontWeight.w500,
        ),
      ),
      centerTitle: true,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
// AI-generated END - mp_common_app_bar.dart

