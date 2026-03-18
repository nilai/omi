/// 文本选择屏幕
/// 
/// 用于显示消息内容并允许用户选择和复制文本
/// 主要用于长消息的文本选择功能
/// 
/// 兼容 iOS 和 Android 平台
import 'package:flutter/material.dart';
import 'package:omi/backend/schema/message.dart';

import 'widgets/markdown_message_widget.dart';

/// 文本选择屏幕组件
/// 
/// 提供一个全屏界面，允许用户选择和复制消息中的文本内容
class SelectTextScreen extends StatelessWidget {
  /// 要显示的消息对象
  final ServerMessage message;
  
  const SelectTextScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        automaticallyImplyLeading: true,
        title: const Text('Select Text'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SelectionArea(child: getMarkdownWidget(context, message.text)),
      ),
    );
  }
}
