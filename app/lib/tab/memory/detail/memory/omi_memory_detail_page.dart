import 'package:flutter/material.dart';
import 'package:omi/common/mp_custom_nav_bar.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_image_loader.dart';

import '../../../../generated/assets.dart';
import 'card/mp_memory_detail_content_card.dart';
import 'card/mp_memory_detail_bottom_bar.dart';

/// Memory 详情页（顶部 [MPCustomNavBar]：返回 + 标题 + 分享 / 更多）
class OmiMemoryDetailPage extends StatelessWidget {
  const OmiMemoryDetailPage({super.key});

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: MPMemoryDetailContentCard(
          data: const MPMemoryDetailCardData(
            title: 'Investor meeting - Series A funding discussion',
            metaLine: 'Yesterday, 4:30 PM • 45m52s • MemoPin',
            audioTimeStart: '0:00',
            audioTimeEnd: '45m52s',
            speakerLabels: <String>['Investor', 'You'],
            initialSegment: MPMemoryDetailSegment.transcript,
          ),
          onSegmentChanged: (MPMemoryDetailSegment s) {
            // TODO: 根据分段切换下方内容
          },
          onPlayTap: () {
            // TODO: 播放
          },
        ),
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
