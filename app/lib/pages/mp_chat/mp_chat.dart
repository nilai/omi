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
import 'package:omi/pages/mp_chat/mp_chat_quick_question_util.dart';
import 'package:omi/providers/home_provider.dart';
import 'package:omi/providers/message_provider.dart';
import 'package:omi/providers/mp_message_provider.dart';
import 'package:provider/provider.dart';

import '../../backend/schema/conversation.dart';
import '../chat/widgets/ai_message.dart';
import '../home/widgets/mp_battery_info_widget.dart';
import '../mp_memory/conversation_detail/conversation_detail_page.dart';
import 'mp_chat_helper.dart';
import 'widgets/mp_chat_appbar.dart';
import 'widgets/mp_chat_memory_card.dart';
import 'widgets/mp_chat_question_list_widget.dart';
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

  /// 聊天栏左侧图标类型
  final MPChatBarLeadingType leadingType;

  MPChatPage({
    Key? key,
    this.type = MPChatPageType.normal,
    this.chatId = '',
    this.title = '',
    this.leadingType = MPChatBarLeadingType.battery,
  }) : super(key: key ?? globalKey);

  /// 获取当前MPChatPageState实例
  static MPChatPageState? getCurrentState() {
    return MPChatPageState.currentInstance;
  }

  /// 获取当前MPMessageProvider实例
  /// 如果页面已加载，返回页面的 provider
  /// 如果页面未加载，返回或创建一个静态的 provider 实例（延迟初始化）
  static MPMessageProvider getCurrentProvider() {
    // 优先返回页面已加载的 provider
    if (MPChatPageState.currentInstance != null) {
      return MPChatPageState.currentInstance!.provider;
    }
    // 如果页面未加载，返回静态的 provider（延迟初始化）
    return MPChatPageState._getOrCreateStaticProvider;
  }

  @override
  State<MPChatPage> createState() => MPChatPageState();

  static void openChatPage(BuildContext context,
      {String chatId = '', String title = '', MPChatPageType type = MPChatPageType.normal}) {
    // 切换到第3个tab（AI助理，索引为2）
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    homeProvider.setIndex(2);

    // 返回到主页
    Navigator.of(context).popUntil((route) => route.isFirst);

    final messageProvider = MPChatPage.getCurrentProvider();
    messageProvider.updatePageInfo(chatId: chatId, type: type, title: title);
  }
}

