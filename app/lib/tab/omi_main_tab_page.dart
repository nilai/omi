import 'package:flutter/material.dart';
import 'package:omi/business/ask_ai/presentation/mp_ask_ai_tab_page.dart';
import 'package:omi/business/home/presentation/mp_home_tab_page.dart';
import 'package:omi/business/preferences/presentation/mp_preferences_tab_page.dart';
import 'package:omi/business/shared/data/mp_business_repository.dart';
import 'package:omi/business/shared/state/mp_business_controller.dart';
import 'package:omi/tab/home/omi_home_page.dart';

import '../generated/assets.dart';
import '../utils/omi_image_loader.dart';
import 'memory/home/omi_memory_page.dart';

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  static const Color _selectedColor = Color(0xFF2D5A47);
  static const Color _unselectedColor = Color(0xFF79796F);

  int _currentIndex = 0;
  late final MPBusinessController _businessController;

  List<Widget> get _pages => [
        OmiHomePage(),
        OmiMemoryPage(controller: _businessController),
        MPAskAiTabPage(controller: _businessController),
        MPPreferencesTabPage(controller: _businessController),
      ];

  @override
  void initState() {
    super.initState();
    _businessController = MPBusinessController(
      repository: const MPBusinessRepository(),
    );
  }

  @override
  void dispose() {
    _businessController.dispose();
    super.dispose();
  }

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
                Assets.tabHome,
                color: _unselectedColor,
              ),
              activeIcon: OmiImageLoader.localImg(
                Assets.tabHome,
                color: _selectedColor,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: OmiImageLoader.localImg(
                Assets.tabBook,
                color: _unselectedColor,
              ),
              activeIcon: OmiImageLoader.localImg(
                Assets.tabBook,
                color: _selectedColor,
              ),
              label: 'Memory',
            ),

            BottomNavigationBarItem(
              icon: OmiImageLoader.localImg(
                Assets.tabAskAi,
                color: _unselectedColor,
              ),
              activeIcon: OmiImageLoader.localImg(
                Assets.tabAskAi,
                color: _selectedColor,
              ),
              label: 'Ask AI',
            ),

            BottomNavigationBarItem(
              icon: OmiImageLoader.localImg(
                Assets.tabSetting,
                color: _unselectedColor,
              ),
              activeIcon: OmiImageLoader.localImg(
                Assets.tabSetting,
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
