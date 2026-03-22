import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omi/common/mp_tristate_page.dart';
import 'package:omi/common/mp_custom_nav_bar.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_image_loader.dart';

import '../../../../generated/assets.dart';
import 'card/mp_memory_detail_content_card.dart';
import 'card/mp_memory_detail_bottom_bar.dart';
import 'omi_memory_detail_cubit.dart';

/// Memory 详情页（顶部 [MPCustomNavBar]：返回 + 标题 + 分享 / 更多）
class OmiMemoryDetailPage extends StatelessWidget {
  const OmiMemoryDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OmiMemoryDetailCubit()..initData(),
      child: const _OmiMemoryDetailView(),
    );
  }
}

class _OmiMemoryDetailView extends StatelessWidget {
  const _OmiMemoryDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      appBar: PreferredSize(
        preferredSize: MPCustomNavBar.preferredSizeOf(context),
        child: MPCustomNavBar(
          title: 'Memory',
          actions: <Widget>[
            GestureDetector(
              onTap: () { // 分享

              },
              child: Container(
                child: OmiImageLoader.localImg(Assets.omiShare, width: 20, height: 20, color: blueTextColor),
              ),
            ),
            SizedBox(width: 16.0,),
            GestureDetector(
              onTap: () { // 更多

              },
              child: Container(
                child: OmiImageLoader.localImg(Assets.omiMemoryDetialMore, width: 20, height: 20, color: blueTextColor),
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
                  title: 'Unable to load memory detail',
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
                child: MPMemoryDetailContentCard(
                  data: data,
                  onSegmentChanged: (MPMemoryDetailSegment s) {},
                  onPlayTap: () {
                    // TODO: 播放
                  },
                ),
              );
          }
        },
      ),
      bottomNavigationBar: MPMemoryDetailBottomBar(
        onAddTodo: () {
          // TODO: Add Todo
        },
        onAddMemo: () {
          // TODO: Add Memo
        },
        onAskAi: () {
          // TODO: Ask AI
        },
      ),
    );
  }
}
