import 'package:flutter/cupertino.dart';

class MPAiSummaryStylePage extends StatelessWidget {
  const MPAiSummaryStylePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('AI Summary Style'),
      ),
      child: SafeArea(
        child: ListView(
          children: const [
            CupertinoListTile(title: Text('简洁')),
            CupertinoListTile(title: Text('详细')),
            CupertinoListTile(title: Text('行动导向')),
          ],
        ),
      ),
    );
  }
}
