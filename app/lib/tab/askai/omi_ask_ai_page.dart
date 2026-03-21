import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';

import '../../common/mp_navigation_bar.dart';
import '../../permission/omi_microphone_manager.dart';

class OmiAskAIPage extends StatefulWidget {
  const OmiAskAIPage({super.key});

  @override
  createState() => _OmiAskAIPageState();
}

class _OmiAskAIPageState extends State<OmiAskAIPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      appBar: PreferredSize(
        preferredSize: MPNavigationBar.preferredSizeOf(context),
        child: MPNavigationBar(
          variant: MPNavigationBarVariant.askAi,
        ),
      ),
      body: Center(
        child: GestureDetector(
          onTap: () async {
            await OmiMicrophoneManager.ensureMicrophonePermission(context);
          },
          child: const Text(
            '申请麦克风权限',
            style: TextStyle(color: mainTextColor),
          ),
        ),
      ),
    );
  }
}