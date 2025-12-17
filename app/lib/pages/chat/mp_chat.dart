import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pull_down_button/pull_down_button.dart';
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
import 'package:omi/pages/home/page.dart';
import 'package:omi/providers/connectivity_provider.dart';
import 'package:omi/providers/home_provider.dart';
import 'package:omi/providers/conversation_provider.dart';
import 'package:omi/providers/message_provider.dart';
import 'package:omi/providers/app_provider.dart';
import 'package:omi/utils/alerts/app_snackbar.dart';
import 'package:omi/utils/analytics/mixpanel.dart';
import 'package:omi/utils/other/temp.dart';
import 'package:omi/widgets/dialog.dart';
import 'package:omi/widgets/extensions/string.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'widgets/message_action_menu.dart';
import 'widgets/mp_chat_appbar.dart';

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
  final bool isPivotBottom;

  const MPChatPage({
    super.key,
    this.isPivotBottom = false,
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
  bool _isInitialLoad = true;

  var prefs = SharedPreferencesUtil();
  late List<App> apps;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _appButtonKey = GlobalKey();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    apps = prefs.appsList;
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
      // if (_isInitialLoad) {
      //   Future.delayed(const Duration(milliseconds: 300), () {
      //     if (mounted && !_showVoiceRecorder && _isInitialLoad) {
      //       textFieldFocusNode.requestFocus();
      //     }
      //   });
      // }
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
                  child: provider.isLoadingMessages && !provider.hasCachedMessages
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              provider.firstTimeLoadingText,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        )
                      : provider.isClearingChat
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Deleting your messages from Omi's memory...",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            )
                          : (provider.messages.isEmpty)
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 32.0),
                                    child: Text(
                                        connectivityProvider.isConnected
                                            ? 'No messages yet!\nWhy don\'t you start a conversation?'
                                            : 'Please check your internet connection and try again',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white)),
                                  ),
                                )
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
                                              MixpanelManager().track('Chat Message Text Selected',
                                                  properties: {'message': message.text});
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
                  decoration:  BoxDecoration(
                    color: Colors.white,
                    borderRadius:  BorderRadius.circular(22),
                    border: Border.all(
                      color:const Color(0xFFE5E7EB),
                      width: 1.0,
                    ),
                  ),
                  child: Consumer<HomeProvider>(builder: (context, home, child) {
                    bool shouldShowSendButton(MessageProvider p) {
                      return !p.sendingMessage && !_showVoiceRecorder;
                    }

                    bool shouldShowVoiceRecorderButton() {
                      return !_showVoiceRecorder;
                    }

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
                                                  style:
                                                      const TextStyle(fontSize: 16.0, color: Color(0xFF4B5563), height: 1.4),
                                                ),
                                              ),
                                      ),
                                      if (shouldShowVoiceRecorderButton())
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
                              !shouldShowSendButton(provider)
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
                                              color:  Color(0xFF4B5563),
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

  void _handleAppSelection(String? val, AppProvider provider) {
    if (val == null || val == provider.selectedChatAppId) {
      return;
    }

    textFieldFocusNode.unfocus();

    if (val == 'clear_chat') {
      _showClearChatDialog();
      return;
    }

    if (val == 'enable') {
      _navigateToAppsPage();
      return;
    }

    _selectApp(val, provider);
  }

  void _showClearChatDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return getDialog(context, () {
          Navigator.of(context).pop();
        }, () {
          if (mounted) {
            context.read<MessageProvider>().clearChat();
            Navigator.of(context).pop();
          }
        }, "Clear Chat?", "Are you sure you want to clear the chat? This action cannot be undone.");
      },
    );
  }

  void _navigateToAppsPage() {
    if (!mounted) return;

    MixpanelManager().pageOpened('Chat Apps');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomePageWrapper(navigateToRoute: '/apps'),
      ),
    );
  }

  void _selectApp(String appId, AppProvider appProvider) async {
    if (!mounted) return;

    _isInitialLoad = false;

    final messageProvider = mounted ? context.read<MessageProvider>() : null;
    if (messageProvider == null) return;

    appProvider.setSelectedChatAppId(appId);

    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    await messageProvider.refreshMessages(dropdownSelected: true);

    if (!mounted) return;

    var app = appProvider.getSelectedApp();
    if (messageProvider.messages.isEmpty) {
      messageProvider.sendInitialAppMessage(app);
    }
  }

  void _showAppsMenu(BuildContext ctx, AppProvider appProvider) {
    final renderBox = _appButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(ctx, rootOverlay: true);

    final buttonOffset = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;
    final screenSize = MediaQuery.of(ctx).size;

    const double menuWidth = 260;
    const double maxMenuHeight = 250;

    double desiredTop = buttonOffset.dy + buttonSize.height + 8;
    if ((desiredTop + maxMenuHeight) > screenSize.height) {
      desiredTop = buttonOffset.dy - maxMenuHeight - 8;
      if (desiredTop < 0) desiredTop = 8;
    }

    late OverlayEntry entry;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    final curved = CurvedAnimation(parent: controller, curve: Curves.easeOut);

    entry = OverlayEntry(
      builder: (context) {
        return Consumer<MessageProvider>(
          builder: (context, msgProvider, _) {
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      controller.reverse().then((_) => entry.remove());
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Positioned(
                  left: buttonOffset.dx + (buttonSize.width - menuWidth) / 2,
                  top: desiredTop,
                  child: AnimatedBuilder(
                    animation: curved,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: curved.value,
                        alignment: Alignment.topCenter,
                        child: Opacity(
                          opacity: curved.value,
                          child: child,
                        ),
                      );
                    },
                    child: Material(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      elevation: 8,
                      child: SizedBox(
                        width: menuWidth,
                        height: maxMenuHeight,
                        child: PullDownMenu(
                          items: [
                            PullDownMenuItem(
                              title: 'Clear Chat',
                              iconWidget: const Icon(Icons.delete, color: Colors.redAccent, size: 16),
                              onTap: () {
                                controller.reverse().then((_) {
                                  entry.remove();
                                  _handleAppSelection('clear_chat', appProvider);
                                });
                              },
                            ),
                            PullDownMenuItem(
                              title: 'Enable Apps',
                              iconWidget: const Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 16),
                              onTap: () {
                                controller.reverse().then((_) {
                                  entry.remove();
                                  _handleAppSelection('enable', appProvider);
                                });
                              },
                            ),
                            PullDownMenuItem(
                              title: 'Omi',
                              iconWidget: _getOmiAvatar(),
                              onTap: () {
                                controller.reverse().then((_) {
                                  entry.remove();
                                  _handleAppSelection('no_selected', appProvider);
                                });
                              },
                              subtitle:
                                  msgProvider.chatApps.firstWhereOrNull((a) => a.id == appProvider.selectedChatAppId) ==
                                          null
                                      ? 'Selected'
                                      : null,
                            ),
                            ...msgProvider.chatApps.map(
                              (app) => PullDownMenuItem(
                                title: app.getName(),
                                iconWidget: _getAppAvatar(app),
                                onTap: () {
                                  controller.reverse().then((_) {
                                    entry.remove();
                                    _handleAppSelection(app.id, appProvider);
                                  });
                                },
                                subtitle: appProvider.selectedChatAppId == app.id ? 'Selected' : null,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    overlay.insert(entry);
    controller.forward();
  }

  Widget _getAppAvatar(App app) {
    return CachedNetworkImage(
      imageUrl: app.getImageUrl(),
      imageBuilder: (context, imageProvider) {
        return CircleAvatar(
          backgroundColor: Colors.white,
          radius: 12,
          backgroundImage: imageProvider,
        );
      },
      errorWidget: (context, url, error) {
        return const CircleAvatar(
          backgroundColor: Colors.white,
          radius: 12,
          child: Icon(Icons.error_outline_rounded),
        );
      },
      progressIndicatorBuilder: (context, url, progress) => CircleAvatar(
        backgroundColor: Colors.white,
        radius: 12,
        child: CircularProgressIndicator(
          value: progress.progress,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _getOmiAvatar() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(Assets.images.background.path),
          fit: BoxFit.cover,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
      ),
      height: 24,
      width: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            Assets.images.herologo.path,
            height: 16,
            width: 16,
          ),
        ],
      ),
    );
  }

  void _showIOSStyleActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(
                  children: [
                    _buildIOSActionItem(
                      title: "Take Photo",
                      icon: Icons.camera_alt,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.pop(context);
                        if (mounted) {
                          context.read<MessageProvider>().captureImage();
                        }
                      },
                      isFirst: true,
                    ),
                    _buildDivider(),
                    _buildIOSActionItem(
                      title: "Photo Library",
                      icon: Icons.photo_library,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.pop(context);
                        if (mounted) {
                          context.read<MessageProvider>().selectImage();
                        }
                      },
                    ),
                    _buildDivider(),
                    _buildIOSActionItem(
                      title: "Choose File",
                      icon: Icons.folder,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.pop(context);
                        if (mounted) {
                          context.read<MessageProvider>().selectFile();
                        }
                      },
                      isLast: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIOSActionItem({
    required String title,
    required VoidCallback onTap,
    IconData? icon,
    bool isFirst = false,
    bool isLast = false,
    bool isCancel = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(13) : Radius.zero,
          bottom: isLast ? const Radius.circular(13) : Radius.zero,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isCancel ? Colors.red : Colors.blue,
                    fontSize: 20,
                    fontWeight: isCancel ? FontWeight.w600 : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (icon != null && !isCancel)
                Icon(
                  icon,
                  color: Colors.grey.shade600,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      color: Colors.grey.shade700,
      margin: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
