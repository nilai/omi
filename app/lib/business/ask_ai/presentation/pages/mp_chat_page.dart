import 'package:flutter/cupertino.dart';
import 'package:omi/business/shared/models/mp_business_models.dart';

class MPChatPage extends StatelessWidget {
  const MPChatPage({
    super.key,
    required this.conversation,
  });

  final MPConversation conversation;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(conversation.title),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _bubble('你可以根据本周事项帮我做个复盘吗？', false),
                  _bubble(conversation.preview, true),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Expanded(child: CupertinoTextField()),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onPressed: () {},
                    child: const Text('发送'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(String text, bool isAi) {
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isAi ? CupertinoColors.systemGrey5 : CupertinoColors.activeBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isAi ? CupertinoColors.black : CupertinoColors.white,
          ),
        ),
      ),
    );
  }
}
