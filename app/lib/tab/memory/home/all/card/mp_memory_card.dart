import 'package:flutter/material.dart';
import 'package:memo_pin/http/schema/mp_data_model.dart';
import 'package:memo_pin/utils/omi_image_loader.dart';

import '../../../../../generated/assets.dart';
import '../../../../../utils/omi_color_utils.dart';
import '../../../../../utils/omi_font_utils.dart';
import '../../../../../utils/omi_textstyle.dart';

import 'mp_audio_recording_card.dart';
import 'mp_memo_group_card.dart';

/// 列表行类型：会话卡片 / Memos 分组 / 录音记忆卡片
enum MPMemoryEntryKind {
  /// [MPMemoryCard]
  conversation,

  /// [MPMemoGroupCard]
  memoGroup,

  /// [MPAudioRecordingCard]
  audioRecording,
}

/// 会话型列表项子类型（服务端 summary / memoryFeed），决定详情页形态与导航。
enum MPMemoryConversationKind {
  summary,
  memoryFeed,
}

/// Memory 列表卡片三种展示形态（对应设计稿）
enum MPMemoryCardVariant {
  /// 有新更新：左侧紫色竖条、角标、「New updates」状态文案，底部 Audio / Summary / Activity
  newUpdates,

  /// 常规：白底描边，无角标与状态条，底部三项齐全
  standard,

  /// 精简：浅灰底，底部仅 Audio / Summary
  compact,
}

/// 单条 Memory 卡片数据
class MPMemoryCardData {
  const MPMemoryCardData({
    required this.title,
    required this.timeLabel,
    required this.preview,
    required this.createAt,
    this.badgeCount,
    this.statusLabel,
    this.showActivity,
  });

  final String title;
  final String timeLabel;
  final String preview;
  final int createAt;

  /// [MPMemoryCardVariant.newUpdates] 时右上角数字角标；为 `null` 不展示
  final int? badgeCount;

  /// [MPMemoryCardVariant.newUpdates] 时与时间之间的紫色状态文案，如 `New updates`
  final String? statusLabel;

  /// 底部是否展示 Activity；`null` 时由 [MPMemoryCard] 按 [MPMemoryCardVariant] 决定（compact 不展示）。
  final bool? showActivity;
}

/// Cubit / 列表行：会话、Memos 分组或录音记忆卡片
///
/// [id] 用于游标分页（下一页请求携带上页最后一条 id，与 [MemoryProvider] 一致）
class MPMemoryEntry {
  const MPMemoryEntry.conversation({
    required this.id,
    required this.conversationKind,
    required this.variant,
    required this.data,
    required this.type,
  })  : kind = MPMemoryEntryKind.conversation,
        memoVariant = null,
        memoData = null,
        audioData = null;

  const MPMemoryEntry.memoGroup({
    required this.id,
    required this.memoVariant,
    required this.memoData,
    required this.type,
  })  : kind = MPMemoryEntryKind.memoGroup,
        variant = null,
        data = null,
        audioData = null,
        conversationKind = null;

  const MPMemoryEntry.audioRecording({
    required this.id,
    required this.type,
    required this.audioData,
  })  : kind = MPMemoryEntryKind.audioRecording,
        variant = null,
        data = null,
        memoVariant = null,
        memoData = null,
        conversationKind = null;

  /// 业务唯一 id，作为服务端 cursor 传递
  final String id;

  final MPMemoryEntryKind kind;

  final MPMemoryType type;

  /// [kind] 为 [MPMemoryEntryKind.conversation] 时使用（服务端 summary / memoryFeed）。
  final MPMemoryConversationKind? conversationKind;

  /// [kind] 为 [MPMemoryEntryKind.conversation] 时使用
  final MPMemoryCardVariant? variant;
  final MPMemoryCardData? data;

  /// [kind] 为 [MPMemoryEntryKind.memoGroup] 时使用
  final MPMemoGroupCardVariant? memoVariant;
  final MPMemoGroupCardData? memoData;

  /// [kind] 为 [MPMemoryEntryKind.audioRecording] 时使用
  final MPAudioRecordingCardData? audioData;
}

