import 'package:flutter/material.dart';
import 'home/home/mp_home_page.dart';

import '../generated/assets.dart';
import '../utils/omi_image_loader.dart';
import 'askai/omi_ask_ai_page.dart';
import 'memory/home/omi_memory_page.dart';
import 'mine/omi_mine_page.dart';

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  static const Color _selectedColor = Color(0xFF2D5A47);
  static const Color _unselectedColor = Color(0xFF79796F);

  int _currentIndex = 0;

  List<Widget> get _pages => <Widget>[
        MPHomePage(
          isTabActive: _currentIndex == 0,
          onViewAllMemories: () {
            setState(() => _currentIndex = 1);
          },
        ),
        OmiMemoryPage(),
        OmiAskAIPage(),
        OmiMinePage(),
      ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: _selectedColor,
          unselectedItemColor: _unselectedColor,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: OmiImageLoader.localImg(Assets.tabHome, color: _unselectedColor),
              activeIcon: OmiImageLoader.localImg(Assets.tabHome, color: _selectedColor),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: OmiImageLoader.localImg(Assets.tabBook, color: _unselectedColor),
              activeIcon: OmiImageLoader.localImg(Assets.tabBook, color: _selectedColor),
              label: 'Memory',
            ),

            BottomNavigationBarItem(
              icon: OmiImageLoader.localImg(Assets.tabAskAi, color: _unselectedColor),
              activeIcon: OmiImageLoader.localImg(Assets.tabAskAi, color: _selectedColor),
              label: 'Ask AI',
            ),

            BottomNavigationBarItem(
              icon: OmiImageLoader.localImg(Assets.tabSetting, color: _unselectedColor),
              activeIcon: OmiImageLoader.localImg(Assets.tabSetting, color: _selectedColor),
              label: 'Preferences',
            ),
          ],
        ),
      ),
    );
  }
}
