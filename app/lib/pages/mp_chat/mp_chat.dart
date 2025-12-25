import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:omi/backend/preferences.dart';
import 'package:omi/backend/schema/message.dart';
import 'package:omi/gen/assets.gen.dart';
import 'package:omi/pages/chat/widgets/user_message.dart';
import 'package:omi/pages/chat/widgets/voice_recorder_widget.dart';
import 'package:omi/pages/mp_chat/mp_chat_menu_list_page.dart';
import 'package:omi/providers/home_provider.dart';
import 'package:omi/providers/message_provider.dart';
import 'package:omi/providers/mp_message_provider.dart';
import 'package:provider/provider.dart';

import '../../backend/schema/conversation.dart';
import '../chat/widgets/ai_message.dart';
import 'widgets/mp_chat_appbar.dart';
import 'widgets/mp_chat_suggestion_cards.dart';

class MPChatPage extends StatefulWidget {
  /// 全局Key，用于在其他页面获取MPChatPageState
  static final GlobalKey<MPChatPageState> globalKey = GlobalKey<MPChatPageState>();

  /// 聊天页面类型
  final MPChatPageType type;

  /// 聊天ID(根据MPChatPageType不同，chatId赋值给不同的开聊id)
  final String chatId;

  /// 聊天标题
  final String title;

  MPChatPage({
    Key? key,
    this.type = MPChatPageType.normal,
    this.chatId = '',
    this.title = '',
  }) : super(key: key ?? globalKey);

  /// 获取当前MPChatPageState实例
  static MPChatPageState? getCurrentState() {
    return globalKey.currentState;
  }

  /// 获取当前MPMessageProvider实例
  static MPMessageProvider? getCurrentProvider() {
    return globalKey.currentState?.provider;
  }

  @override
  State<MPChatPage> createState() => MPChatPageState();
}

