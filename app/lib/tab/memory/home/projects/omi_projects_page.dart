import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

/// Memory「Projects」占位页（后续接真实列表）
class OmiProjectsPage extends StatelessWidget {
  const OmiProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Projects',
        style: OmiTextStyle.create(
          fontSize: OmiFontSize.t11_20,
          fontWeight: OmiFontWeight.medium,
          color: secondTextColor,
        ),
      ),
    );
  }
}
