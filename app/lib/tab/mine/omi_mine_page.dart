import 'package:flutter/material.dart';

import '../../common/mp_navigation_bar.dart';
import '../../utils/omi_color_utils.dart';

class OmiMinePage extends StatefulWidget {
  const OmiMinePage({super.key});

  @override
  createState() => _OmiMinePageState();
}

class _OmiMinePageState extends State<OmiMinePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      appBar: PreferredSize(
        preferredSize: MPNavigationBar.preferredSizeOf(context),
        child: MPNavigationBar(
          backgroundColor: Colors.white,
          variant: MPNavigationBarVariant.preferences,
        ),
      ),
    );
  }
}