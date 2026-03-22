import 'package:flutter/cupertino.dart';
import 'package:omi/business/memory/presentation/pages/mp_person_detail_page.dart';

class MPPeoplePage extends StatelessWidget {
  const MPPeoplePage({super.key});

  @override
  Widget build(BuildContext context) {
    const people = <String>['Alex', 'Jordan', 'Sarah', 'Emily'];
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('People'),
      ),
      child: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: people.length,
          itemBuilder: (context, index) {
            final person = people[index];
            return CupertinoListTile(
              title: Text(person),
              subtitle: const Text('Memory relationships'),
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => MPPersonDetailPage(name: person),
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
