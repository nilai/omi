import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:omi/backend/http/api/messages.dart';
import 'package:omi/backend/preferences.dart';
import 'package:omi/backend/schema/app.dart';
import 'package:omi/backend/schema/conversation.dart';
import 'package:omi/backend/schema/message.dart';
import 'package:omi/gen/assets.gen.dart';
import 'package:omi/pages/chat/select_text_screen.dart';
import 'package:omi/pages/chat/widgets/ai_message.dart';
import 'package:omi/pages/chat/widgets/user_message.dart';
import 'package:omi/pages/chat/widgets/voice_recorder_widget.dart';
import 'package:omi/providers/connectivity_provider.dart';
import 'package:omi/providers/conversation_provider.dart';
import 'package:omi/providers/home_provider.dart';
import 'package:omi/providers/message_provider.dart';
import 'package:omi/utils/alerts/app_snackbar.dart';
import 'package:omi/utils/analytics/mixpanel.dart';
import 'package:omi/utils/other/temp.dart';
import 'package:omi/widgets/dialog.dart';
import 'package:omi/widgets/extensions/string.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../chat/widgets/message_action_menu.dart';
import 'widgets/mp_chat_appbar.dart';
import 'widgets/mp_chat_suggestion_cards.dart';

// 聊天页面类型。不同类型调用url接口入参不同。
enum MPChatPageType {
  // 普通聊天
  normal,
  // 记忆总结
  memory,
  // 模板聊天
  template,
  // AI分析助手
  aiAssistant,
  // 专家模型
  expert,
}

class MPChatPage extends StatefulWidget {
  const MPChatPage({
    super.key,
  });

  @override
  State<MPChatPage> createState() => MPChatPageState();
}

