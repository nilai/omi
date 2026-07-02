import 'package:flutter/material.dart';
import 'package:memo_pin/common/mp_tristate_page.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_image_loader.dart';

import '../../../../generated/assets.dart';

/// Memory「Projects」：Beta 阶段占位提示
class OmiProjectsPage extends StatelessWidget {
  const OmiProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MPTristatePage(
      type: MPTristateType.empty,
      data: MPTristatePageData(
        icon: OmiImageLoader.localImg(
          Assets.omiBrain,
          width: 60,
          height: 60,
          color: blueTextColor,
          fit: BoxFit.cover,
        ),
        title: 'Project view is coming soon',
        description:
            'This feature is not available in the current beta. We\'ll add project-based memory organization in a later phase.',
        showButton: false,
      ),
    );
  }
}
