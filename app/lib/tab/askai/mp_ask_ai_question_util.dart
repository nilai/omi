import '../../cache/mp_hive_util.dart';
import '../../http/api/mp_chat.dart';
import '../../http/schema/mp_chat.dart';

/// Ask AI 问题工具类：
/// 1. 从后端拉取建议问题并缓存到 Hive
/// 2. 从 Hive 读取所有问题，空数据时回退默认问题
class MPAskAIQuestionUtil {
  MPAskAIQuestionUtil._();

  static const String _kQuestionsCacheKey = 'ask_ai_question_modules_v1';

  /// 从后台接口获取问题并写入 Hive。
  ///
  /// @returns {Future<void>}
  static Future<void> fetchQuestionsAndCache() async {
    try {
      final MPGetChatSuggestionCardsResponse? response =
          await getChatSuggestionCards(MPGetChatSuggestionCardRequest());
      if (response == null || response.baseResp.code != 0) {
        return;
      }
      final List<MPChatSuggestionCard> cards = response.suggestion
          .where(
            (MPChatSuggestionCard e) =>
                e.title.trim().isNotEmpty && e.suggestions.isNotEmpty,
          )
          .toList(growable: false);
      if (cards.isEmpty) {
        return;
      }
      await MPHiveUtil.instance.putPrimitive(
        key: _kQuestionsCacheKey,
        value: _cardsToCache(cards),
      );
    } catch (_) {
      return;
    }
  }

  /// 从 Hive 获取问题模块。
  ///
  /// @returns {Future<List<MPChatSuggestionCard>>} 缓存有效时返回缓存；空或无效时返回默认问题。
  static Future<List<MPChatSuggestionCard>> getAllQuestionsFromHive() async {
    final List<dynamic>? cached = await MPHiveUtil.instance
        .getPrimitive<List<dynamic>>(_kQuestionsCacheKey);
    final List<MPChatSuggestionCard> fromCache = _cacheToCards(cached);
    if (fromCache.isNotEmpty) {
      return fromCache;
    }
    return _defaultCards;
  }

  static List<Map<String, dynamic>> _cardsToCache(
    List<MPChatSuggestionCard> cards,
  ) {
    return cards
        .map(
          (MPChatSuggestionCard card) => <String, dynamic>{
            'title': card.title,
            'subtitle': card.subtitle,
            'content': card.content,
            'detail': card.detail,
            'suggestions': card.suggestions,
          },
        )
        .toList(growable: false);
  }

  static List<MPChatSuggestionCard> _cacheToCards(List<dynamic>? cached) {
    if (cached == null || cached.isEmpty) {
      return const <MPChatSuggestionCard>[];
    }
    final List<MPChatSuggestionCard> cards = <MPChatSuggestionCard>[];
    for (final dynamic raw in cached) {
      if (raw is! Map) {
        continue;
      }
      final Map<String, dynamic> item = Map<String, dynamic>.from(raw);
      final String title = (item['title'] ?? '').toString().trim();
      final String subtitle = (item['subtitle'] ?? '').toString().trim();
      final String content = (item['content'] ?? '').toString().trim();
      final String detail = (item['detail'] ?? '').toString().trim();
      final List<String> suggestions = _parseSuggestions(item['suggestions']);
      if (title.isEmpty || suggestions.isEmpty) {
        continue;
      }
      cards.add(
        MPChatSuggestionCard(
          title: title,
          subtitle: subtitle,
          content: content,
          detail: detail,
          suggestions: suggestions,
        ),
      );
    }
    return cards;
  }

  static List<String> _parseSuggestions(dynamic raw) {
    if (raw is List) {
      return raw
          .map((dynamic e) => e.toString().trim())
          .where((String e) => e.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  static final List<MPChatSuggestionCard> _defaultCards =
      <MPChatSuggestionCard>[
    MPChatSuggestionCard(
      title: 'Recall recent context',
      subtitle: 'Remember what you\'ve been discussing',
      content: '',
      detail: '',
      suggestions: <String>[
        'What have I been working on recently?',
        'What decisions did I make this week?',
        'Who have I been talking with most?',
        'What unresolved threads should I revisit?',
      ],
    ),
    MPChatSuggestionCard(
      title: 'Connect patterns & signals',
      subtitle: 'See connections across conversations',
      content: '',
      detail: '',
      suggestions: <String>[
        'What recurring concerns keep showing up?',
        'Which topics tend to appear together?',
        'Are there any strong positive patterns lately?',
        'What signals suggest burnout risk?',
        'What habits correlate with productive days?',
      ],
    ),
    MPChatSuggestionCard(
      title: 'Decide what matters next',
      subtitle: 'Figure out what deserves attention now',
      content: '',
      detail: '',
      suggestions: <String>[
        'What is the highest-leverage thing to do today?',
        'What should I delay or drop for now?',
        'Which conversations need follow-up first?',
        'What can I finish in under 30 minutes?',
      ],
    ),
  ];
}