class MPChatPageState extends State<MPChatPage> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  TextEditingController textController = TextEditingController();
  late ScrollController scrollController;
  late FocusNode textFieldFocusNode;

  bool isScrollingDown = false;

  bool _showVoiceRecorder = false;

  var prefs = SharedPreferencesUtil();

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    scrollController = ScrollController();
    textFieldFocusNode = FocusNode();
    textController.addListener(() {
      setState(() {});
    });

    scrollController.addListener(() {
      if (scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (!isScrollingDown) {
          isScrollingDown = true;
          setState(() {});
          Future.delayed(const Duration(seconds: 5), () {
            if (isScrollingDown) {
              isScrollingDown = false;
              if (mounted) {
                setState(() {});
              }
            }
          });
        }
      }

      if (scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (isScrollingDown) {
          isScrollingDown = false;
          setState(() {});
        }
      }
    });
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      var provider = context.read<MessageProvider>();
      if (provider.messages.isEmpty) {
        provider.refreshMessages();
      }
      // provider.fetchChatApps();
      scrollToBottom();
    });
    super.initState();
  }

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer2<MessageProvider, ConnectivityProvider>(
      builder: (context, provider, connectivityProvider, child) {
        return Scaffold(
          key: scaffoldKey,
          backgroundColor: Theme.of(context).colorScheme.primary,
          appBar: MPChatAppBar(
            onLeftIconTap: () => (),
            onMenuTap: () => (),
          ),
          body: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Column(
              children: [
                Expanded(
                  child: provider.messages.isEmpty
                      ? _noMessagesWidget()
                      : ListView.builder(
                          shrinkWrap: false,
                          reverse: true,
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          itemCount: provider.messages.length,
                          itemBuilder: (context, chatIndex) {
                            final message = provider.messages[chatIndex];
                            double topPadding = chatIndex == provider.messages.length - 1 ? 8 : 16;

                            double bottomPadding = chatIndex == 0 ? 16 : 0;
                            return GestureDetector(
                              onLongPress: () {
                                showModalBottomSheet(
                                  context: context,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (context) => MessageActionMenu(
                                    message: message.text.decodeString,
                                    onCopy: () async {
                                      MixpanelManager()
                                          .track('Chat Message Copied', properties: {'message': message.text});
                                      await Clipboard.setData(ClipboardData(text: message.text.decodeString));
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Message copied to clipboard.',
                                              style: TextStyle(
                                                color: Color.fromARGB(255, 255, 255, 255),
                                                fontSize: 12.0,
                                              ),
                                            ),
                                            duration: Duration(milliseconds: 2000),
                                          ),
                                        );
                                        Navigator.pop(context);
                                      }
                                    },
                                    onSelectText: () {
                                      MixpanelManager()
                                          .track('Chat Message Text Selected', properties: {'message': message.text});
                                      routeToPage(context, SelectTextScreen(message: message));
                                    },
                                    onShare: () {
                                      MixpanelManager()
                                          .track('Chat Message Shared', properties: {'message': message.text});
                                      Share.share(
                                        '${message.text.decodeString}\n\nResponse from Omi. Get yours at https://omi.me',
                                        subject: 'Chat with Omi',
                                      );
                                      Navigator.pop(context);
                                    },
                                    onThumbsUp: message.sender == MessageSender.ai && message.askForNps
                                        ? () {
                                            provider.setMessageNps(message, 1);
                                            Navigator.pop(context);
                                            AppSnackbar.showSnackbar('Thank you for your feedback!');
                                          }
                                        : null,
                                    onThumbsDown: message.sender == MessageSender.ai && message.askForNps
                                        ? () {
                                            provider.setMessageNps(message, 0);
                                            Navigator.pop(context);
                                            AppSnackbar.showSnackbar('Thank you for your feedback!');
                                          }
                                        : null,
                                    onReport: () {
                                      if (message.sender == MessageSender.human) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'You cannot report your own messages.',
                                              style: TextStyle(
                                                color: Color.fromARGB(255, 255, 255, 255),
                                                fontSize: 12.0,
                                              ),
                                            ),
                                            duration: Duration(milliseconds: 2000),
                                          ),
                                        );
                                        return;
                                      }
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return getDialog(
                                            context,
                                            () {
                                              Navigator.of(context).pop();
                                            },
                                            () {
                                              MixpanelManager().track('Chat Message Reported',
                                                  properties: {'message': message.text});
                                              Navigator.of(context).pop();
                                              Navigator.of(context).pop();
                                              context.read<MessageProvider>().removeLocalMessage(message.id);
                                              reportMessageServer(message.id);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Message reported successfully.',
                                                    style: TextStyle(
                                                      color: Color.fromARGB(255, 255, 255, 255),
                                                      fontSize: 12.0,
                                                    ),
                                                  ),
                                                  duration: Duration(milliseconds: 2000),
                                                ),
                                              );
                                            },
                                            'Report Message',
                                            'Are you sure you want to report this message?',
                                          );
                                        },
                                      );
                                    },
                                  ),
                                );
                              },
                              child: Padding(
                                key: ValueKey(message.id),
                                padding: EdgeInsets.only(bottom: bottomPadding, top: topPadding),
                                child: message.sender == MessageSender.ai
                                    ? AIMessage(
                                        showTypingIndicator: provider.showTypingIndicator && chatIndex == 0,
                                        message: message,
                                        sendMessage: _sendMessageUtil,
                                        displayOptions: provider.messages.length <= 1 &&
                                            provider.messageSenderApp(message.appId)?.isNotPersona() == true,
                                        appSender: provider.messageSenderApp(message.appId),
                                        updateConversation: (ServerConversation conversation) {
                                          context.read<ConversationProvider>().updateConversation(conversation);
                                        },
                                        setMessageNps: (int value) {
                                          provider.setMessageNps(message, value);
                                        },
                                      )
                                    : HumanMessage(message: message),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 10, left: 16, right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1.0,
                    ),
                  ),
                  child: Consumer<HomeProvider>(builder: (context, home, child) {
                    return Column(
                      children: [
                        Consumer<MessageProvider>(builder: (context, provider, child) {
                          return const SizedBox.shrink();
                        }),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.only(left: 16, right: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: _showVoiceRecorder
                                            ? VoiceRecorderWidget(
                                                onTranscriptReady: (transcript) {
                                                  setState(() {
                                                    textController.text = transcript;
                                                    _showVoiceRecorder = false;
                                                    context.read<MessageProvider>().setNextMessageOriginIsVoice(true);
                                                  });
                                                },
                                                onClose: () {
                                                  setState(() {
                                                    _showVoiceRecorder = false;
                                                  });
                                                },
                                              )
                                            : Container(
                                                alignment: Alignment.centerLeft,
                                                child: TextField(
                                                  enabled: true,
                                                  controller: textController,
                                                  focusNode: textFieldFocusNode,
                                                  obscureText: false,
                                                  textAlign: TextAlign.start,
                                                  textAlignVertical: TextAlignVertical.center,
                                                  decoration: const InputDecoration(
                                                    // hintText: 'Ask Anything',
                                                    // hintStyle: TextStyle(fontSize: 16.0, color: Colors.white54),
                                                    focusedBorder: InputBorder.none,
                                                    enabledBorder: InputBorder.none,
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                                    isDense: true,
                                                  ),
                                                  minLines: 1,
                                                  maxLines: 10,
                                                  keyboardType: TextInputType.multiline,
                                                  textCapitalization: TextCapitalization.sentences,
                                                  style: const TextStyle(
                                                      fontSize: 16.0, color: Color(0xFF4B5563), height: 1.4),
                                                ),
                                              ),
                                      ),
                                      if (_shouldShowVoiceRecorderButton())
                                        textController.text.isNotEmpty
                                            ? GestureDetector(
                                                onTap: () {
                                                  textController.clear();
                                                },
                                                child: Container(
                                                  height: 44,
                                                  width: 44,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF3F4F6),
                                                    borderRadius: BorderRadius.circular(22),
                                                  ),
                                                  child: const FaIcon(
                                                    FontAwesomeIcons.xmark,
                                                    color: Color(0xFF4B5563),
                                                    size: 20,
                                                  ),
                                                ),
                                              )
                                            : GestureDetector(
                                                child: Container(
                                                  height: 44,
                                                  width: 44,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF3F4F6),
                                                    borderRadius: BorderRadius.circular(22),
                                                  ),
                                                  child: const FaIcon(
                                                    FontAwesomeIcons.microphone,
                                                    color: Color(0xFF4B5563),
                                                    size: 20,
                                                  ),
                                                ),
                                                onTap: () {
                                                  FocusScope.of(context).unfocus();
                                                  setState(() {
                                                    _showVoiceRecorder = true;
                                                  });
                                                },
                                              ),
                                    ],
                                  ),
                                ),
                              ),
                              !_shouldShowSendButton(provider)
                                  ? const SizedBox.shrink()
                                  : ValueListenableBuilder<TextEditingValue>(
                                      valueListenable: textController,
                                      builder: (context, value, child) {
                                        bool canSend = value.text.trim().isNotEmpty &&
                                            !provider.sendingMessage &&
                                            !provider.isUploadingFiles &&
                                            connectivityProvider.isConnected;

                                        return GestureDetector(
                                          onTap: canSend
                                              ? () {
                                                  HapticFeedback.mediumImpact();
                                                  String message = textController.text.trim();
                                                  if (message.isEmpty) return;
                                                  _sendMessageUtil(message);
                                                }
                                              : null,
                                          child: Container(
                                            height: 44,
                                            width: 44,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF3F4F6),
                                              borderRadius: BorderRadius.circular(22),
                                            ),
                                            child: const Icon(
                                              FontAwesomeIcons.arrowUp,
                                              color: Color(0xFF4B5563),
                                              size: 20,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 没有消息时显示的Widget
  Widget _noMessagesWidget() {
    return Column(
      children: [
        const SizedBox(
          height: 16,
        ),
        Assets.images.mpChatNoMsgTopIcon.image(height: 80, width: 80),
        const Text(
          'How can I help you?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
        ),
        const SizedBox(
          height: 24,
        ),
        MPChatSuggestionCards(
          onTodayTap: () {
            _sendMessageUtil('今天我应该怎么做？');
          },
          onYesterdayTap: () {
            _sendMessageUtil('我昨天做了什么？');
          },
        ),
        const Spacer(),
        const Text(
          'Ask about anything you\'ve said or heard',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF9CA3AF)),
        ),
      ],
    );
  }

  bool _shouldShowSendButton(MessageProvider p) {
    return !p.sendingMessage && !_showVoiceRecorder;
  }

  bool _shouldShowVoiceRecorderButton() {
    return !_showVoiceRecorder;
  }

  _sendMessageUtil(String text) {
    textFieldFocusNode.unfocus();

    var provider = context.read<MessageProvider>();
    provider.setSendingMessage(true);
    provider.addMessageLocally(text);
    textController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      scrollToBottom();
    });

    provider.sendMessageStreamToServer(text);
    provider.clearSelectedFiles();
    provider.setSendingMessage(false);
  }

  sendInitialAppMessage(App? app) async {
    context.read<MessageProvider>().setSendingMessage(true);
    scrollToBottom();
    ServerMessage message = await getInitialAppMessage(app?.id);
    if (mounted) {
      context.read<MessageProvider>().addMessage(message);
      scrollToBottom();
      context.read<MessageProvider>().setSendingMessage(false);
    }
  }

  void _moveListToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  scrollToBottom() => _moveListToBottom();
}
