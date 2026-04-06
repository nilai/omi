import 'package:flutter/material.dart';
import 'package:memo_pin/common/omi_button.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_image_loader.dart';

import '../../../../../generated/assets.dart';

/// Memory 详情页底部：Add Todo / Add Memo / Ask AI
class MPMemoryDetailBottomBar extends StatelessWidget {
  const MPMemoryDetailBottomBar({
    super.key,
    this.onAddTodo,
    this.onAddMemo,
    this.onAskAi,
  });

  final VoidCallback? onAddTodo;
  final VoidCallback? onAddMemo;
  final VoidCallback? onAskAi;

 
  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.paddingOf(context).bottom;
    return  Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: topInset),
        child: Row(
          children: <Widget>[
            Expanded(
              child: OmiButton(
                iconSize: 12,
                icon: OmiImageLoader.localImg(Assets.omiDetailCheck,width: 12, height: 12,color: Colors.white),
                bgColor: greenDeepColor,
                textFontSize: 12,
                textFontWeight: OmiFontWeight.medium,
                textColor: Colors.white,
                text: 'Add Todo',
                onPressed: onAddTodo,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OmiButton(
                bgColor: blueTextColor,
                iconSize: 12,
                icon: OmiImageLoader.localImg(Assets.omiDetailEdit,width: 12, height: 12,color: Colors.white),
                textFontWeight: OmiFontWeight.medium,
                textFontSize: 12,
                textColor: Colors.white,
                text: 'Add Memo',
                onPressed: onAddMemo,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OmiButton(
                bgColor: greenTextColor,
                iconSize: 12,
                icon: OmiImageLoader.localImg(Assets.omiDetailMessage,width: 12, height: 12,color: Colors.white),
                textFontWeight: OmiFontWeight.medium,
                textColor: Colors.white,
                textFontSize: 12,
                text: 'Ask AI',
                onPressed: onAskAi,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
