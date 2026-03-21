import 'package:flutter/cupertino.dart';
import 'package:omi/business/ask_ai/presentation/mp_ask_ai_tab_page.dart';
import 'package:omi/business/home/presentation/mp_home_tab_page.dart';
import 'package:omi/business/memory/presentation/mp_memory_tab_page.dart';
import 'package:omi/business/preferences/presentation/mp_preferences_tab_page.dart';
import 'package:omi/business/shared/data/mp_business_repository.dart';
import 'package:omi/business/shared/state/mp_business_controller.dart';

class MPBusinessShellPage extends StatefulWidget {
  const MPBusinessShellPage({
    super.key,
    required this.repository,
  });

  final MPBusinessRepository repository;

  @override
  State<MPBusinessShellPage> createState() => _MPBusinessShellPageState();
}

class _MPBusinessShellPageState extends State<MPBusinessShellPage> {
  int _currentIndex = 0;
  late final MPBusinessController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MPBusinessController(repository: widget.repository);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.collections),
            label: 'Memory',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble_2),
            label: 'Ask AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Preferences',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return MPHomeTabPage(controller: _controller);
          case 1:
            return MPMemoryTabPage(controller: _controller);
          case 2:
            return MPAskAiTabPage(controller: _controller);
          default:
            return MPPreferencesTabPage(controller: _controller);
        }
      },
    );
  }
}
