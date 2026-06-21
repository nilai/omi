import 'package:flutter/material.dart';

import '../../http/api/mp_chat.dart';
import '../../http/api/mp_insight.dart';
import '../../http/schema/mp_chat.dart';
import '../../http/schema/mp_insight.dart';
import '../../main.dart';
import '../../utils/mp_toast_utils.dart';
import 'mp_ask_ai_chat_page.dart';

export 'mp_ask_ai_chat_page.dart' show MPAskAIChatType;

/// Ask AI 聊天页打开参数。
class MPAskAIChatOpenParams {
  const MPAskAIChatOpenParams({
    required this.aboutText,
    required this.conversationType,
    this.paramId = '',
    this.type = MPAskAIChatType.normal,
    this.chatTypeId,
    this.initialMessage,
    this.fetchSuggestions = false,
  });

  final String aboutText;
  final int conversationType;
  final String paramId;
  final MPAskAIChatType type;
  final String? chatTypeId;
  final String? initialMessage;

  /// Insight 场景为 true 时，并发拉取建议问题与最近会话。
  final bool fetchSuggestions;
}

/// Ask AI 聊天页统一导航入口，防止 API 等待期间重复打开。
class MPAskAIChatNavigationHelper {
  MPAskAIChatNavigationHelper._();

  static bool _isOpening = false;

  /// 是否正在打开聊天页。
  static bool get isOpening => _isOpening;

  /// 拉取会话信息并跳转 Ask AI 聊天页。
  static Future<void> open(BuildContext context, MPAskAIChatOpenParams params) async {
    if (_isOpening) {
      return;
    }
    _isOpening = true;
    try {
      List<String> suggestedQuestions = const <String>[];
      String conversationId = '';

      if (params.fetchSuggestions) {
        final String insightId = params.paramId.trim();
        if (insightId.isEmpty) {
          return;
        }
        final List<dynamic> responses = await Future.wait<dynamic>(<Future<dynamic>>[
          getInsightSuggestion(MPGetInsightSuggestionRequest(insightId: insightId)),
          getLastConversation(
            MPGetLastConversationRequest(
              conversationType: params.conversationType,
              paramId: params.paramId,
            ),
          ),
        ]);
        final MPGetInsightSuggestionResponse? suggestionResp =
            responses[0] as MPGetInsightSuggestionResponse?;
        final MPGetLastConversationResponse? lastConversationResp =
            responses[1] as MPGetLastConversationResponse?;

        if (suggestionResp == null) {
          MPToastUtils.showMessage('Ask AI failed');
          return;
        }
        suggestedQuestions = suggestionResp.suggestion;
        conversationId = lastConversationResp?.conversationId ?? '';
      } else {
        final MPGetLastConversationResponse? lastConversation = await getLastConversation(
          MPGetLastConversationRequest(
            conversationType: params.conversationType,
            paramId: params.paramId,
          ),
        );
        conversationId = lastConversation?.conversationId ?? '';
      }

      final BuildContext? targetContext =
          context.mounted ? context : MyApp.navigatorKey.currentContext;
      if (targetContext == null || !targetContext.mounted) {
        return;
      }

      // ignore: use_build_context_synchronously
      await Navigator.of(targetContext).push(
        MaterialPageRoute<void>(
          builder: (_) => MPAskAIChatPage(
            aboutText: params.aboutText,
            suggestedQuestions: suggestedQuestions,
            conversationId: conversationId,
            initialMessage: params.initialMessage,
            type: params.type,
            chatTypeId: params.chatTypeId,
          ),
        ),
      );
    } finally {
      _isOpening = false;
    }
  }
}
