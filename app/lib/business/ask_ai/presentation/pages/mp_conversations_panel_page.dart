import 'package:flutter/cupertino.dart';
import 'package:omi/business/ask_ai/presentation/pages/mp_chat_page.dart';
import 'package:omi/business/shared/state/mp_business_controller.dart';

class MPConversationsPanelPage extends StatelessWidget {
  const MPConversationsPanelPage({
    super.key,
    required this.controller,
  });

  final MPBusinessController controller;

  @override
  Widget build(BuildContext context) {
    final conversations = controller.conversations;
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Conversations'),
      ),
      child: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final item = conversations[index];
            return CupertinoListTile(
              title: Text(item.title),
              subtitle: Text(item.preview),
              trailing: Text(item.updatedAtLabel),
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => MPChatPage(conversation: item),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
