import 'package:flutter/material.dart';

import '../../common/mp_navigation_bar.dart';
import '../../utils/omi_color_utils.dart';

class OmiHomePage extends StatefulWidget {
 const OmiHomePage({super.key});
 @override
 createState() => _OmiHomePageState();
}

class _OmiHomePageState extends State<OmiHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      appBar: PreferredSize(
        preferredSize: MPNavigationBar.preferredSizeOf(context),
        child: MPNavigationBar(
          variant: MPNavigationBarVariant.memoPin,
        ),
      ),
    );
  }
}