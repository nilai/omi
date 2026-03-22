import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_detail_content_card.dart';
import 'package:omi/tab/memory/detail/memory/card/omi_memory_action_content.dart';
import 'package:omi/tab/memory/detail/memory/card/omi_memory_transcript_item.dart';

enum OmiMemoryDetailPhase {
  loading,
  loaded,
  error,
}

class OmiMemoryDetailState {
  const OmiMemoryDetailState({
    required this.phase,
    this.data,
    this.errorMessage,
  });

  final OmiMemoryDetailPhase phase;
  final MPMemoryDetailCardData? data;
  final String? errorMessage;
}

class OmiMemoryDetailCubit extends Cubit<OmiMemoryDetailState> {
  OmiMemoryDetailCubit()
      : super(const OmiMemoryDetailState(phase: OmiMemoryDetailPhase.loading));

  Future<void> initData() => load();

  Future<void> load() async {
    emit(const OmiMemoryDetailState(phase: OmiMemoryDetailPhase.loading));
    try {
      final MPMemoryDetailCardData data = await _mockFetchDetail();
      emit(
        OmiMemoryDetailState(
          phase: OmiMemoryDetailPhase.loaded,
          data: data,
        ),
      );
    } catch (e) {
      emit(
        OmiMemoryDetailState(
          phase: OmiMemoryDetailPhase.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> retry() => load();

  /// 模拟详情请求：
  /// - 延迟 900ms
  /// - 返回头部信息 + overview/transcript/actions 三段数据
  Future<MPMemoryDetailCardData> _mockFetchDetail() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return MPMemoryDetailCardData(
      title: 'Investor meeting - Series A funding discussion',
      metaLine: 'Yesterday, 4:30 PM • 45m52s • MemoPin',
      audioTimeStart: '0:00',
      audioTimeEnd: '45m52s',
      speakerLabels: const <String>['Investor', 'You'],
      initialSegment: MPMemoryDetailSegment.transcript,
      overviewText:
          'Investors认可近期增长，但要求在基础设施稳定性、鉴权安全测试和灰度发布计划上给出更明确里程碑。',
      transcriptItems: const <MPMemoryTranscriptItemData>[
        MPMemoryTranscriptItemData(
          timestamp: '00:00',
          speakerName: 'Investor',
          transcriptText:
              'Thanks for presenting today. Your growth numbers look impressive.',
        ),
        MPMemoryTranscriptItemData(
          timestamp: '02:15',
          speakerName: 'You',
          transcriptText:
              'We can walk through the Q3 pipeline and unit economics next.',
        ),
        MPMemoryTranscriptItemData(
          timestamp: '05:40',
          speakerName: 'Investor',
          transcriptText:
              'Please detail risk controls for phased rollout and auth migration.',
        ),
      ],
      actionItems: const <MPMemoryActionItemData>[
        MPMemoryActionItemData(
          title: 'Review migration milestones with infrastructure team',
          status: MPMemoryActionItemStatus.created,
        ),
        MPMemoryActionItemData(
          title: 'Schedule authentication service testing session',
          status: MPMemoryActionItemStatus.pending,
        ),
        MPMemoryActionItemData(
          title: 'Document rollout risks and mitigation strategies',
          status: MPMemoryActionItemStatus.pending,
        ),
      ],
    );
  }
}
