import 'package:flutter/cupertino.dart';
import 'package:omi/business/shared/models/mp_business_models.dart';

class MPMemoDetailPage extends StatelessWidget {
  const MPMemoDetailPage({
    super.key,
    required this.memo,
  });

  final MPMemo memo;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Memo Detail'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                memo.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(memo.timeLabel),
              const SizedBox(height: 12),
              Text(memo.content),
            ],
          ),
        ),
      ),
    );
  }
}
