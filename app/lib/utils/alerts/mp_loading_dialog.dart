import 'package:flutter/material.dart';

/// MP Loading对话框工具类
/// 用于显示模态loading对话框，阻止用户交互
class MPLoadingDialog {
  /// 显示loading对话框
  /// [context] BuildContext
  /// [message] 可选的提示消息，默认为"下载中..."
  /// 返回Navigator的pop结果，用于后续关闭对话框
  static void show(
    BuildContext context, {
    String message = '下载中...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // 阻止点击外部关闭
      barrierColor: Colors.black54, // 半透明背景
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // 阻止返回键关闭
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 隐藏loading对话框
  /// [context] BuildContext
  static void hide(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}
