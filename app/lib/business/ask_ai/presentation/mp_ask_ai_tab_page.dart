import 'package:flutter/cupertino.dart';
import 'package:omi/business/ask_ai/presentation/pages/mp_chat_page.dart';
import 'package:omi/business/ask_ai/presentation/pages/mp_conversations_panel_page.dart';
import 'package:omi/business/ask_ai/presentation/pages/mp_expert_chat_page.dart';
import 'package:omi/business/shared/state/mp_business_controller.dart';
import 'package:omi/business/shared/models/mp_business_models.dart';

class MPAskAiTabPage extends StatelessWidget {
  const MPAskAiTabPage({
    super.key,
    required this.controller,
  });

  final MPBusinessController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final conversations = controller.conversations;
        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Ask AI'),
          ),
          child: SafeArea(
            child: Column(
              children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      color: CupertinoColors.systemGrey5,
                      onPressed: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute<void>(
                            builder: (_) =>
                                MPConversationsPanelPage(controller: controller),
                          ),
                        );
                      },
                      child: const Text(
                        'Conversations',
                        style: TextStyle(color: CupertinoColors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      color: CupertinoColors.systemGrey5,
                      onPressed: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute<void>(
                            builder: (_) =>
                                const MPExpertChatPage(expertName: 'Business'),
                          ),
                        );
                      },
                      child: const Text(
                        'Expert',
                        style: TextStyle(color: CupertinoColors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: CupertinoSearchTextField(),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  return CupertinoListTile(
                    title: Text(conversation.title),
                    subtitle: Text(conversation.preview),
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute<void>(
                          builder: (_) => MPChatPage(conversation: conversation),
                        ),
                      );
                    },
                    trailing: Text(
                      conversation.updatedAtLabel,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemCount: conversations.length,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: () {
                    controller.addConversationDraft('你可以直接输入问题，我会结合你的记忆给出建议。');
                    const draftConversation = MPConversation(
                      id: 'new_chat',
                      title: '新对话',
                      preview: '你可以直接输入问题，我会结合你的记忆给出建议。',
                      updatedAtLabel: '刚刚',
                    );
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) =>
                            const MPChatPage(conversation: draftConversation),
                      ),
                    );
                  },
                  child: const Text('新建对话'),
                ),
              ),
            ),
              ],
            ),
          ),
        );
      },
    );
  }
}
