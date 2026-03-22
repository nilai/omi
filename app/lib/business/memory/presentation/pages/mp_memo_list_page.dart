import 'package:flutter/cupertino.dart';
import 'package:omi/business/memory/presentation/pages/mp_memo_detail_page.dart';
import 'package:omi/business/shared/state/mp_business_controller.dart';

class MPMemoListPage extends StatelessWidget {
  const MPMemoListPage({
    super.key,
    required this.controller,
  });

  final MPBusinessController controller;

  @override
  Widget build(BuildContext context) {
    final memos = controller.memos;
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Memo List'),
      ),
      child: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: memos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final memo = memos[index];
            return CupertinoListTile(
              title: Text(memo.title),
              subtitle: Text(memo.content),
              trailing: Text(memo.timeLabel),
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => MPMemoDetailPage(memo: memo),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
