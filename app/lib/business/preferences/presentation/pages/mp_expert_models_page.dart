import 'package:flutter/cupertino.dart';

class MPExpertModelsPage extends StatelessWidget {
  const MPExpertModelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Expert Models'),
      ),
      child: SafeArea(
        child: ListView(
          children: const [
            CupertinoListTile(title: Text('General Assistant')),
            CupertinoListTile(title: Text('Product Analyst')),
            CupertinoListTile(title: Text('Research Synthesizer')),
          ],
        ),
      ),
    );
  }
}
