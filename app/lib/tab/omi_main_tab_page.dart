import 'package:flutter/material.dart';
import 'package:omi/tab/askai/omi_ask_ai_page.dart';
import 'package:omi/tab/home/omi_home_page.dart';
import 'package:omi/tab/memory/home/omi_memory_page.dart';
import 'package:omi/tab/mine/omi_mine_page.dart';

import '../generated/assets.dart';
import '../utils/omi_image_loader.dart';

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  static const Color _selectedColor = Color(0xFF2D5A47);
  static const Color _unselectedColor = Color(0xFF79796F);

  int _currentIndex = 0;

  final List<Widget> _pages = const [
    OmiHomePage(),
    OmiMemoryPage(),
    OmiAskAIPage(),
    OmiMinePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
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
              icon: OmiImageLoader.localImg(
                Assets.imagesTabHome,
                color: _unselectedColor,
              ),
              activeIcon: OmiImageLoader.localImg(
                Assets.imagesTabHome,
                color: _selectedColor,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: OmiImageLoader.localImg(
                Assets.imagesTabBook,
                color: _unselectedColor,
              ),
              activeIcon: OmiImageLoader.localImg(
                Assets.imagesTabBook,
                color: _selectedColor,
              ),
              label: 'Memory',
            ),

            BottomNavigationBarItem(
              icon: OmiImageLoader.localImg(
                Assets.imagesTabAskAi,
                color: _unselectedColor,
              ),
              activeIcon: OmiImageLoader.localImg(
                Assets.imagesTabAskAi,
                color: _selectedColor,
              ),
              label: 'Ask AI',
            ),

            BottomNavigationBarItem(
              icon: OmiImageLoader.localImg(
                Assets.imagesTabSetting,
                color: _unselectedColor,
              ),
              activeIcon: OmiImageLoader.localImg(
                Assets.imagesTabSetting,
                color: _selectedColor,
              ),
              label: 'Preferences',
            ),
          ],
        ),
      ),
    );
  }
}
