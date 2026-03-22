import 'package:flutter/cupertino.dart';

class MPCalendarPage extends StatelessWidget {
  const MPCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Calendar'),
      ),
      child: SafeArea(
        child: Center(
          child: Text('日历视图占位页，可扩展月/周/日模式。'),
        ),
      ),
    );
  }
}
