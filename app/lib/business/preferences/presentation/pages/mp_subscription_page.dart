import 'package:flutter/cupertino.dart';

class MPSubscriptionPage extends StatelessWidget {
  const MPSubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Subscription'),
      ),
      child: SafeArea(
        child: Center(
          child: Text('订阅与账单页占位。'),
        ),
      ),
    );
  }
}
