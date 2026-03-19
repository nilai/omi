import 'package:flutter/material.dart';
import 'package:omi/askai/omi_ask_ai_page.dart';
import 'package:omi/home/omi_home_page.dart';
import 'package:omi/memory/omi_memory_page.dart';
import 'package:omi/mine/omi_mine_page.dart';

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
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
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
            BottomNavigationBarItem(icon: Icon(Icons.memory), label: '记忆'),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome),
              label: 'Ask AI',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
          ],
        ),
      ),
    );
  }
}