/// 设计色（与设计稿对齐，可按主题再抽）
const Color _kBody = Color(0xFF555555);
const Color _kFooter = Color(0xFF6B6B6B);
const Color _kCompactBg = Color(0xFFF8F8F6);

/// Memory 列表卡片
class MPMemoryCard extends StatelessWidget {
  const MPMemoryCard({
    super.key,
    required this.variant,
    required this.data,
    this.onTap,
  });

  final MPMemoryCardVariant variant;
  final MPMemoryCardData data;
  final VoidCallback? onTap;

  bool get _showLeftAccent =>
      variant == MPMemoryCardVariant.newUpdates;

  bool get _showBadgeAndStatus =>
      variant == MPMemoryCardVariant.newUpdates;

  bool get _showActivity =>
      data.showActivity ?? false;

  Color get _cardBg =>
      variant == MPMemoryCardVariant.compact ? _kCompactBg : Colors.white;

  @override
  Widget build(BuildContext context) {
    final bool showUnreadBadge =
        data.badgeCount != null && data.badgeCount! > 0;

    final Widget content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showUnreadBadge)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OmiTextStyle.create(
                      fontSize: 16,
                      fontWeight: OmiFontWeight.medium,
                      color: mainTextColor,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _Badge(count: data.badgeCount!),
              ],
            )
          else
            Text(
              data.title,
              style: OmiTextStyle.create(
                fontSize: 16,
                fontWeight: OmiFontWeight.medium,
                color: mainTextColor,
                height: 1.2,
              ),
            ),
          const SizedBox(height: 8),
          if (_showBadgeAndStatus && data.statusLabel != null) ...[
            Row(
              children: [
                Text(
                  data.timeLabel,
                  style: OmiTextStyle.create(fontSize: 12, color: secondTextColor, fontWeight: OmiFontWeight.regular),
                ),
                Text(' · ', style: OmiTextStyle.create(color: secondTextColor, fontWeight: OmiFontWeight.regular)),
                Text(
                  data.statusLabel!,
                  style: OmiTextStyle.create(
                    fontSize: 12,
                    fontWeight: OmiFontWeight.medium,
                    color: purpleTextColor,
                  ),
                ),
              ],
            ),
          ] else
            Text(
              data.timeLabel,
              style: OmiTextStyle.create(fontSize: 12, color: secondTextColor, fontWeight: OmiFontWeight.regular),
            ),
          const SizedBox(height: 8),
          Text(
            data.preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: OmiTextStyle.create(
              fontSize: 13,
              height: 1.25,
              color: _kBody,
              fontWeight: OmiFontWeight.regular,
            ),
          ),
          const SizedBox(height: 14),
          _Footer(showActivity: _showActivity),
        ],
      ),
    );

    final Widget inner = _showLeftAccent
        ? IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: purpleTextColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(child: content),
              ],
            ),
          )
        : content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: inner,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: purpleTextColor,
        shape: BoxShape.circle,
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: OmiTextStyle.create(
          color: Colors.white,
          fontSize: 11,
          fontWeight: OmiFontWeight.medium,
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.showActivity});

  final bool showActivity;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FooterChip(icon: OmiImageLoader.localImg(Assets.omiAudio,width: 16, height: 16, color: _kFooter), label: 'Audio'),
        const SizedBox(width: 20),
        _FooterChip(icon: OmiImageLoader.localImg(Assets.omiSparkles,width: 16, height: 16, color: _kFooter), label: 'Summary'),
        if (showActivity) ...[
          const SizedBox(width: 20),
          _FooterChip(icon: OmiImageLoader.localImg(Assets.omiActivity,width: 16, height: 16, color: _kFooter), label: 'Activity'),
        ],
      ],
    );
  }
}

class _FooterChip extends StatelessWidget {
  const _FooterChip({
    required this.icon,
    required this.label,
  });

  final Image icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 6),
        Text(
          label,
          style: OmiTextStyle.create(
            fontSize: 13,
            color: _kFooter,
            fontWeight: OmiFontWeight.medium,
          ),
        ),
      ],
    );
  }
}
