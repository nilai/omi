import 'package:flutter/material.dart';

/// 模态弹层：点击灰色遮罩区域关闭（与 [showOmiEditTodoPopup] 底部弹层一致）。
///
/// [child] 为底部对齐的面板；点击面板外区域会 [Navigator.pop]。
class MPDismissibleModalBackdrop extends StatelessWidget {
  const MPDismissibleModalBackdrop({
    super.key,
    required this.child,
    this.onDismiss,
    this.unfocusOnDismiss = true,
  });

  final Widget child;

  /// 自定义关闭逻辑；默认 [Navigator.pop]。
  final VoidCallback? onDismiss;

  /// 关闭前是否收起键盘。
  final bool unfocusOnDismiss;

  void _handleDismiss(BuildContext context) {
    if (unfocusOnDismiss) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    if (onDismiss != null) {
      onDismiss!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _handleDismiss(context),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      ],
    );
  }
}