class MPChatPageState extends State<MPChatPage> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  TextEditingController textController = TextEditingController();
  late ScrollController scrollController;
  late FocusNode textFieldFocusNode;

  late MPMessageProvider provider;

  bool isScrollingDown = false;

  bool _showVoiceRecorder = false;

  var prefs = SharedPreferencesUtil();

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    provider = MPMessageProvider(chatId: widget.chatId, type: widget.type);
    provider.title = widget.title;

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
      await provider.updatePageMessages('');
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

    return ChangeNotifierProvider.value(
        value: provider,
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: Theme.of(context).colorScheme.primary,
          appBar: MPChatAppBar(
            onLeftIconTap: () => (),
            onMenuTap: () => _showMenuListPage(context),
          ),
          body: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Column(
              children: [
                // 消息列表
                Expanded(
                  child: _buildMessagesWidget(),
                ),
                _buildQuickQuestionsWidget(),
                _buildSendMessageWidget(),
              ],
            ),
          ),
        ));
  }

  // 消息列表
  Widget _buildMessagesWidget() {
    return Consumer<MPMessageProvider>(
      builder: (context, mpProvider, child) {
        return mpProvider.messages.isEmpty
            ? _noMessagesWidget()
            : ListView.builder(
                shrinkWrap: false,
                reverse: true,
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                itemCount: mpProvider.messages.length,
                itemBuilder: (context, chatIndex) {
                  final message = mpProvider.messages[chatIndex];
                  double topPadding = chatIndex == mpProvider.messages.length - 1 ? 8 : 16;

                  double bottomPadding = chatIndex == 0 ? 16 : 0;
                  return GestureDetector(
                    onLongPress: () {},
                    child: Padding(
                      key: ValueKey(message.id),
                      padding: EdgeInsets.only(bottom: bottomPadding, top: topPadding),
                      child: message.sender == MessageSender.ai
                          ? AIMessage(
                              showTypingIndicator: mpProvider.showTypingIndicator && chatIndex == 0,
                              message: message,
                              sendMessage: _sendMessageUtil,
                              displayOptions: mpProvider.messages.length <= 1,
                              appSender: null,
                              updateConversation: (ServerConversation conversation) {
                                // context.read<ConversationProvider>().updateConversation(conversation);
                                // mpProvider.updateConversation(conversation);
                              },
                              setMessageNps: (int value) {
                                // mpProvider.setMessageNps(message, value);
                              },
                            )
                          : HumanMessage(message: message),
                    ),
                  );
                },
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

  // 快速提问区域
  Widget _buildQuickQuestionsWidget() {
    List<String> questionList = [];
//     enum MPChatPageType {
//   // 普通聊天
//   normal,
//   // 记忆总结
//   memory,
//   // 模板聊天
//   template,
//   // AI分析助手
//   aiAssistant,
//   // 专家模型
//   expert,
// }
    if (widget.type == MPChatPageType.memory) {
      questionList = [
        '有哪些需要跟进的地方?',
        '和对方沟通的风险点是哪些?',
        '还有哪些没有解决的问题?',
        '下次会议需要准备什么材料?',
      ];
    } else if (widget.type == MPChatPageType.expert) {
      questionList = [
        '帮我总结一下近半年我们的沟通情况',
        '我们讨论的最重要三个话题',
        '前几次讨论我们还有没有没解决的问题',
      ];
    }
    // else {
    //   questionList = [
    //     '今天我应该怎么做？',
    //     '我昨天做了什么？',
    //     '最近有什么重要事项？',
    //     '帮我总结一下',
    //   ];
    // }
    if (questionList.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: questionList.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(right: index < questionList.length - 1 ? 12 : 0),
            child: GestureDetector(
              onTap: () {
                _sendMessageUtil(questionList[index]);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: Text(
                    questionList[index],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 发送消息区域
  Widget _buildSendMessageWidget() {
    return Container(
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
        return Consumer<MPMessageProvider>(builder: (context, mpProvider, child) {
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
                                          hintText: 'Ask Anything',
                                          hintStyle: TextStyle(fontSize: 16.0, color: Colors.white54),
                                          focusedBorder: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                          isDense: true,
                                        ),
                                        minLines: 1,
                                        maxLines: 10,
                                        keyboardType: TextInputType.multiline,
                                        textCapitalization: TextCapitalization.sentences,
                                        style: const TextStyle(fontSize: 16.0, color: Color(0xFF4B5563), height: 1.4),
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
                    !_shouldShowSendButton(mpProvider)
                        ? const SizedBox.shrink()
                        : ValueListenableBuilder<TextEditingValue>(
                            valueListenable: textController,
                            builder: (context, value, child) {
                              bool canSend = value.text.trim().isNotEmpty && !mpProvider.sendingMessage;
                              // !mpProvider.isUploadingFiles;
                              print(
                                  '----------- canSend: $canSend -------------- textController.text: ${textController.text} -------------- mpProvider.sendingMessage: ${mpProvider.sendingMessage}');
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
        });
      }),
    );
  }

  bool _shouldShowSendButton(MPMessageProvider p) {
    return !p.sendingMessage && !_showVoiceRecorder;
  }

  bool _shouldShowVoiceRecorderButton() {
    return !_showVoiceRecorder;
  }

  _sendMessageUtil(String text) {
    textFieldFocusNode.unfocus();

    // 直接使用已创建的 provider 实例，避免 context 作用域问题
    provider.setSendingMessage(true);
    provider.addMessageLocally(text);
    textController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      scrollToBottom();
    });

    provider.sendMessageStreamToServer(text);
    // provider.clearSelectedFiles();
    provider.setSendingMessage(false);
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

  // show menu list page
  void _showMenuListPage(BuildContext context) {
    MPChatMenuListPage.show(
      context,
      newChatCallback: () {
        provider.resetPageInfo();
        provider.createConversationIfNeeded();
      },
      dailyInsightCallback: (String str) async {
        await provider.updatePageInfo(str, MPChatPageType.memory);
      },
      peopleMemoryCallback: (String str) async {
        await provider.updatePageInfo(str, MPChatPageType.memory);
      },
      conversationCallback: (String str) async {
        await provider.updatePageMessages(str);
      },
    );
  }
}
