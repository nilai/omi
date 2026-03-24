import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omi/common/mp_custom_nav_bar.dart';
import 'package:omi/common/mp_tristate_page.dart';
import 'package:omi/common/omi_quick_add_todo_popup.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_detail_content_card.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_detail_bottom_bar.dart';
import 'package:omi/tab/memory/detail/memory/omi_memory_detail_cubit.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_image_loader.dart';

import '../../../../generated/assets.dart';

/// Memo 详情页：与 Memory 详情复用同一份内容逻辑。
/// 区别：
/// 1. 主卡片不带背景色；
/// 2. Segment 下内容与页面主滚动保持同一滚动容器。
class OmiMemoDetailPage extends StatelessWidget {
  const OmiMemoDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OmiMemoryDetailCubit()..initData(),
      child: const _OmiMemoDetailView(),
    );
  }
}

class _OmiMemoDetailView extends StatelessWidget {
  const _OmiMemoDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      appBar: PreferredSize(
        preferredSize: MPCustomNavBar.preferredSizeOf(context),
        child: MPCustomNavBar(
          title: 'Memo',
          actions: <Widget>[
            GestureDetector(
              onTap: () {},
              child: OmiImageLoader.localImg(
                Assets.omiShare,
                width: 20,
                height: 20,
                color: blueTextColor,
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () {},
              child: OmiImageLoader.localImg(
                Assets.omiMemoryDetialMore,
                width: 20,
                height: 20,
                color: blueTextColor,
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<OmiMemoryDetailCubit, OmiMemoryDetailState>(
        builder: (BuildContext context, OmiMemoryDetailState state) {
          switch (state.phase) {
            case OmiMemoryDetailPhase.loading:
              return const MPTristatePage(type: MPTristateType.loading);
            case OmiMemoryDetailPhase.error:
              return MPTristatePage(
                type: MPTristateType.error,
                data: MPTristatePageData(
                  title: 'Unable to load memo detail',
                  description: state.errorMessage ?? '请稍后重试',
                  onButtonPressed: () {
                    context.read<OmiMemoryDetailCubit>().retry();
                  },
                ),
              );
            case OmiMemoryDetailPhase.loaded:
              final MPMemoryDetailCardData data = state.data!;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MPMemoryDetailContentCard(
                        data: data,
                        showBackground: false,
                        segmentBodyScrollWithParent: true,
                        cardType: MPMemoryDetailCardType.memo,
                        onSegmentChanged: (MPMemoryDetailSegment s) {},
                        onPlayTap: () {},
                      ),
                    ),
                  ],
                ),
              );
          }
        },
      ),
      bottomNavigationBar: MPMemoryDetailBottomBar(
        onAddTodo: () async {
          final OmiQuickAddTodoResult? result = await showOmiQuickAddTodoPopup(
            context,
          );
          if (result == null) return;
          context.read<OmiMemoryDetailCubit>().addTodoFromQuickInput(
            result.text,
          );
        },
        onAddMemo: () async {
          final OmiQuickAddTodoResult? result = await showOmiQuickAddTodoPopup(
            context,
            params: const OmiQuickInputPopupParams(
              headerTitle: 'ADD MEMO',
              hintText: 'What would you like to remember?',
            ),
          );
          if (result == null) return;
          context.read<OmiMemoryDetailCubit>().addMemoFromQuickInput(
            result.text,
          );
        },
        onAskAi: () {},
      ),
    );
  }
}
