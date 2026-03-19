import 'package:flutter/cupertino.dart';

class OmiMinePage extends StatefulWidget {
  const OmiMinePage({super.key});

  @override
  createState() => _OmiMinePageState();
}

class _OmiMinePageState extends State<OmiMinePage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
        child: Text('omi_mine_page'),
      ),
    );
  }
}