class MPChatPageState extends State<MPChatPage> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  /// 当前活跃的 MPChatPageState 实例的静态引用
  static MPChatPageState? _currentInstance;

  /// 获取当前活跃的实例（用于外部访问）
  static MPChatPageState? get currentInstance => _currentInstance;

  /// 静态的 provider 实例，用于在页面未加载时也能访问
  static MPMessageProvider? _staticProvider;

  /// 获取静态 provider 实例（延迟初始化）
  static MPMessageProvider get _getOrCreateStaticProvider {
    _staticProvider ??= MPMessageProvider();
    return _staticProvider!;
  }

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

  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    // 注册当前实例
    _currentInstance = this;

    // 如果静态 provider 存在，复用它的数据（如 pageModels）
    if (_staticProvider != null) {
      debugPrint('-----hj----- initState: reuse static provider');
      provider = _staticProvider!;
      // 清除静态引用，因为现在由页面实例管理
      _staticProvider = null;
    } else {
      debugPrint('-----hj----- initState: create new provider');
      provider = MPMessageProvider();
    }

    _isInit = true;

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
      if (!_isInit) {
        return;
      }
      _isInit = false;
      await provider.updatePageInfo(chatId: widget.chatId, type: widget.type, title: widget.title);
      scrollToBottom();
    });
  }

  @override
  void dispose() {
    // 如果当前实例是 this，则清除引用
    if (_currentInstance == this) {
      _currentInstance = null;
      // 将 provider 保存到静态引用，以便页面销毁后仍能访问
      _staticProvider = provider;
    }
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
          backgroundColor: Colors.white,
          appBar: MPChatAppBar(
            onLeftIconTap: () {
              _onLeftIconTap();
            },
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
                _buildCustomCardWidget(),
                // _buildQuickQuestionsWidget(),
                _buildSendMessageWidget(),
              ],
            ),
          ),
        ));
  }

  void _onLeftIconTap() async {
    if (provider.leadingType == MPChatBarLeadingType.cancel) {
      provider.setLeadingType(MPChatBarLeadingType.battery);
      provider.setQuestionType(MPChatQuestionType.grid);
      final list = await MPQuickQuestionUtil().getQuestionsByChatType(MPChatPageType.normal);
      provider.setQuestions(list);
      return;
    }
    if (provider.leadingType == MPChatBarLeadingType.battery) {
      MPBatteryInfoWidget.pushToFindDevicesPage(context);
      return;
    }
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
                              displayOptions: false,
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
    final type = provider.curPageModel?.type ?? widget.type;

    switch (type) {
      case MPChatPageType.normal:
        return _buildNormalNoMessagesWidget();
      case MPChatPageType.expert:
        return _buildExpertNoMessagesWidget();
      case MPChatPageType.memory:
        return _buildMemoryNoMessagesWidget();
      case MPChatPageType.template:
        return _buildTemplateNoMessagesWidget();
      case MPChatPageType.speaker:
        return _buildSpeakerNoMessagesWidget();
    }
  }

  /// 普通聊天类型的空消息Widget
  Widget _buildNormalNoMessagesWidget() {
    List<Widget> buildQuestionWidget(MPMessageProvider provider) {
      if (provider.questionType == MPChatQuestionType.grid) {
        return [
          MPChatSuggestionCards(
            questions: provider.questions,
            onQuestionTap: (question) {
              final list = MPQuickQuestionUtil().getQuestionsByKey(question);
              if (list.isEmpty) {
                _sendMessageUtil(question);
              } else {
                provider.setQuestions(list);
                provider.setLeadingType(MPChatBarLeadingType.cancel);
                provider.setQuestionType(MPChatQuestionType.list);
              }
            },
          ),
          const Spacer()
        ];
      }
      return [
        Expanded(
          child: MPChatQuestionListWidget(
            questions: provider.questions,
            onQuestionTap: (question) {
              final list = MPQuickQuestionUtil().getQuestionsByKey(question);
              if (list.isEmpty) {
                _sendMessageUtil(question);
              } else {
                provider.setQuestions(list);
                provider.setLeadingType(MPChatBarLeadingType.cancel);
                provider.setQuestionType(MPChatQuestionType.list);
              }
            },
          ),
        ),
      ];
    }

    return Consumer<MPMessageProvider>(
      builder: (context, mpProvider, child) {
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
            ...buildQuestionWidget(mpProvider),
            const Text(
              'Ask about anything you\'ve said or heard',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF9CA3AF)),
            ),
          ],
        );
      },
    );
  }

  /// 专家类型的空消息Widget
  Widget _buildExpertNoMessagesWidget() {
    return _buildCommonNoMessagesWidget('基于专家提问');
  }

  Widget _buildCommonNoMessagesWidget(String title) {
    return Consumer<MPMessageProvider>(
      builder: (context, mpProvider, child) {
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
            Expanded(
              child: MPChatQuestionListWidget(
                questions: provider.questions,
                onQuestionTap: (question) {
                  _sendMessageUtil(question);
                },
              ),
            ),
            const Text(
              'Ask about anything you\'ve said or heard',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF9CA3AF)),
            ),
          ],
        );
      },
    );
  }

  /// 记忆类型的空消息Widget
  Widget _buildMemoryNoMessagesWidget() {
    return _buildCommonNoMessagesWidget('基于记忆提问');
  }

  /// 模板类型的空消息Widget
  Widget _buildTemplateNoMessagesWidget() {
    return _buildCommonNoMessagesWidget('基于模版提问');
  }

  /// 人物类型的空消息Widget
  Widget _buildSpeakerNoMessagesWidget() {
    return _buildCommonNoMessagesWidget('基于人物提问');
  }

  // 自定义卡片区域
  Widget _buildCustomCardWidget() {
    return Consumer<MPMessageProvider>(
      builder: (context, mpProvider, child) {
        if (!mpProvider.showCustomCard) {
          return const SizedBox.shrink();
        }
        final type = mpProvider.curPageModel?.type;
        if (type == null) {
          return const SizedBox.shrink();
        }
        switch (type) {
          case MPChatPageType.memory:
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: MPChatMemoryCard(
                onCloseTap: () {
                  mpProvider.setShowCustomCard(false);
                },
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ConversationDetailPage(memory: MPChatHelper.instance.memory!)));
                },
              ),
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  // 快速提问区域
  // Widget _buildQuickQuestionsWidget() {
  //   return Consumer<MPMessageProvider>(
  //     builder: (context, mpProvider, child) {
  //       final questionList = mpProvider.questions;
  //       print(
  //           '-----hj----- _buildQuickQuestionsWidget: questionList: $questionList --- type: ${mpProvider.curPageModel?.type}');
  //       if (questionList.isEmpty || mpProvider.curPageModel?.type == MPChatPageType.normal) {
  //         return const SizedBox.shrink();
  //       }
  //       return Container(
  //         height: 40,
  //         margin: const EdgeInsets.symmetric(vertical: 8),
  //         child: ListView.builder(
  //           scrollDirection: Axis.horizontal,
  //           padding: const EdgeInsets.symmetric(horizontal: 16),
  //           itemCount: questionList.length,
  //           itemBuilder: (context, index) {
  //             return Container(
  //               margin: EdgeInsets.only(right: index < questionList.length - 1 ? 12 : 0),
  //               child: GestureDetector(
  //                 onTap: () {
  //                   _sendMessageUtil(questionList[index]);
  //                 },
  //                 child: Container(
  //                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  //                   decoration: BoxDecoration(
  //                     color: Colors.white,
  //                     borderRadius: BorderRadius.circular(20),
  //                     border: Border.all(
  //                       color: const Color(0xFFE5E7EB),
  //                       width: 1.0,
  //                     ),
  //                   ),
  //                   child: Center(
  //                     child: Text(
  //                       questionList[index],
  //                       style: const TextStyle(
  //                         fontSize: 14,
  //                         color: Color(0xFF4B5563),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             );
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }

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
                                        cursorColor: Colors.black,
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
    provider.setSendingMessage(false);
    provider.setLeadingType(MPChatBarLeadingType.battery);
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
        await provider.updatePageInfo(chatId: str, type: MPChatPageType.memory);
      },
      peopleMemoryCallback: (String str) async {
        await provider.updatePageInfo(chatId: str, type: MPChatPageType.memory);
      },
      conversationCallback: (String str) async {
        await provider.updatePageMessages(str);
      },
    );
  }
}
