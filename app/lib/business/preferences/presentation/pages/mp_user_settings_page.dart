import 'package:flutter/cupertino.dart';

class MPUserSettingsPage extends StatelessWidget {
  const MPUserSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('User Settings'),
      ),
      child: SafeArea(
        child: Center(
          child: Text('用户设置页占位。'),
        ),
      ),
    );
  }
}
