import 'package:flutter/material.dart';

import '../../../common/mp_memory_top_tabs.dart';
import '../../../common/mp_navigation_bar.dart';
import '../../../utils/omi_color_utils.dart';
import 'all/omi_all_page.dart';
import 'people/omi_people_page.dart';
import 'projects/omi_projects_page.dart';

/// Memory 根页：顶部导航 + All / People / Projects 分段内容
class OmiMemoryPage extends StatefulWidget {
  const OmiMemoryPage({super.key});

  @override
  State<OmiMemoryPage> createState() => _OmiMemoryPageState();
}

class _OmiMemoryPageState extends State<OmiMemoryPage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      appBar: PreferredSize(
        preferredSize: MPNavigationBar.preferredSizeOf(context),
        child: MPNavigationBar(
          variant: MPNavigationBarVariant.memory,
          backgroundColor: Colors.white,
          onPrimaryActionTap: () {
            // TODO: 打开搜索
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MPMemoryTopTabs(
            index: _tabIndex,
            onChanged: (int i) => setState(() => _tabIndex = i),
          ),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              sizing: StackFit.expand,
              children: const <Widget>[
                OmiAllPage(),
                OmiPeoplePage(),
                OmiProjectsPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
